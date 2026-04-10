function NewBm = FindPausesFromBmChunk_FromMaxima(OldBm,indices_to_use,inhalePauseStats , DerivativeBand , SecondDerivativeBand, CycleID ,  PLOT_ON)
%%  PLOT_ON  = true ;
% Merge pauses or consider only the largest one?
%% Decide if the pauses start from the earliest or the bigggest epoch between inhala/ehale ;
SelectOnlyLargeForInhalation = false;
SelectAllForInhalation = ~(SelectOnlyLargeForInhalation);
%% Decide if the pauses start from the earliest or the bigggest epoch between exhala and next inhale;
SelectOnlyLargeForExhalation = true;
SelectAllForExhalation = ~(SelectOnlyLargeForExhalation);



    srate = round(1/nanmean(diff(OldBm.time(1:5))));
    OldBm.time = reshape(OldBm.time,1,[]);
    OldBm.indices = reshape(1:numel(OldBm.time),1,[]);
    OldBm.exhaleOffsets(isnan(OldBm.exhaleOffsets)) = [OldBm.CycleEnd(isnan(OldBm.exhaleOffsets)) ] ;
    NewBm = OldBm ; 
    N_Cycles = numel(NewBm.inhaleOnsets);
    NewBm.exhaleOffsets(NewBm.exhaleOffsets>find(indices_to_use,1,'last')) = find(indices_to_use,1,'last');
    CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];
        RemoveTheseCycles = ...
            NewBm.inhalePeaks==1 | ...
        ~InIntervals(NewBm.inhaleOnsets,CycleIntervals) | ...
        ~InIntervals(NewBm.inhaleOffsets,CycleIntervals) | ... 
        ~InIntervals(NewBm.exhaleOnsets,CycleIntervals ) | ... 
        ~InIntervals(NewBm.exhaleOffsets,CycleIntervals ) | ... 
        ~InIntervals(NewBm.exhaleTroughs,CycleIntervals ) ;
    indices_to_use( find(indices_to_use,1,'last')+1:end) = [];
    if any(RemoveTheseCycles)
        NewBm.inhaleOnsets(RemoveTheseCycles) = [];
        NewBm.inhaleOffsets(RemoveTheseCycles) = [];
        NewBm.exhaleOnsets(RemoveTheseCycles) = [];
        NewBm.exhaleOffsets(RemoveTheseCycles) = [];
        NewBm.CycleStart(RemoveTheseCycles) = [];
        NewBm.CycleEnd(RemoveTheseCycles) = [];
        NewBm.inhalePauseOnsets(RemoveTheseCycles) = [];
        NewBm.exhalePauseOnsets(RemoveTheseCycles) = [];
        NewBm.inhalePeaks(RemoveTheseCycles) = [];
        NewBm.exhaleTroughs(RemoveTheseCycles) = [];
        NewBm.inhalePauseDurations(RemoveTheseCycles) = [];
        NewBm.exhalePauseDurations(RemoveTheseCycles) = [];
        CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];
    end
    
    N_Cycles = numel(NewBm.inhalePeaks); 
    
    if N_Cycles == 0
        [   NewBm.inhalePeaks , NewBm.exhaleTroughs , NewBm.peakInspiratoryFlows, NewBm.troughExpiratoryFlows, ...
         NewBm.inhaleOnsets , NewBm.exhaleOnsets , NewBm.inhaleOffsets , NewBm.exhaleOffsets  , NewBm.inhaleTimeToPeak , ...
         NewBm.exhaleTimeToTrough , NewBm.inhaleVolumes , NewBm.exhaleVolumes , NewBm.inhaleDurations , NewBm.exhaleDurations , ...
         NewBm.inhalePauseOnsets , NewBm.exhalePauseOnsets , NewBm.inhalePauseDurations, NewBm.exhalePauseDurations , NewBm.CycleStart, NewBm.CycleEnd] = deal([]);
        NewBm.time = reshape(NewBm.time, [] ,1);
        return
    end
    
    
    
    CyclesArray = [1:N_Cycles] ;
    ToFix = find( reshape(NewBm.inhalePeaks < NewBm.inhaleOnsets,[],1) ) ;

    %try
    SignalToAdjust = true ;
    MaxIterations = 100;
    Iterations = 1 ;
    while SignalToAdjust
     
    if Iterations ==1 ;    
        MeanInhalationThreshold = [nanmean( NewBm.baselineCorrectedRespiration(   NewBm.inhaleOnsets(CyclesArray(not(ismember(CyclesArray,ToFix))))))] ;
        MeanExhlationThreshold = [nanmean( NewBm.baselineCorrectedRespiration(   NewBm.exhaleOnsets(CyclesArray(not(ismember(CyclesArray,ToFix)))))) ] ;
        %MeanThreshold = nanmean([MeanInhalationThreshold , MeanExhlationThreshold ] ) ;
        %MeanThreshold = 0;
        MeanThreshold = nanmean([inhalePauseStats.BaselineCorrected.FifthPercentile inhalePauseStats.BaselineCorrected.NinetyFifthPercentile]);
        if or(isnan(MeanThreshold),prctile(NewBm.baselineCorrectedRespiration,90)<MeanThreshold);
            MeanThreshold = nanmean([MeanInhalationThreshold , MeanExhlationThreshold ] ) ;
        end
            
    elseif Iterations>1;
        AverageSignal = movmean(OldBm.baselineCorrectedRespiration, srate*log10(Iterations) ) ;
        NewBm.baselineCorrectedRespiration =   OldBm.baselineCorrectedRespiration - AverageSignal ; 
        MeanThreshold = 0 ;
    end
    
%     if Iterations>1
%         clf
%         subplot(2,1,1);
%         plot(OldBm.indices,OldBm.baselineCorrectedRespiration);
%         hold on ;
%         plot(OldBm.indices,AverageSignal )
%         subplot(2,1,2);
%         plot(OldBm.indices,NewBm.baselineCorrectedRespiration  );
%         hold on ;
%         line(xlim,[MeanThreshold, MeanThreshold],'Color','r');
%         scatter(OldBm.indices(NewBm.inhaleOnsets),NewBm.baselineCorrectedRespiration(NewBm.inhaleOnsets));
%         scatter(OldBm.indices(NewBm.exhaleOnsets),NewBm.baselineCorrectedRespiration(NewBm.exhaleOnsets));  
%         scatter(OldBm.indices(    NewBm.inhaleOnsets(CyclesArray(not(ismember(CyclesArray,ToFix))))),NewBm.baselineCorrectedRespiration(    NewBm.inhaleOnsets(CyclesArray(not(ismember(CyclesArray,ToFix))))));
%         scatter(OldBm.indices(    NewBm.exhaleOnsets(CyclesArray(not(ismember(CyclesArray,ToFix))))),NewBm.baselineCorrectedRespiration(    NewBm.exhaleOnsets(CyclesArray(not(ismember(CyclesArray,ToFix))))));
%     end   
    
    
    InhalationBoundaries =   bwlabel([NewBm.baselineCorrectedRespiration(indices_to_use) > MeanThreshold]);
    InhalationBoundaries =   [accumarray(InhalationBoundaries(InhalationBoundaries>0 ),  reshape(NewBm.indices(InhalationBoundaries>0 ),[],1) , [max(InhalationBoundaries),1   ] ,  @min) , ...
        accumarray(InhalationBoundaries(InhalationBoundaries>0 ),  reshape(NewBm.indices(InhalationBoundaries>0 ),[],1) , [max(InhalationBoundaries),1   ] ,  @max) ] ; 
    
    
    %InhalationBoundaries = DetectMarginsFromArray([NewBm.indices ], [NewBm.baselineCorrectedRespiration > MeanThreshold]);  ;
    [GoodInhalation,WhichInhalationBoundary] = InIntervals(NewBm.inhalePeaks,    InhalationBoundaries) ;
    InhalationBoundaries = InhalationBoundaries(WhichInhalationBoundary(GoodInhalation),:);
    [GoodInhalation,WhichInhalationBoundary] = InIntervals(NewBm.inhalePeaks,    InhalationBoundaries) ;
    InhalationBoundariesIndx = [NaN(N_Cycles,2) ];
    InhalationBoundariesIndx(WhichInhalationBoundary(GoodInhalation),:) = ...
        InhalationBoundaries(WhichInhalationBoundary(GoodInhalation),:) ;
    InhalationBoundariesIndx(WhichInhalationBoundary==1,1) = 1 ;
    clear InhalationBoundaries;

    ExhalationBoundaries = bwlabel(not(InIntervals(reshape(NewBm.indices((indices_to_use)),[],1), InhalationBoundariesIndx))) ;
    %ExhalationBoundaries =   bwlabel([NewBm.baselineCorrectedRespiration < MeanThreshold]);
    ExhalationBoundaries =   [accumarray(ExhalationBoundaries(ExhalationBoundaries>0),  reshape(NewBm.indices(ExhalationBoundaries>0),[],1) , [max(ExhalationBoundaries),1   ] ,  @min) , ...
        accumarray(ExhalationBoundaries(ExhalationBoundaries>0),  reshape(NewBm.indices(ExhalationBoundaries>0),[],1) , [max(ExhalationBoundaries),1   ] ,  @max) ] ;
    
    [GoodExhalation,WhichExhalationBoundary] = InIntervals(NewBm.exhaleTroughs,    ExhalationBoundaries) ;
    ExhalationBoundaries = ExhalationBoundaries(WhichExhalationBoundary(GoodExhalation),:);
    [GoodExhalation,WhichExhalationBoundary] = InIntervals(NewBm.exhaleTroughs,    ExhalationBoundaries) ;
    ExhalationBoundariesIndx = [NaN(N_Cycles,2) ];
    ExhalationBoundariesIndx(WhichExhalationBoundary(GoodExhalation),:) =ExhalationBoundaries(WhichExhalationBoundary(GoodExhalation),:);
    MissingBoundaries = any([isnan(InhalationBoundariesIndx) ; isnan(ExhalationBoundariesIndx) ]);
    NewBm.baselineCorrectedRespiration = OldBm.baselineCorrectedRespiration;
    if any(MissingBoundaries)
        Iterations = Iterations+1;
        if Iterations == MaxIterations
           clear NewBm
           return
        end
    else
        SignalToAdjust = false;
        NewBm.baselineCorrectedRespiration = OldBm.baselineCorrectedRespiration;
        clear AverageSignal
    
