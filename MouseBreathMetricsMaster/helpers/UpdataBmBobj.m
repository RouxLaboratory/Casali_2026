function [New ]  = UpdataBmBobj(Old, FullTime   , ValidWindows,  AllTimeWindow)
%% Function written by Giulio Casali (giulio.casali.pro@gmail.com)
% Similar to the functon "ReSampleBmBobj", the goal of this function is to update the results of the bmObj in the parent script,
% so that most of the relevant information previously ran can be kept after resampling;
% INPUT:
% Old = bmObj obtained in parent function of the master Sniff script;
% FullTime = Long vector of samples for the entire session;
% ValidWindows = Sometimes the sniff signal disappears, so the valid windows represent the intervals in which the sniff results are valid;
% Valid Data: This is obtained in the previous script "ReSampleBmBobj" and specifies the logical array of data to consider based on the valid windows;
% AllTimeWindow = The overall lenght of the session including multiple recordings sometimes;
%% 1) Pre-allocating variables...
    New = [];;
    New.dataType = Old.dataType;
    New.time = reshape(FullTime,[], [1]);
    [New.rawRespiration, New.smoothedRespiration,New.baselineCorrectedRespiration ]  = deal(NaN(size(New.time))) ;
    New.srate = Old.srate;
    Old.indices = reshape(1 : numel(Old.time),[],1);
    %Old.baselineCorrectedRespiration = ShiftBaselineCorrectedSignalToMatchRaw(Old,false) ;

    
    % [In,Which ] = InIntervals(Old.time, ValidWindows) ;
    % TimeStarts = accumarray(Which(In),Old.indices(In),[size(ValidWindows,1) ,1] ,@min) ;
    % TimeEnds = accumarray(Which(In),Old.indices(In),[size(ValidWindows,1) ,1] ,@max) ;

%% 2) Re-sample the signals along the entire length of the session
    ValidData =  InIntervals( New.time  , ValidWindows);
    New.rawRespiration = reshape(InterpolateVector(Old.time,Old.rawRespiration , New.time),[],1);
    %New.rawRespiration(~ValidData) = NaN;
    New.smoothedRespiration = reshape(InterpolateVector(Old.time,Old.smoothedRespiration , New.time),[],1);
    %New.smoothedRespiration(~ValidData) = NaN;
    New.baselineCorrectedRespiration = reshape(InterpolateVector(Old.time,Old.baselineCorrectedRespiration , New.time),[],1);
    %New.baselineCorrectedRespiration(~ValidData) = NaN;
   %% 3) Update the indices
    n_cycles = numel(Old.inhaleOnsets);
    New.inhalePeaks =   knnsearch( New.time, Old.time(Old.inhalePeaks) );
    New.exhaleTroughs = knnsearch( New.time, Old.time(Old.exhaleTroughs) );
    New.inhaleOnsets = knnsearch( New.time, Old.time(Old.inhaleOnsets) );
    New.exhaleOnsets = knnsearch( New.time, Old.time(Old.exhaleOnsets) );
    New.inhaleOffsets = knnsearch( New.time, Old.time(Old.inhaleOffsets) );
    New.exhaleOffsets = knnsearch( New.time, Old.time(Old.exhaleOffsets) );
    New.CycleStart = knnsearch( New.time, Old.time(Old.CycleStart) ) ; 
    New.CycleEnd = knnsearch( New.time, Old.time(Old.CycleEnd) ) ; 
    ToAdjust = find([New.inhaleOffsets==New.exhaleOnsets]);
    New.inhaleOffsets(ToAdjust) = New.inhaleOffsets(ToAdjust)-1;
    New.exhaleOffsets(New.exhaleOffsets >New.CycleEnd) = New.CycleEnd(New.exhaleOffsets >New.CycleEnd) ;
    
    New.peakInspiratoryFlows =  reshape(New.smoothedRespiration(New.inhalePeaks)  , [],1);; 
    New.troughExpiratoryFlows =  reshape(New.smoothedRespiration(New.exhaleTroughs)  , [],1);; 
    
    if size(New.exhaleOffsets,1)<size(New.exhaleOnsets,1)
        New.exhaleOffsets(size(New.exhaleOffsets,1)+1:size(New.exhaleOnsets,1),1) = NaN ;
    end
        
    New.inhaleTimeToPeak = (New.inhalePeaks-New.inhaleOnsets)/New.srate ; 
    New.timeToTroughs =(New.exhaleTroughs-New.exhaleOnsets)/New.srate;
    [New.inhaleVolumes,New.exhaleVolumes] = findRespiratoryVolumes(New.smoothedRespiration,New.srate, ...
    New.inhaleOnsets', New.exhaleOnsets', New.inhaleOffsets', New.exhaleOffsets');
    New.inhaleVolumes = reshape(New.inhaleVolumes,[],1);
    New.exhaleVolumes = reshape(New.exhaleVolumes,[],1);
    New.inhaleDurations = diff([New.time(New.inhaleOnsets) New.time(New.inhaleOffsets) ] ,[],2) ;
    New.exhaleDurations = diff([New.time(New.exhaleOnsets) , New.time(New.exhaleOffsets) ], [] , 2) ;
    New.inhalePauseOnsets = NaN(size(Old.inhalePauseOnsets));
    New.inhalePauseOnsets(~isnan(Old.inhalePauseOnsets)) = knnsearch( New.time, Old.time(Old.inhalePauseOnsets(~isnan(Old.inhalePauseOnsets))) );
    New.inhalePauseOnsets = reshape(New.inhalePauseOnsets,[],1);
    New.exhalePauseOnsets = NaN(size(Old.exhalePauseOnsets));
    New.exhalePauseOnsets(~isnan(Old.exhalePauseOnsets)) = knnsearch( New.time, Old.time(Old.exhalePauseOnsets(~isnan(Old.exhalePauseOnsets))) );
    New.exhalePauseOnsets = reshape(New.exhalePauseOnsets,[],1);
    New.inhalePauseDurations = ([New.exhaleOnsets  - New.inhaleOffsets] -1) / New.srate ;
    New.exhalePauseDurations  = diff( [ (New.exhaleOffsets)    (New.CycleEnd)], [] ,2)/ New.srate ;
    New.CycleDuration = nansum([New.inhaleDurations , New.inhalePauseDurations , New.exhaleDurations , New.exhalePauseDurations ], 2) ; 
    New.AllinhaleVolumes  = New.inhaleVolumes ;
    New.AllexhaleVolumes = New.exhaleVolumes  ;
    
    [New.AllinhaleVolumes((~isnan(New.inhalePauseOnsets))),New.AllexhaleVolumes((~isnan(New.inhalePauseOnsets)))] = ...
    findRespiratoryVolumes(New.smoothedRespiration,New.srate, ...
    New.CycleStart((~isnan(New.inhalePauseOnsets)))', ...
    New.exhaleOnsets(~isnan(New.inhalePauseOnsets))', ...
    New.exhaleOnsets(~isnan(New.inhalePauseOnsets))', ...
    New.CycleEnd((~isnan(New.inhalePauseOnsets)))');
    New.AllinhaleVolumes  = reshape( New.AllinhaleVolumes ,[],1);
    New.AllexhaleVolumes  = reshape( New.AllexhaleVolumes ,[],1);

    
    New.ValidWindows = ValidWindows;
    New.ValidData = ValidData;
end
    