%         clf;
%         subplot(2,1,1);
%         plot(NewBm.indices,NewBm.baselineCorrectedRespiration);
%         hold on ;
%         line(xlim,[MeanThreshold,MeanThreshold])
%         PlotIntervals([InhalationBoundariesIndx(227:229,:) ] ,'color','r','alpha',0.4);
%         PlotIntervals([ExhalationBoundariesIndx(227:229,:) ] ,'color','b','alpha',0.4);
%         scatter(NewBm.indices(NewBm.inhalePeaks)   ,NewBm.baselineCorrectedRespiration(NewBm.inhalePeaks));
%         scatter(NewBm.indices(NewBm.exhaleTroughs)   ,NewBm.baselineCorrectedRespiration(NewBm.exhaleTroughs));
    end
    end
    
%     if MissingBoundaries
%         
%        %Matrix =  sortrows([InhalationBoundariesIndx, repmat(1,size(InhalationBoundariesIndx,1),1), [1 :size(InhalationBoundariesIndx,1)]'  ; ExhalationBoundariesIndx, repmat(2,size(ExhalationBoundariesIndx,1),1),[1 :size(ExhalationBoundariesIndx,1)]'  ],1);
%         %Matrix = [InhalationBoundariesIndx(:,1) NewBm.inhalePeaks InhalationBoundariesIndx(:,2),ExhalationBoundariesIndx(:,1) , NewBm.exhaleTroughs , ExhalationBoundariesIndx(:,2)]
%         %reshape(sort(Matrix(:)),[6],[])'  %InhalationBoundariesIndx % [NewBm.inhaleOnsets, NewBm.inhaleOffsets, NewBm.exhaleOnsets, NewBm.exhaleOffsets]
%         NewBm.inhaleOnsets ;
%         NewBm.inhaleOffsets = NewBm.exhaleOnsets-1 ;
%         NewBm.exhaleOffsets = [NewBm.inhaleOnsets(2:end)-1; find(indices_to_use,1,'last')];
%         ToFix = find( [NewBm.inhaleOffsets  -  NewBm.inhaleOnsets  ]<0) ;
%         if not(isempty(ToFix)) 
%             if  not(isnan(InhalationBoundariesIndx(ToFix,:))) & not(isnan(ExhalationBoundariesIndx(ToFix,:)))
%                 NewBm.exhaleOffsets(ToFix-1) = InhalationBoundariesIndx(ToFix,1)-1 ;
%                 NewBm.inhaleOnsets(ToFix) = InhalationBoundariesIndx(ToFix,1) ;
%                 NewBm.inhaleOffsets(ToFix) = InhalationBoundariesIndx(ToFix,2) ;
%                 NewBm.exhaleOnsets(ToFix) = ExhalationBoundariesIndx(ToFix,1) ;
%                 NewBm.exhaleOffsets(ToFix) = ExhalationBoundariesIndx(ToFix,2) ;
%                 NewBm.inhaleOnsets(ToFix+1) = NewBm.exhaleOffsets(ToFix)+1;
%             else
%               NewBm.inhaleOffsets(ToFix) = NewBm.inhaleOnsets(ToFix) ;  
%               NewBm.inhaleOnsets(ToFix)  = NewBm.inhaleOffsets(ToFix) ;
%               NewBm.exhaleOffsets(ToFix-1) = NewBm.inhaleOnsets(ToFix)-1 ;
%             end
%                 
%         end
%     else
%     
    NewBm.inhaleOnsets(WhichInhalationBoundary(GoodInhalation)) = ...
        InhalationBoundariesIndx(:,1) ;
    
    NewBm.inhaleOffsets(GoodExhalation) = ...
        ExhalationBoundariesIndx(GoodExhalation,1)-1;
    
    NewBm.exhaleOnsets(GoodExhalation) = ...
        ExhalationBoundariesIndx(GoodExhalation,1);
   
    NewBm.exhaleOffsets(GoodExhalation) = ...
        ExhalationBoundariesIndx(GoodExhalation,2);   
    
%     end
%     
%     catch
%         NewBm.inhaleOnsets ;
%         NewBm.inhaleOffsets = NewBm.exhaleOnsets-1 ;
%         NewBm.exhaleOffsets = [NewBm.inhaleOnsets(2:end)-1; find(indices_to_use,1,'last')];
%     end
    
    %NewBm.exhaleOffsets = [ NewBm.inhaleOnsets(2:end)-1 ;find(indices_to_use,1,'last')];
    %NewBm.inhaleDurations = [NewBm.time(NewBm.inhaleOffsets) - NewBm.time(NewBm.inhaleOnsets)];
    %NewBm.exhaleDurations = [NewBm.time(NewBm.exhaleOffsets) - NewBm.time(NewBm.exhaleOnsets)];
    clear Boundaries WhichBoundary
    NewBm.CycleStart = NewBm.inhaleOnsets;   
    NewBm.CycleEnd = [ [NewBm.inhaleOnsets(2:end)-1 ; find(indices_to_use,1,'last')]];

    CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];
    NewBm.indices( find(indices_to_use,1,'last')+1:end) = [];
    NewBm.time( find(indices_to_use,1,'last')+1:end) = [];
    NewBm.rawRespiration( find(indices_to_use,1,'last')+1:end) = [];
    NewBm.smoothedRespiration( find(indices_to_use,1,'last')+1:end) = [];
    NewBm.baselineCorrectedRespiration( find(indices_to_use,1,'last')+1:end) = [];
    %NewBm.exhaleOffsets(NewBm.exhaleOffsets > NewBm.CycleEnd) = NewBm.CycleEnd(NewBm.exhaleOffsets > NewBm.CycleEnd);
    %NewBm.exhaleOffsets(isnan(NewBm.exhaleOffsets)) = [OldBm.CycleEnd(isnan(NewBm.exhaleOffsets)) ] ;
    %NewBm.exhaleOffsets(isnan(NewBm.exhalePauseOnsets)) = [OldBm.CycleEnd(isnan(NewBm.exhalePauseOnsets)) ] ;
    %NewBm.exhalePauseOnsets(NewBm.exhalePauseOnsets> NewBm.CycleEnd) = NewBm.CycleEnd(NewBm.exhalePauseOnsets> NewBm.CycleEnd); 
    %NewBm.exhalePauseOnsets(NewBm.exhalePauseOnsets> NewBm.CycleEnd) = NewBm.CycleEnd(NewBm.exhalePauseOnsets> NewBm.CycleEnd); 
    RemoveTheseCycles = ...
        ~InIntervals(NewBm.inhaleOnsets,CycleIntervals) | ...
        ~InIntervals(NewBm.inhaleOffsets,CycleIntervals) | ... 
        ~InIntervals(NewBm.exhaleOnsets,CycleIntervals ) | ... 
        ~InIntervals(NewBm.exhaleOffsets,CycleIntervals ) | ... 
        ~InIntervals(NewBm.exhaleTroughs,CycleIntervals ) ;
    indices_to_use( find(indices_to_use,1,'last')+1:end) = [];
    if any(RemoveTheseCycles)
        NewBm.inhaleOnsets(RemoveTheseCycles) = [];
        NewBm.inhaleOffsets(RemoveTheseCycles) = [];
        NewBm.exhaleOnsets(RemoveTheseCycles) = [];
        NewBm.exhaleOffsets(RemoveTheseCycles) = [];
        NewBm.CycleStart(RemoveTheseCycles) = [];
        NewBm.CycleEnd(RemoveTheseCycles) = [];
        NewBm.inhalePauseOnsets(RemoveTheseCycles) = [];
        NewBm.exhalePauseOnsets(RemoveTheseCycles) = [];
        NewBm.inhalePeaks(RemoveTheseCycles) = [];
        NewBm.exhaleTroughs(RemoveTheseCycles) = [];
        NewBm.inhalePauseDurations(RemoveTheseCycles) = [];
        NewBm.exhalePauseDurations(RemoveTheseCycles) = [];
        CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];
    end

Sigma = [1 ] / 1000;
OldFirstDerivative = [diff(OldBm.baselineCorrectedRespiration);NaN];
OldFirstDerivative = imgaussfilt(OldFirstDerivative,[srate *Sigma ] ) ;
NewFirstDerivative = [diff(NewBm.baselineCorrectedRespiration);NaN];
NewFirstDerivative = imgaussfilt(NewFirstDerivative,[srate *Sigma ] ) ;
NewSecondDerivative = [diff(NewFirstDerivative);NaN]  ;

%NewBm.exhaleOffsets(isnan(NewBm.exhaleOffsets)) = [OldBm.CycleEnd(isnan(NewBm.exhaleOffsets)) ] ;
%NewBm.exhaleOffsets(isnan(NewBm.exhalePauseOnsets)) = [OldBm.CycleEnd(isnan(NewBm.exhalePauseOnsets)) ] ;
%NewBm.inhalePauseDurations(isnan(NewBm.inhalePauseOnsets) ) = 0;
%NewBm.inhalePauseDurations(isnan(NewBm.inhalePauseDurations)) = 0;
%NewBm.exhalePauseDurations(isnan(NewBm.exhalePauseOnsets)) = 0;
%NewBm.exhalePauseDurations(isnan(NewBm.exhalePauseDurations)) = 0;
%NewBm.inhalePauseDurations(not(isnan(NewBm.inhalePauseOnsets ))) = NewBm.time(NewBm.exhaleOnsets(not(isnan(NewBm.inhalePauseOnsets )))) - NewBm.time(NewBm.inhalePauseOnsets(not(isnan(NewBm.inhalePauseOnsets )))) ; 
%NewBm.exhalePauseDurations(not(isnan(NewBm.exhalePauseOnsets ))) = abs( [ NewBm.time(CycleIntervals(not(isnan(NewBm.exhalePauseOnsets )),2))] -  NewBm.time(NewBm.exhalePauseOnsets(not(isnan(NewBm.exhalePauseOnsets )))) ) ; 
%NewBm.inhaleDurations = [NewBm.time(NewBm.inhaleOffsets) - NewBm.time(NewBm.inhaleOnsets)];
%NewBm.exhaleDurations = [NewBm.time(NewBm.exhaleOffsets) - NewBm.time(NewBm.exhaleOnsets)];
NewBm.inhaleOnsets(1) = 1; 
DerivativeMins =    find(indices_to_use & [imregionalmin( NewFirstDerivative(not(isnan(NewFirstDerivative)))) ; repmat(false,sum(isnan(NewFirstDerivative ) ),1) ] );
DerivativeMax =     find(indices_to_use & [imregionalmax( NewFirstDerivative(not(isnan(NewFirstDerivative)))) ; repmat(false,sum(isnan(NewFirstDerivative ) ),1)] );
N_Cycles = numel(NewBm.inhalePeaks); 
CyclesArray = [1:N_Cycles] ;



if  PLOT_ON           
figure(2);clf;
s1 = subplot(3,1,1);

plot(OldBm.time,OldBm.baselineCorrectedRespiration,'Color','k'); hold on ;
%plot(OldBm.time,OldBm.rawRespiration,'Color','g'); hold on ;
xlim(FindExtremesOfArray(OldBm.time(indices_to_use)))     ;
line(xlim(),[MeanThreshold,MeanThreshold],'Color','r')
ylim(4*[-1,1]*10^0);
PlotIntervals(OldBm.time([ OldBm.inhaleOnsets ,OldBm.inhaleOffsets]) ,'color','r','alpha',0.25)
if any(~isnan(OldBm.inhalePauseOnsets))
%    PlotIntervals([OldBm.time(OldBm.inhalePauseOnsets(not(isnan(OldBm.inhalePauseOnsets))))'] + [zeros(numel(OldBm.inhalePauseOnsets(not(isnan(OldBm.inhalePauseOnsets)))),1) ,  OldBm.inhalePauseDurations(not(isnan(OldBm.inhalePauseOnsets)))*srate ],'color','k','alpha',0.25);
    PlotIntervals([OldBm.time(OldBm.inhalePauseOnsets(not(isnan(OldBm.inhalePauseOnsets))))'] + [zeros(numel(OldBm.inhalePauseOnsets(not(isnan(OldBm.inhalePauseOnsets)))),1) ,  OldBm.inhalePauseDurations(not(isnan(OldBm.inhalePauseOnsets))) ],'color','k','alpha',0.25);

end
PlotIntervals(OldBm.time([ OldBm.exhaleOnsets ,OldBm.exhaleOffsets]),'color','b','alpha',0.25);
if any(~isnan(OldBm.exhalePauseOnsets))
    %PlotIntervals([OldBm.indices(OldBm.exhalePauseOnsets(not(isnan(OldBm.exhalePauseOnsets))))'] + [zeros(numel(OldBm.exhalePauseOnsets(not(isnan(OldBm.exhalePauseOnsets)))),1) ,  OldBm.exhalePauseDurations(not(isnan(OldBm.exhalePauseOnsets))) *srate],'color','k','alpha',0.25);
    PlotIntervals([OldBm.time(OldBm.exhalePauseOnsets(not(isnan(OldBm.exhalePauseOnsets))))'] + [zeros(numel(OldBm.exhalePauseOnsets(not(isnan(OldBm.exhalePauseOnsets)))),1) ,  OldBm.exhalePauseDurations(not(isnan(OldBm.exhalePauseOnsets))) ],'color','k','alpha',0.25);

end
scatter(OldBm.time(OldBm.inhalePeaks),OldBm.baselineCorrectedRespiration(OldBm.inhalePeaks),'r')
scatter(OldBm.time(OldBm.exhaleTroughs),OldBm.baselineCorrectedRespiration(OldBm.exhaleTroughs),'b')
line(xlim(), repmat(inhalePauseStats.BaselineCorrected.FifthPercentile ,1,2) ,'Color','k','LineStyle','--');
line(xlim(), repmat(inhalePauseStats.BaselineCorrected.NinetyFifthPercentile ,1,2) ,'Color','k','LineStyle','--');
title(['Interval # ' num2str( CycleID ) ' Input'])

s2=subplot(3,1,2);
plot(OldBm.time,OldFirstDerivative,'Color','r','LineStyle','--'); hold on ;
line(xlim(), repmat(DerivativeBand(1) ,1,2) ,'Color','r','LineStyle','--');
line(xlim(), repmat(DerivativeBand(2) ,1,2) ,'Color','r','LineStyle','--');
ylim([-1,1]*max(abs(ylim())));
xlim(FindExtremesOfArray(OldBm.time(indices_to_use))) ;
scatter(OldBm.time(DerivativeMins ),    NewFirstDerivative(DerivativeMins  ) ,[],'b');
scatter(OldBm.time(DerivativeMax ),     NewFirstDerivative(DerivativeMax  ) ,[],'r');
linkaxes([s1,s2],'x')
end


PeaksPresent = numel(NewBm.inhalePeaks) >0 ;
if PeaksPresent

if ~isempty(DerivativeMax)
                    %% AscendingPhaseOfInhalation;

                    DerivativeMaxForPeaks =DerivativeMax; 
                    [InCycle,WhichCycle]=InIntervals(DerivativeMaxForPeaks, [1 NewBm.inhalePeaks(1) ; [NewBm.exhaleTroughs(1:end-1) NewBm.inhalePeaks(2:end)] ]);
                    DerivativeMaxForPeaks = DerivativeMaxForPeaks(InCycle);
                    WhichCycle = WhichCycle(InCycle);
                    SignalAtPeak = NewBm.baselineCorrectedRespiration(DerivativeMaxForPeaks);
                    Height = NewFirstDerivative(DerivativeMaxForPeaks);
                    Distance= [ NewBm.inhalePeaks(WhichCycle) - DerivativeMaxForPeaks ] ;
                    Which = Distance>0 & SignalAtPeak >= MeanThreshold ;
                    peaks = accumarray( WhichCycle(Which ) , Height(Which) , [ N_Cycles,1],@nanmax);
                    maxpos = accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@max_and_idx);
                    %accumarray(WhichCycle(Distance>0)  , Height(Distance>0) , [ N_Cycles,1],@getthis(maxpos ,WhichCycle(Distance>0)  ));
                    AscendingPhaseOfInhalation = [];
                    for iWhichCycle = 1 : N_Cycles
                       if maxpos(iWhichCycle)==0;
                            AscendingPhaseOfInhalation(iWhichCycle) = NaN;
                            else
                            AscendingPhaseOfInhalation(iWhichCycle) =  GetValueFromIndex( DerivativeMaxForPeaks( Which & WhichCycle ==iWhichCycle ) ,maxpos(iWhichCycle)) ; 
                        end
                    end
                    AscendingPhaseOfInhalation = reshape(AscendingPhaseOfInhalation,[],1);
                    clear peas maxpos Height Distance SignalAtPeak WhichCycle DerivativeMaxForPeaks InCycle                    
                    
              
                    %% AscendingPhaseOfExhalation;
                    DerivativeMaxForPeaks =DerivativeMax; 
                    [InCycle,WhichCycle]=InIntervals(DerivativeMaxForPeaks, [NewBm.exhaleTroughs(1:end-1) NewBm.inhalePeaks(2:end)-1; NewBm.exhaleTroughs(end) find(indices_to_use,1,'last')  ] );
                    DerivativeMaxForPeaks = DerivativeMaxForPeaks(InCycle);
                    WhichCycle = WhichCycle(InCycle);
                    SignalAtPeak = NewBm.baselineCorrectedRespiration(DerivativeMaxForPeaks);
                    Height = NewFirstDerivative(DerivativeMaxForPeaks);
                    Distance= [ NewBm.exhaleTroughs(WhichCycle) - DerivativeMaxForPeaks ] ;
                    Which = find(Distance<0 & SignalAtPeak < MeanThreshold) ;
                    if ~isempty(Which)
                    peaks = accumarray( WhichCycle(Which) , Height(Which) , [ N_Cycles,1],@nanmax);
                    peaks(accumarray(WhichCycle(Distance<0 & SignalAtPeak < MeanThreshold)  , Height(Distance<0 & SignalAtPeak < MeanThreshold) , [ N_Cycles,1],@NElements)==0) = NaN;;
                    maxpos = accumarray(WhichCycle(Distance<0 & SignalAtPeak < MeanThreshold)  , Height(Distance<0 & SignalAtPeak < MeanThreshold) , [ N_Cycles,1],@max_and_idx);
                    maxpos(accumarray(WhichCycle(Distance<0 & SignalAtPeak < MeanThreshold)  , Height(Distance<0 & SignalAtPeak < MeanThreshold) , [ N_Cycles,1],@NElements)==0) = NaN;;
                    else
                    maxpos = NaN( N_Cycles,1);
                    end
                    AscendingPhaseOfExhalation = [];
                    for iWhichCycle = 1 : N_Cycles
                       if isnan(maxpos(iWhichCycle)) 
                           if iWhichCycle < N_Cycles
                            AscendingPhaseOfExhalation(iWhichCycle) = AscendingPhaseOfInhalation(iWhichCycle+1);
                           else
                             AscendingPhaseOfExhalation(iWhichCycle) = find(indices_to_use,1,'last') ;
                           end
                       else
                            AscendingPhaseOfExhalation(iWhichCycle) =  GetValueFromIndex( DerivativeMaxForPeaks( Distance<0 & WhichCycle ==iWhichCycle  & SignalAtPeak < MeanThreshold) ,maxpos(iWhichCycle)) ; 
                       end
                    end
                    AscendingPhaseOfExhalation = reshape(AscendingPhaseOfExhalation,[],1);
                    clear peas maxpos Height Distance WhichCycle DerivativeMaxForPeaks InCycle SignalAtPeak Which
                    clear K distance peaks max_index ns inds;
else;   
                %DerivativeMinsBeforePeaks = reshape([NewBm.inhalePeaks-1] , [] ,1) ;
                %DerivativeMinsAfterPeaks= reshape([NewBm.inhalePeaks+1] , [] ,1) ;
                DescendingPhaseOfInhalation =   round(nanmean([NewBm.inhalePeaks  PutativeInhalationWindow(:,2)],2));
                AscendingPhaseOfExhalation =   round(nanmean([NewBm.exhaleTroughs  PutativeExhalationWindow(:,2)],2));
end

            %% [AscendingPhaseOfInhalation ,AscendingPhaseOfExhalation ]  ; 
            if isnan(AscendingPhaseOfInhalation(1)) ;AscendingPhaseOfInhalation(1)=1; end;
            AscendingPhaseOfInhalation(isnan(AscendingPhaseOfInhalation)) = AscendingPhaseOfExhalation(find(isnan(AscendingPhaseOfInhalation))-1);
            AscendingPhaseOfExhalation(find(isnan(AscendingPhaseOfExhalation))) = AscendingPhaseOfInhalation(find(isnan(AscendingPhaseOfExhalation))+1);

if ~isempty(DerivativeMins)
                    %% DescendingPhaseOfInhalation;
                    DerivativeMinForPeaks =DerivativeMins; 
                    [InCycle,WhichCycle]=InIntervals(DerivativeMinForPeaks, [NewBm.inhalePeaks NewBm.exhaleTroughs ] );
                    DerivativeMinForPeaks = DerivativeMinForPeaks(InCycle);
                    SignalAtPeak = NewBm.baselineCorrectedRespiration(DerivativeMinForPeaks);
                    WhichCycle = WhichCycle(InCycle);
                    Height = NewFirstDerivative(DerivativeMinForPeaks);
                    Distance= [ DerivativeMinForPeaks - NewBm.inhalePeaks(WhichCycle)  ] ;
                    Which = [ Distance>0 & SignalAtPeak>max(MeanThreshold) ] ;
                    peaks = accumarray( WhichCycle(Which) , Height(Which) , [ N_Cycles,1],@nanmin);
                    peaks(accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@NElements)==0) = NaN ;
                    minpos = accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@min_and_idx ) ;
                    minpos(accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@NElements)==0 ) = NaN ;
                    DescendingPhaseOfInhalation = [];
                    for iWhichCycle = 1 : N_Cycles
                       if isnan(minpos(iWhichCycle))
                             DescendingPhaseOfInhalation(iWhichCycle) = NaN;
                       else
                            DescendingPhaseOfInhalation(iWhichCycle) =  GetValueFromIndex( DerivativeMinForPeaks(Which & WhichCycle ==iWhichCycle ) ,minpos(iWhichCycle)) ; 
                       end
                    end
                    DescendingPhaseOfInhalation = reshape(DescendingPhaseOfInhalation,[],1);
                    clear peaks minpos Height Distance WhichCycle DerivativeMinForPeaks InCycle SignalAtPeak Which
                 
                    %% DescendingPhaseOfExhalation   
                    DerivativeMinForPeaks =DerivativeMins; 
                    [InCycle,WhichCycle]=InIntervals(DerivativeMinForPeaks, [NewBm.inhalePeaks  NewBm.exhaleTroughs  ] );
                    DerivativeMinForPeaks = DerivativeMinForPeaks(InCycle);
                    SignalAtPeak = NewBm.baselineCorrectedRespiration(DerivativeMinForPeaks);
                    WhichCycle = WhichCycle(InCycle);
                    Height = NewFirstDerivative(DerivativeMinForPeaks);
                    Distance= [ NewBm.exhaleTroughs(WhichCycle) - DerivativeMinForPeaks ] ;
                    Which = [ Distance>0 & SignalAtPeak<=min(MeanThreshold)]  ;
                    peaks = accumarray( WhichCycle(Which) , Height(Which) , [ N_Cycles,1],@nanmin);
                    peaks(accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@NElements)==0) = NaN;;
                    minpos = accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@min_and_idx);
                    minpos(accumarray(WhichCycle(Which)  , Height(Which) , [ N_Cycles,1],@NElements)==0) = NaN;;
                    DescendingPhaseOfExhalation = [];
                    for iWhichCycle = 1 : N_Cycles
                       if isnan(minpos(iWhichCycle))
                             DescendingPhaseOfExhalation(iWhichCycle) = DescendingPhaseOfInhalation(iWhichCycle);
                       else
                            DescendingPhaseOfExhalation(iWhichCycle) =  GetValueFromIndex( DerivativeMinForPeaks(Which & WhichCycle ==iWhichCycle ) ,minpos(iWhichCycle)) ; 
                       end
                    end
                    DescendingPhaseOfExhalation = reshape(DescendingPhaseOfExhalation,[],1);
                    clear peaks minpos Height Distance WhichCycle DerivativeMinForPeaks InCycle SignalAtPeak
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                                
else
                DerivativeMinsAfterPeaks = reshape([NewBm.inhalePeaks+1] , [] ,1) ;
                DescendingPhaseOfExhalation = reshape([NewBm.exhaleTroughs-1] , [] ,1 ) ;
                DerivativeMinsAfterThrough = reshape([CycleIntervals(:,2)] , [] ,1 ) ;
end
              %%  [ DescendingPhaseOfInhalation  DescendingPhaseOfExhalation    ] ;
              DescendingPhaseOfInhalation(isnan(DescendingPhaseOfInhalation)) =DescendingPhaseOfExhalation(isnan(DescendingPhaseOfInhalation)) ;
              DescendingPhaseOfExhalation(isnan(DescendingPhaseOfExhalation)) =DescendingPhaseOfInhalation(isnan(DescendingPhaseOfExhalation)) ;
%% 1) Check that ascending and descending peaks are inside inhalation window;
    %% Inhalation 
    AscendingPhasesInhalationToFix = find(~InIntervals(AscendingPhaseOfInhalation , [ NewBm.inhaleOnsets  NewBm.inhalePeaks ] ));
    NewBm.inhaleOnsets(AscendingPhasesInhalationToFix) = AscendingPhaseOfInhalation(AscendingPhasesInhalationToFix);
    NewBm.exhaleOffsets(AscendingPhasesInhalationToFix(AscendingPhasesInhalationToFix>1)-1) = NewBm.inhaleOnsets(AscendingPhasesInhalationToFix(AscendingPhasesInhalationToFix>1))-1;

    DescendingPhasesInhalationToFix = find(~InIntervals(DescendingPhaseOfInhalation , [ NewBm.inhalePeaks  NewBm.inhaleOffsets ] ));
    NewBm.inhaleOffsets(DescendingPhasesInhalationToFix) = DescendingPhaseOfInhalation(DescendingPhasesInhalationToFix);
    NewBm.exhaleOnsets(DescendingPhasesInhalationToFix) = DescendingPhaseOfInhalation(DescendingPhasesInhalationToFix)+1;

        %% Exhalation
    DeScendingPhasesExhalationToFix = find(~InIntervals(DescendingPhaseOfExhalation , [ NewBm.exhaleOnsets  NewBm.exhaleTroughs ] ));
    NewBm.exhaleOnsets(DeScendingPhasesExhalationToFix) = DescendingPhaseOfExhalation(DeScendingPhasesExhalationToFix);
    NewBm.inhaleOffsets(DeScendingPhasesExhalationToFix) = DescendingPhaseOfExhalation(DeScendingPhasesExhalationToFix)-1;

    AscendingPhaseOfExhalationToFix = find(~InIntervals(AscendingPhaseOfExhalation , [ NewBm.exhaleTroughs NewBm.exhaleOffsets ] ) & ...
        ~ismember(AscendingPhaseOfExhalation,AscendingPhaseOfInhalation) );
    
    NewBm.exhaleOffsets(AscendingPhaseOfExhalationToFix) = AscendingPhaseOfExhalation(AscendingPhaseOfExhalationToFix);
    NewBm.inhaleOnsets(AscendingPhaseOfExhalationToFix+1) = NewBm.exhaleOffsets(AscendingPhaseOfExhalationToFix) +1;
    NewBm.inhaleOnsets = NewBm.inhaleOnsets(1:N_Cycles);    
    
    %% Assume inhalation of cycle 1 starts from index 1;
    NewBm.inhaleOnsets(1)=1;
    
    
    clear AscendingPhasesInhalationToFix AscendingPhaseOfExhalationToFix  DescendingPhasesInhalationToFix DeScendingPhasesExhalationToFix AscendingPhasesInhalationToFix AscendingPhasesInhalationToFix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DerivativeMinsBeforePeaks(1,1) = 1;
%DescendingPhaseOfExhalation(ismember(DerivativeMinsAfterPeaks,DerivativeMinsAfterPeaks)) = 1 +DescendingPhaseOfExhalation(ismember(DerivativeMinsAfterPeaks,DerivativeMinsAfterPeaks)) ;
PutativeInhalationWindow = [NewBm.inhaleOnsets,NewBm.inhaleOffsets ] ;%DerivativeMaxAfterPeaks];
% InhalationInds = indices_to_use & ...
%     InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [PutativeInhalationWindow] ) ;

PutativeInhalationWindow(diff(PutativeInhalationWindow,[],2)==0,:) = ...
    PutativeInhalationWindow(diff(PutativeInhalationWindow,[],2)==0,:) + repmat([-1,1 ],sum(diff(PutativeInhalationWindow,[],2)==0),1);

PutativeExhalationWindow = [NewBm.exhaleOnsets,NewBm.exhaleOffsets];
PutativeExhalationWindow(diff(PutativeExhalationWindow,[],2)==0,:) = ...
PutativeExhalationWindow(diff(PutativeExhalationWindow,[],2)==0,:) + repmat([-1,1 ],sum(diff(PutativeExhalationWindow,[],2)==0),1);

%     ExhalationInds = indices_to_use & ...
%     InIntervals( reshape([1 : numel(NewBm.time)],[],1) , [PutativeExhalationWindow]);
    



NewBm.inhaleOnsets = [ PutativeInhalationWindow(:,1)] ;
NewBm.inhaleOffsets = [ PutativeInhalationWindow(:,2)] ;
NewBm.exhaleOnsets = [ PutativeExhalationWindow(:,1)] ;
NewBm.exhaleOffsets = [ PutativeExhalationWindow(:,2)] ;
NewBm.CycleStart = NewBm.inhaleOnsets;   
NewBm.CycleEnd = [ [NewBm.inhaleOnsets(2:end)-1 ; find(indices_to_use,1,'last')]];
CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];

InBandForPause = indices_to_use & ...
        ~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) , [1,NewBm.inhalePeaks(1)])) & ...
        ...~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) , [NewBm.inhalePeaks]+[-1,1])) & ...
        ...~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) , [NewBm.exhaleTroughs]+[-1,1])) & ...
        ...~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) ,...
        ... [   AscendingPhaseOfInhalation(InIntervals(  AscendingPhaseOfInhalation ,PutativeInhalationWindow) ) , ...
        ...     NewBm.inhalePeaks(InIntervals(  AscendingPhaseOfInhalation ,PutativeInhalationWindow) )+1 ] ) ) & ...
        ~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) , [AscendingPhaseOfInhalation ,DescendingPhaseOfInhalation])) & ...
        ~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) , [DescendingPhaseOfExhalation ,AscendingPhaseOfExhalation])) & ...
         ...InIntervals(NewBm.baselineCorrectedRespiration, [inhalePauseStats.BaselineCorrected.FifthPercentile inhalePauseStats.BaselineCorrected.NinetyFifthPercentile]) & ...
        or(InIntervals(NewBm.baselineCorrectedRespiration, [inhalePauseStats.BaselineCorrected.FifthPercentile inhalePauseStats.BaselineCorrected.NinetyFifthPercentile]) ,...
        InIntervals(NewBm.rawRespiration, [inhalePauseStats.RawSignal.FifthPercentile inhalePauseStats.RawSignal.NinetyFifthPercentile]) ) & ...
        InIntervals(NewFirstDerivative, [DerivativeBand] ) ; ...& ...
         ...InIntervals(NewSecondDerivative , [SecondDerivativeBand] ) ;
       ... ~(InIntervals( reshape([1 : numel(NewBm.time)],[],1) , ...
           
        ...  [  DescendingPhaseOfExhalation(InIntervals(  DescendingPhaseOfExhalation ,PutativeExhalationWindow) ) , ...
        ...     NewBm.exhaleTroughs(InIntervals(  DescendingPhaseOfExhalation ,PutativeExhalationWindow) )+1 ] ) ) & ...
        ...

InBandForPauseInds = DetectMarginsFromArray(InBandForPause,find(InBandForPause)) ;
%InBandForPauseInds(  diff(InBandForPauseInds,[],2)<2,:)=[];


PutativePauses =   ...
    ...not(InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [1,NewBm.inhalePeaks(1)])) & ...
    ...not(InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [NewBm.inhaleOnsets,NewBm.inhalePeaks])) & ...
    ...not(InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [NewBm.inhalePeaks,DerivativeMinsAfterPeaks])) & ...
    ~(InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [PutativeInhalationWindow])) & ...
    ~(InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [PutativeExhalationWindow])) & ...
    ...not(InIntervals( reshape([1 : numel(NewBm.time)],[],1)      , [DescendingPhaseOfExhalation,DerivativeMinsAfterThrough])) & ...    
    indices_to_use & ...
    ...InIntervals(NewBm.baselineCorrectedRespiration, [inhalePauseStats.BaselineCorrected.FifthPercentile inhalePauseStats.BaselineCorrected.NinetyFifthPercentile]) & ...
        or(InIntervals(NewBm.baselineCorrectedRespiration, [inhalePauseStats.BaselineCorrected.FifthPercentile inhalePauseStats.BaselineCorrected.NinetyFifthPercentile]) ,...
        InIntervals(NewBm.rawRespiration, [inhalePauseStats.RawSignal.FifthPercentile inhalePauseStats.RawSignal.NinetyFifthPercentile]) )    & ...
        InIntervals(NewFirstDerivative, [DerivativeBand] ) ;
    
PausesInds = DetectMarginsFromArray(PutativePauses,find(PutativePauses)) ;PausesInds(  diff(PausesInds,[],2)==0,:)=[];%PausesInds = PausesInds(1:numel(NewBm.inhaleOnsets),:) ;%PutativePauses = InIntervals( reshape([1 : numel(NewBm.time)],[],1),PausesInds);
if not(isempty(PausesInds))
    PausesInds = [PausesInds(:,1)+1 , PausesInds(:,2)-1] ;
    PausesInds(    diff(PausesInds,[],2)<=2 , :) =[];
end;

if PLOT_ON
s2=subplot(3,1,2);
ylim([DerivativeBand ]*10)

PlotIntervals(NewBm.time([RemoveNansFromHorizontalRows(PutativeInhalationWindow)]) ,'color','r','alpha',0.1)
PlotIntervals(NewBm.time([ RemoveNansFromHorizontalRows(   PutativeExhalationWindow) ]) ,'color','b','alpha',0.1)
if ~isempty(InBandForPauseInds)
    PlotIntervals(  NewBm.time(InBandForPauseInds),'color','g','alpha',0.2);
end
if ~isempty(PausesInds)
    PlotIntervals(  NewBm.time(PausesInds),'color',rgb('black'),'alpha',0.5);
end

xlim(FindExtremesOfArray(NewBm.time(indices_to_use)))     ;

scatter(NewBm.time(NewBm.inhalePeaks), NewFirstDerivative(NewBm.inhalePeaks),'r','filled');
scatter(NewBm.time(NewBm.exhaleTroughs), NewFirstDerivative(NewBm.exhaleTroughs),'b','filled');

scatter(NewBm.time(AscendingPhaseOfInhalation ),  NewFirstDerivative(AscendingPhaseOfInhalation  ) ,[],'y','filled');
scatter(NewBm.time(DescendingPhaseOfInhalation ),  NewFirstDerivative(DescendingPhaseOfInhalation  ) ,[],rgb('orange'),'filled');

scatter(NewBm.time(DescendingPhaseOfExhalation ),   NewFirstDerivative(DescendingPhaseOfExhalation  ), [] ,'cyan','filled');
scatter(NewBm.time(RemoveNaNsFromVector(   AscendingPhaseOfExhalation )),       NewFirstDerivative(RemoveNaNsFromVector(AscendingPhaseOfExhalation ) ) ,[],'g','filled');
set(gca,'XTick',    NewBm.time(CycleIntervals(:,1)) )
title(['Interval # ' num2str( CycleID ) ' Derivative']);
linkaxes([s1,s2],'x');
% yyaxis right ; 
% plot(NewBm.indices,NewSecondDerivative,'b','LineStyle','--')
end


PausesInds = sortrows([ PausesInds; InBandForPauseInds]);
if ~isempty(PausesInds) & size(PausesInds,1)>1 ;
PausesInds = ConsolidateIntervals(PausesInds);
end;
% exclude just minima/maxima from pauses;
%PausesInds(diff(PausesInds,[],2)==0,:)=[];

%% 3 - Define Inhal/Exhal relative to the min-max of each cycle;
% A) Detect if they are assigned to previously classed inhalation 
if not(isempty(PausesInds))
    ThisPauseInPutativeInhalationWindow = ...
        ...InIntervals( nanmean(PausesInds,2) , sort([PutativeInhalationWindow(:,1) PutativeExhalationWindow(:,1)],2) ) | ...
        ...InIntervals( PausesInds(:,1) , sort([PutativeInhalationWindow(:,1) PutativeExhalationWindow(:,1)],2) ) | ...
        ...InIntervals( PausesInds(:,2) , sort([PutativeInhalationWindow(:,1) PutativeExhalationWindow(:,1)],2)) | ...
        InIntervals( PausesInds(:,1) , sort([ DescendingPhaseOfInhalation  NewBm.exhaleTroughs],2)) & ...
        InIntervals( PausesInds(:,2) , sort([ DescendingPhaseOfInhalation  NewBm.exhaleTroughs],2) ) ;
        
%         InIntervals( PausesInds(:,1) , sort([max([DerivativeMinsAfterPeaks,DerivativeMaxAfterPeaks],[], 2) NewBm.exhaleTroughs],2)) & ...
%         InIntervals( PausesInds(:,2) , sort([max([DerivativeMinsAfterPeaks,DerivativeMaxAfterPeaks],[], 2) NewBm.exhaleTroughs],2));
    
    ThisPauseInPutativeExhalationWindow =  ...
        ...%InIntervals( PausesInds(:,1) , sort([PutativeExhalationWindow(:,2) CycleIntervals(:,2)],2)  ) | ...
        ...%InIntervals( PausesInds(:,2) , sort([PutativeExhalationWindow(:,2) CycleIntervals(:,2)],2)  ) | ...
        InIntervals( PausesInds(:,1) ,  [AscendingPhaseOfExhalation(1:end-1)       AscendingPhaseOfInhalation(2:end) ; AscendingPhaseOfExhalation(end) PutativeExhalationWindow(end,2)]) & ...
        InIntervals( PausesInds(:,2) ,  [AscendingPhaseOfExhalation(1:end-1)       AscendingPhaseOfInhalation(2:end) ; AscendingPhaseOfExhalation(end) PutativeExhalationWindow(end,2)]) ;
        %AscendingPhaseOfExhalation(8)
        %InIntervals( PausesInds(:,1) , sort([DerivativeMinsAfterThrough PutativeExhalationWindow(:,2)],2)  ) &... ;
        %InIntervals( PausesInds(:,2) , sort([DerivativeMinsAfterThrough PutativeExhalationWindow(:,2)],2)  ) ;
    %ThisPauseInPutativeExhalationWindow = InIntervals( PausesInds(:,1) , [PutativeExhalationWindow(1:end-1,2) PutativeInhalationWindow(2:end,1);    PutativeExhalationWindow(end,2)  CycleIntervals(end,2)]) |  InIntervals( PausesInds(:,2) , [PutativeExhalationWindow(1:end-1,2) PutativeInhalationWindow(2:end,1);    PutativeExhalationWindow(end,2)  CycleIntervals(end,2)])
else
    ThisPauseInPutativeInhalationWindow = false;    WhichInhalationCycle = [];InhalationPause =[];
    ThisPauseInPutativeExhalationWindow = false;    WhichExhalationCycle = [];ExhalationPause =[];
end
% B) Then check they are the min-max in each cycle
if any(ThisPauseInPutativeInhalationWindow)  
    InhalationPause =   PausesInds(ThisPauseInPutativeInhalationWindow ,:);  
    [~,WhichInhalationCycle] = InIntervals( InhalationPause(:,1) , [CycleIntervals ] );
    InhalationPause([ InhalationPause(:,1)] < AscendingPhaseOfInhalation(WhichInhalationCycle) ,:) =[];   
    [~,WhichInhalationCycle] = InIntervals( InhalationPause(:,1) , [CycleIntervals ] );
    InhalationPause([ InhalationPause(:,2)] < AscendingPhaseOfInhalation(WhichInhalationCycle) ,:) =[];
    [~,WhichInhalationCycle] = InIntervals( InhalationPause(:,1) , [CycleIntervals ] );
    InhalationPause([ InhalationPause(:,1)] < NewBm.inhalePeaks(WhichInhalationCycle) ,:) =[];
    [~,WhichInhalationCycle] = InIntervals( InhalationPause(:,1) , [CycleIntervals ] );
    %InhalationPause(diff(InhalationPause,[],2)<=1,:) = [];
    %[~,WhichInhalationCycle] = InIntervals( InhalationPause(:,1) , [CycleIntervals ] );
    if any((NewBm.exhaleTroughs(WhichInhalationCycle) < InhalationPause(:,2)))
        WrongInhalation = find(NewBm.exhaleTroughs(WhichInhalationCycle) < InhalationPause(:,2));
        ToRemove = ( InhalationPause( WrongInhalation  ,1) > GetValueFromIndex(   NewBm.exhaleTroughs(WhichInhalationCycle),WrongInhalation));
        InhalationPauseEnds = (GetValueFromIndex(   NewBm.exhaleOnsets(WhichInhalationCycle),WrongInhalation( ~ToRemove))) -1 ;
        %             NewBm.inhaleOffsets ( WhichInhalationCycle(WrongInhalation( ~ToRemove)))
        %             (GetValueFromIndex(   NewBm.inhaleOffsets(WhichInhalationCycle),WrongInhalation( ~ToRemove)))
        InhalationPauseEnds(InhalationPauseEnds < InhalationPause( WrongInhalation( ~ToRemove)  ,2)) = ...
            min([([ DerivativeMaxAfterPeaks(WhichInhalationCycle(WrongInhalation( ~ToRemove)) ) ,DescendingPhaseOfExhalation(WhichInhalationCycle(WrongInhalation( ~ToRemove))) ])],[],2) ;
        InhalationPause( WrongInhalation(~ToRemove)  , 2 ) = InhalationPauseEnds;
        InhalationPause( WrongInhalation(ToRemove)  , : ) = [];
        [~,WhichInhalationCycle] = InIntervals( InhalationPause(:,1) , [CycleIntervals ] );
        clear WrongInhalation ToRemove InhalationPauseEnds;
    end
    
        
        if ~isempty(WhichInhalationCycle)
           
            if SelectOnlyLargeForInhalation
                %% if you only want to select the largest use the code below;
                LargestPauseCycles =  (accumarray(WhichInhalationCycle , diff(InhalationPause,[],2), [N_Cycles,1] ,@max_and_idx )) ;
                LargestPauseInhalationPause = [];
                LargestPauseWhichInhalationCycle = [];
                for iCycle = 1 : N_Cycles;
                    if LargestPauseCycles( iCycle)
                        LargestPauseInhalationPause(iCycle,:) =   GetThisRowFromMatrix(InhalationPause(WhichInhalationCycle == iCycle , :), LargestPauseCycles( iCycle));
                        LargestPauseWhichInhalationCycle(iCycle,:) = iCycle;
                    else
                        LargestPauseInhalationPause(iCycle,:) = [0,0];
                        LargestPauseWhichInhalationCycle(iCycle,:)  = 0;
                    end
                end;
                LargestPauseInhalationPause(LargestPauseWhichInhalationCycle==0,:) = [];
                LargestPauseWhichInhalationCycle(LargestPauseWhichInhalationCycle==0,:) = [];
            else
                %% if you want to merge the as a single pause use the code below;;
                LargestPauseInhalationPause = [ ...
                    accumarray( WhichInhalationCycle , InhalationPause(:,1), [ N_Cycles,1], @min)  ,...
                    accumarray( WhichInhalationCycle , InhalationPause(:,2), [ N_Cycles,1], @max) ];
                LargestPauseWhichInhalationCycle = [1:N_Cycles]';
                
                LargestPauseWhichInhalationCycle(diff(LargestPauseInhalationPause,[],2)==0,:) = [];
                LargestPauseInhalationPause(diff(LargestPauseInhalationPause,[],2)==0,:) = [];
                
            end
           
            
        InhalationPause = [ ...
                        ... accumarray(WhichInhalationCycle , InhalationPause(:,1), [N_Cycles,1] ,@min ), ...
                        accumarray(LargestPauseWhichInhalationCycle , LargestPauseInhalationPause(:,1), [N_Cycles,1] ,@min ) , ...
                        accumarray(WhichInhalationCycle , InhalationPause(:,2), [N_Cycles,1] ,@max )] ;
        WhichInhalationCycle = unique(LargestPauseWhichInhalationCycle);
        InhalationPause = InhalationPause(LargestPauseWhichInhalationCycle,:);
        clear LargestPauseInhalationPause LargestPauseWhichInhalationCycle LargestPauseCycles
        end
else
    WhichInhalationCycle = [];
end
% C) Detect if they are assigned to previously classed inhalation 
if any(ThisPauseInPutativeExhalationWindow) 
        clear WhichExhalationCycle
        ExhalationPause =   PausesInds(ThisPauseInPutativeExhalationWindow ,:);
        [~,WhichExhalationCycle(:,1)] = InIntervals( ExhalationPause(:,1) , [AscendingPhaseOfExhalation(1:end-1)       AscendingPhaseOfInhalation(2:end) ; AscendingPhaseOfExhalation(end) PutativeExhalationWindow(end,2)]) ;
        
        %[~,WhichExhalationCycle(:,2)] = InIntervals( ExhalationPause(:,2) , [DerivativeMinsAfterThrough(1:end-1)       AscendingPhaseOfInhalation(2:end) ; DerivativeMinsAfterThrough(end) PutativeExhalationWindow(end,2)]); 
        %[~,WhichExhalationCycle(:,1)] = InIntervals( ExhalationPause(:,1) , [CycleIntervals] );
        %[~,WhichExhalationCycle(:,2)] = InIntervals( ExhalationPause(:,2) , [CycleIntervals] );
       
%        if ~isequal(WhichExhalationCycle(:,1),WhichExhalationCycle(:,2))
%         ExhalationPause(WhichExhalationCycle(:,1) ~= WhichExhalationCycle(:,2),2) = [CycleIntervals(WhichExhalationCycle(WhichExhalationCycle(:,1) ~= WhichExhalationCycle(:,2) , 1),2) ];
%             clear WhichExhalationCycle
%         [~,WhichExhalationCycle(:,1)] = InIntervals( ExhalationPause(:,1) , [CycleIntervals] );
%         [~,WhichExhalationCycle(:,2)] = InIntervals( ExhalationPause(:,2) , [CycleIntervals] );
%         WhichExhalationCycle = nanmean(WhichExhalationCycle,2);
%        else
%            WhichExhalationCycle = WhichExhalationCycle(:,1);
%        end
       
       if any( NewBm.exhaleTroughs(WhichExhalationCycle) > ExhalationPause(:,1) )
            WrongExhalation = find(NewBm.exhaleTroughs(WhichExhalationCycle) > ExhalationPause(:,1) ) ; 
            ToRemove = ( ExhalationPause( WrongExhalation  ,1) < GetValueFromIndex(   NewBm.exhaleTroughs(WhichExhalationCycle),WrongExhalation));
            ExhalationPause( WrongExhalation( ~ToRemove)  ,1) =  GetValueFromIndex(   NewBm.exhaleOffsets(WhichExhalationCycle),WrongExhalation( ~ToRemove)) +1;
            ExhalationPause( WrongExhalation(ToRemove)  , : ) = [];
            [~,WhichExhalationCycle] = InIntervals( ExhalationPause(:,1) , [[DerivativeMinsAfterThrough(1:end-1)       AscendingPhaseOfInhalation(2:end) ; DerivativeMinsAfterThrough(end) PutativeExhalationWindow(end,2)] ] );
            clear WrongExhalation ToRemove ; 
       end
       if ~isempty(WhichExhalationCycle)
            if SelectOnlyLargeForExhalation

                LargestPauseCycles =  (accumarray(WhichExhalationCycle , diff(ExhalationPause,[],2), [N_Cycles,1] ,@max_and_idx )) ;
                LargestPauseExhalationPause = [];
                LargestPauseWhichExhalationCycle = [];
                for iCycle = 1 : N_Cycles;
                    if LargestPauseCycles( iCycle)
                        LargestPauseExhalationPause(iCycle,:) =   GetThisRowFromMatrix(ExhalationPause(WhichExhalationCycle == iCycle , :), LargestPauseCycles( iCycle));
                        LargestPauseWhichExhalationCycle(iCycle,:) = iCycle;
                    else
                        LargestPauseExhalationPause(iCycle,:) = [0 ,0 ];
                        LargestPauseWhichExhalationCycle(iCycle,:) = 0;
                    end
                end;
                LargestPauseExhalationPause(LargestPauseWhichExhalationCycle==0,:) = [];
                LargestPauseWhichExhalationCycle(LargestPauseWhichExhalationCycle==0,:) = [];
           else
                LargestPauseExhalationPause = [ ...
                    accumarray( WhichExhalationCycle , ExhalationPause(:,1), [ N_Cycles,1], @min)  ,...
                    accumarray( WhichExhalationCycle , ExhalationPause(:,2), [ N_Cycles,1], @max) ];
                LargestPauseWhichExhalationCycle = [1:N_Cycles]';
                
                LargestPauseWhichExhalationCycle(diff(LargestPauseExhalationPause,[],2)==0,:) = [];
                LargestPauseExhalationPause(diff(LargestPauseExhalationPause,[],2)==0,:) = [];
  
                
            end
        ExhalationPause = [ ...
                        ... accumarray(WhichExhalationCycle , ExhalationPause(:,1), [N_Cycles,1] ,@min ), ...
                        accumarray(LargestPauseWhichExhalationCycle , LargestPauseExhalationPause(:,1), [N_Cycles,1] ,@min ) , ...
                        accumarray(WhichExhalationCycle , ExhalationPause(:,2), [N_Cycles,1] ,@max )] ;
        WhichExhalationCycle = unique(LargestPauseWhichExhalationCycle);
        ExhalationPause = ExhalationPause(WhichExhalationCycle,:);
        clear LargestPauseExhalationPause LargestPauseWhichExhalationCycle LargestPauseCycles
        
        [~,WhichExhalationCycle] = InIntervals( ExhalationPause(:,1) , [[AscendingPhaseOfExhalation(1:end-1)       AscendingPhaseOfInhalation(2:end) ; AscendingPhaseOfExhalation(end) PutativeExhalationWindow(end,2)] ] );
       end
else
    WhichExhalationCycle = [];
end
%% 4 Update Inhalation info
NewBm.inhalePauseOnsets( ~ismember(1:N_Cycles,WhichInhalationCycle)  )  =NaN;  
NewBm.inhalePauseDurations( ~ismember(1:N_Cycles,WhichInhalationCycle)  )  =0;  
if   any(ThisPauseInPutativeInhalationWindow) ; %% or(FixInhalation ) ;
    %NewBm.inhaleOnsets(WhichInhalationCycle)
    NewBm.inhaleOffsets(WhichInhalationCycle) = InhalationPause(:,1) -1;
    NewBm.exhaleOnsets(WhichInhalationCycle) = InhalationPause(:,2)+1;  
    if  any(NewBm.exhaleOnsets(WhichInhalationCycle) > NewBm.exhaleOffsets(WhichInhalationCycle)) 
        NewBm.exhaleOnsets(WhichInhalationCycle) = NewBm.exhaleOffsets(WhichInhalationCycle) ;
        NewBm.exhaleOffsets(WhichInhalationCycle) = NewBm.exhaleOnsets(WhichInhalationCycle) + 1;
    end
    NewBm.inhalePauseOnsets(WhichInhalationCycle) = InhalationPause(:,1);
    NewBm.inhalePauseDurations(WhichInhalationCycle) = diff(NewBm.time(InhalationPause),[],2);
end

%% 5 Update Exhalation info
NewBm.exhalePauseOnsets( ~ismember(1:N_Cycles,WhichExhalationCycle)  )  =NaN;  
NewBm.exhalePauseDurations( ~ismember(1:N_Cycles,WhichExhalationCycle)  )  =0;  
if any(ThisPauseInPutativeExhalationWindow) ;  %or(FixExhalation , 
     NewBm.exhaleOffsets(WhichExhalationCycle) = ExhalationPause(:,1)-1 ;
    % Update the start of following cycle  ?
     NewBm.inhaleOnsets( WhichExhalationCycle+1 ) =ExhalationPause(:,2)+1 ;
     NewBm.inhaleOnsets = NewBm.inhaleOnsets(1:numel(NewBm.inhalePeaks));
     
     NewBm.exhalePauseOnsets(WhichExhalationCycle) = ExhalationPause(:,1);
     NewBm.exhalePauseDurations(WhichExhalationCycle) = diff(NewBm.time(ExhalationPause),[],2);
end
    
    NewBm.CycleStart = NewBm.inhaleOnsets;   
    NewBm.CycleEnd = [ [NewBm.inhaleOnsets(2:end)-1 ; find(indices_to_use,1,'last')]];
    CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];

    NewBm.exhaleOffsets((~isnan(NewBm.exhalePauseOnsets))) = NewBm.exhalePauseOnsets(~isnan(NewBm.exhalePauseOnsets))-1;
    NewBm.exhaleOffsets(    isnan(NewBm.exhalePauseOnsets)) = NewBm.CycleEnd(    isnan(NewBm.exhalePauseOnsets)) ;
    CycleIntervals= [NewBm.CycleStart, NewBm.CycleEnd  ];

    NewBm.inhaleDurations = reshape(    NewBm.time(NewBm.inhaleOffsets) - NewBm.time(NewBm.inhaleOnsets),[],1);
    NewBm.exhaleDurations = reshape(  NewBm.time(NewBm.exhaleOffsets) - NewBm.time(NewBm.exhaleOnsets),[],1);
    NewBm.inhalePauseDurations(not(isnan(NewBm.inhalePauseOnsets))) =  NewBm.time(NewBm.exhaleOnsets(not(isnan(NewBm.inhalePauseOnsets)))-1) - NewBm.time(NewBm.inhalePauseOnsets(not(isnan(NewBm.inhalePauseOnsets))));
    NewBm.exhalePauseDurations(not(isnan(NewBm.exhalePauseOnsets))) =  NewBm.time(CycleIntervals(not(isnan(NewBm.exhalePauseOnsets)),2)) - NewBm.time(NewBm.exhalePauseOnsets(  not(isnan(NewBm.exhalePauseOnsets)))) ;
      
    [NewBm.inhaleVolumes,NewBm.exhaleVolumes] = findRespiratoryVolumes(NewBm.baselineCorrectedRespiration,srate, ...
    NewBm.inhaleOnsets', NewBm.exhaleOnsets', NewBm.inhaleOffsets', NewBm.exhaleOffsets');
    NewBm.inhaleVolumes = reshape(NewBm.inhaleVolumes , [] , 1) ;
    NewBm.exhaleVolumes = reshape(NewBm.exhaleVolumes , [] , 1 ) ;
    NewBm.inhaleTimeToPeak =    reshape((NewBm.inhalePeaks-NewBm.inhaleOnsets)/ srate,[],1) ;
    NewBm.exhaleTimeToTrough =  reshape((NewBm.exhaleTroughs-NewBm.exhaleOnsets)/ srate,[],1) ;
    NewBm.peakInspiratoryFlows = reshape(NewBm.baselineCorrectedRespiration( NewBm.inhalePeaks),[],1) ;
    NewBm.troughExpiratoryFlows = reshape(NewBm.baselineCorrectedRespiration(NewBm.exhaleTroughs ),[],1) ;

    if  PLOT_ON
        delete(subplot(3,1,3));
        s3 = subplot(3,1,3);
        plot(NewBm.time,NewBm.baselineCorrectedRespiration,'Color','k'); hold on ;         
        %plot(OldBm.time,OldBm.rawRespiration,'Color','g'); hold on ;
        %plot(NewBm.time,NewBm.rawRespiration,'Color','b'); hold on ;

        linkaxes([s1, s2,s3],'x');
        linkaxes([s1,s3],'y');

        scatter(NewBm.time(NewBm.inhalePeaks),NewBm.baselineCorrectedRespiration(NewBm.inhalePeaks),'r','filled');
        scatter(NewBm.time(NewBm.exhaleTroughs),NewBm.baselineCorrectedRespiration(NewBm.exhaleTroughs),'b','filled');
        line(xlim(),[MeanThreshold,MeanThreshold],'Color','r')
        %scatter(NewBm.indices(DerivativeMinsBeforePeaks ), NewBm.baselineCorrectedRespiration(DerivativeMinsBeforePeaks  ) , [], rgb('Orange'),'filled');
        scatter(NewBm.time(AscendingPhaseOfInhalation ),  NewBm.baselineCorrectedRespiration(AscendingPhaseOfInhalation  ) ,[],'y','filled');
        scatter(NewBm.time(DescendingPhaseOfInhalation ),  NewBm.baselineCorrectedRespiration(DescendingPhaseOfInhalation  ) ,[],rgb('orange'),'filled');

        %scatter(NewBm.indices(DerivativeMaxAfterPeaks ),  NewBm.baselineCorrectedRespiration(DerivativeMaxAfterPeaks  ) ,[],'r','filled');
        %scatter(NewBm.indices(DerivativeMinsAfterPeaks ),  NewBm.baselineCorrectedRespiration(DerivativeMinsAfterPeaks  ) ,[],'r','filled');
        scatter(NewBm.time(DescendingPhaseOfExhalation ),   NewBm.baselineCorrectedRespiration(DescendingPhaseOfExhalation  ), [] ,'cyan','filled');
        scatter(NewBm.time(RemoveNaNsFromVector(AscendingPhaseOfExhalation )),       NewBm.baselineCorrectedRespiration(RemoveNaNsFromVector(AscendingPhaseOfExhalation ) ) ,[],'g','filled');
        %scatter(NewBm.indices(DerivativeMinsAfterThrough ) ,   NewBm.baselineCorrectedRespiration(DerivativeMinsAfterThrough  ), [], 'blue','filled');
        
        xlim(FindExtremesOfArray(NewBm.time(indices_to_use)))     ;
        ylim([-1,1]*max(abs(ylim())));
        line(xlim(), repmat(inhalePauseStats.BaselineCorrected.FifthPercentile ,1,2) ,'Color','k','LineStyle','--');
        line(xlim(), repmat(inhalePauseStats.BaselineCorrected.NinetyFifthPercentile ,1,2) ,'Color','k','LineStyle','--');
        PlotIntervals(NewBm.time([ NewBm.inhaleOnsets ,NewBm.inhaleOffsets]),'color','r','alpha',0.25);
        if any(~isnan(NewBm.inhalePauseOnsets))
            %PlotIntervals([NewBm.indices(NewBm.inhalePauseOnsets(not(isnan(NewBm.inhalePauseOnsets))))'] + [zeros(numel(NewBm.inhalePauseOnsets(not(isnan(NewBm.inhalePauseOnsets)))),1) ,  NewBm.inhalePauseDurations(not(isnan(NewBm.inhalePauseOnsets))) *srate],'color','k','alpha',0.25);
            PlotIntervals([NewBm.time(NewBm.inhalePauseOnsets(not(isnan(NewBm.inhalePauseOnsets))))'] + [zeros(numel(NewBm.inhalePauseOnsets(not(isnan(NewBm.inhalePauseOnsets)))),1) ,  NewBm.inhalePauseDurations(not(isnan(NewBm.inhalePauseOnsets))) ],'color','k','alpha',0.25);
        end
        PlotIntervals(NewBm.time([ NewBm.exhaleOnsets ,NewBm.exhaleOffsets]),'color','b','alpha',0.25);
        if any(~isnan(NewBm.exhalePauseOnsets))
                %PlotIntervals([NewBm.indices(NewBm.exhalePauseOnsets(not(isnan(NewBm.exhalePauseOnsets))))'] + [zeros(numel(NewBm.exhalePauseOnsets(not(isnan(NewBm.exhalePauseOnsets)))),1) ,  NewBm.exhalePauseDurations(not(isnan(NewBm.exhalePauseOnsets))) *srate],'color','k','alpha',0.25);
                PlotIntervals([NewBm.time(NewBm.exhalePauseOnsets(not(isnan(NewBm.exhalePauseOnsets))))'] + [zeros(numel(NewBm.exhalePauseOnsets(not(isnan(NewBm.exhalePauseOnsets)))),1) ,  NewBm.exhalePauseDurations(not(isnan(NewBm.exhalePauseOnsets))) ],'color','k','alpha',0.25);
        end

        title(['Interval # ' num2str( CycleID ) ' Output'])
%        set(gca,'XTick',[NewBm.time(NewBm.inhaleOnsets) ], 'XTickLabel', char(SetDecimals([1:numel(NewBm.inhaleOnsets )],0))  )
        %xlabel('Cycle ID');
        xlabel('Time (s)');
        linkaxes([s1, s2,s3],'x');
        linkaxes([s1,s3],'y');
        yyaxis right
        plot(NewBm.time,NewBm.rawRespiration,'Color','b');
        ylim([-1,1]*max(abs(ylim())));ylabel('Raw');
        line(xlim(), repmat(inhalePauseStats.RawSignal.FifthPercentile ,1,2) ,'Color','b','LineStyle','--');
        line(xlim(), repmat(inhalePauseStats.RawSignal.NinetyFifthPercentile ,1,2) ,'Color','b','LineStyle','--');
        
        
    end;
    

    clear FinalTest;
    FinalTest(:,1) = InIntervals( reshape([NewBm.time],[],1)   ,  [NewBm.time([NewBm.inhaleOnsets ,NewBm.inhaleOffsets])] );
    FinalTest(:,2) = InIntervals( reshape([NewBm.time],[],1)   ,  [reshape(NewBm.time(NewBm.inhalePauseOnsets(~isnan(NewBm.inhalePauseOnsets))),[],1) + [zeros(sum((~isnan(NewBm.inhalePauseOnsets)),1),1), NewBm.inhalePauseDurations(~isnan(NewBm.inhalePauseOnsets)) ]]);
    FinalTest(:,3) = InIntervals( reshape([NewBm.time],[],1)   ,  [NewBm.time([NewBm.exhaleOnsets ,NewBm.exhaleOffsets])]);
    FinalTest(:,4) = InIntervals( reshape([NewBm.time],[],1)   ,  [reshape(NewBm.time(NewBm.exhalePauseOnsets(~isnan(NewBm.exhalePauseOnsets))),[],1) + [zeros(sum((~isnan(NewBm.exhalePauseOnsets)),1),1), NewBm.exhalePauseDurations(~isnan(NewBm.exhalePauseOnsets)) ]]);
    
    [m  ] = find(nansum(FinalTest,2)>1) ;
    
    if not(isempty(m))  
        [~,CyclesToFix] = InIntervals(m, [CycleIntervals ]);
        FinalTest(m,:) ; 
        disp([num2str(numel(m)) ' ts wrong in Cycles ' num2str(reshape(unique(CyclesToFix),1,[]),0)] )
        %clear NewBm
    end

    if any(NewBm.exhaleDurations<0)
        clear NewBm
    end
    if any(NewBm.inhaleDurations<0)
        clear NewBm
    end
     

else ;; %% No peaks detected;
     [   NewBm.inhalePeaks , NewBm.exhaleTroughs , NewBm.peakInspiratoryFlows, NewBm.troughExpiratoryFlows, ...
         NewBm.inhaleOnsets , NewBm.exhaleOnsets , NewBm.inhaleOffsets , NewBm.exhaleOffsets  , NewBm.inhaleTimeToPeak , ...
         NewBm.exhaleTimeToTrough , NewBm.inhaleVolumes , NewBm.exhaleVolumes , NewBm.inhaleDurations , NewBm.exhaleDurations , ...
         NewBm.inhalePauseOnsets , NewBm.exhalePauseOnsets , NewBm.inhalePauseDurations, NewBm.exhalePauseDurations , NewBm.CycleStart, NewBm.CycleEnd] = deal([]);
end
    

    
NewBm.time = reshape(NewBm.time, [] ,1);
NewBm = RemoveFieldsFromStrucrue(NewBm,{'indices'});
    
    
end