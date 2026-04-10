function  [bmObj , PostProcessesSniffIntToUse  , PostProcessesGoodSniffInt ]  = RemoveExtraCyclesFromSniffTrace(In , ImpossibleLength , LowFrequencySampling ,SniffIntToUse  , DetectedGoodSniffInt, OriginalBmWindow)

%% Function written by GC to check for possible issues with multiple runs of breathmetrics;
    bmObj = In;
    N_Cycles = numel(bmObj.CycleStart);
    PlotOverlapping = false;
%% 1) Check that cycle start always follows cycle end of previous cycle (.e. they do not overlap);
if any(~[bmObj.CycleStart(2:N_Cycles) > bmObj.CycleEnd(1:N_Cycles-1)])
    CyclesToRemove = [];
    OverlappingCycles = 1 + find(~[bmObj.CycleStart(2:N_Cycles) > bmObj.CycleEnd(1:N_Cycles-1)]);
    disp([ 'Fraction of overlapping cycles = ' num2str(100*numel(OverlappingCycles) / N_Cycles ) ' % from breathmetrics...' ] )
    %OverlappingCycles = [8183;     8416 ; 8417 ; 8418] ;
    for iCycle = 1  :numel(OverlappingCycles); 
        WhichCycle = OverlappingCycles(iCycle) ;
        %NewOnset = knnsearch(   reshape([ bmObj.smoothedRespiration(    (bmObj.CycleStart(WhichCycle)  : bmObj.inhalePeaks(WhichCycle) )   )]  ,[],1) , bmObj.smoothedRespiration((bmObj.inhaleOffsets(WhichCycle)))) ;
        %bmObj.CycleStart(WhichCycle) = bmObj.CycleStart(WhichCycle)+NewOnset+1;       
        NewOnset = knnsearch(   reshape([ bmObj.smoothedRespiration(    (bmObj.exhaleTroughs(WhichCycle-1)  : bmObj.inhalePeaks(WhichCycle) )   )]  ,[],1) , bmObj.smoothedRespiration((bmObj.inhaleOffsets(WhichCycle)))) ;
        % [bmObj.CycleStart(OverlappingCycles), bmObj.inhalePeaks(OverlappingCycles) , bmObj.CycleEnd(OverlappingCycles) ]
        try
            bmObj.CycleStart(WhichCycle) = bmObj.exhaleTroughs(WhichCycle-1)+NewOnset+1;       
        
        catch
            if bmObj.exhaleTroughs(WhichCycle-1)     >  bmObj.inhalePeaks(WhichCycle)  
                disp('Merge this cycle');
                CyclesToRemove = [CyclesToRemove ; WhichCycle-1];  
                bmObj.CycleEnd(WhichCycle-1) = bmObj.CycleEnd(WhichCycle);
            else
                disp('Fix this cycle');
            end
        end
         
               
        bmObj.inhaleOnsets(WhichCycle) = bmObj.CycleStart(WhichCycle);       
        bmObj.CycleEnd(WhichCycle-1) =  bmObj.CycleStart(WhichCycle)-1;
        
        if isnan( bmObj.exhalePauseOnsets(WhichCycle-1))
           bmObj.exhaleOffsets(WhichCycle-1) = bmObj.CycleEnd(WhichCycle-1);
           bmObj.exhalePauseDurations(WhichCycle-1) = 0;
        else
            if bmObj.exhalePauseOnsets(WhichCycle-1) >= bmObj.CycleStart(WhichCycle)
                bmObj.exhalePauseOnsets(WhichCycle-1) = NaN;
                bmObj.exhalePauseDurations(WhichCycle-1) = 0;
            end
            
                if bmObj.exhalePauseOnsets(WhichCycle-1) < bmObj.CycleStart(WhichCycle)
                    %disp(['Update Pauses after exhale '])
                    bmObj.exhalePauseDurations(WhichCycle-1) = ...
                    diff([ bmObj.time( bmObj.exhalePauseOnsets(WhichCycle-1) )         bmObj.time(bmObj.CycleEnd(WhichCycle-1) )  ],[],2);
                end
        end
    
        
   if PlotOverlapping 
    clf;
    subplot(2,2,1);
    plot(In.time(In.CycleStart(WhichCycle-1):In.CycleEnd(WhichCycle-1)),In.smoothedRespiration(In.CycleStart(WhichCycle-1):In.CycleEnd(WhichCycle-1)));
    hold on ;
    scatter(In.time(In.inhalePeaks(WhichCycle-1)),In.smoothedRespiration(In.inhalePeaks(WhichCycle-1)),'r')
    scatter(In.time(In.exhaleTroughs(WhichCycle-1)),In.smoothedRespiration(In.exhaleTroughs(WhichCycle-1)),'b')
    if ~isnan(In.inhalePauseOnsets(WhichCycle-1))
    PlotIntervals( [In.time(In.inhalePauseOnsets(WhichCycle-1))]+[0,In.inhalePauseDurations(WhichCycle-1)])
    end
    if ~isnan(In.exhalePauseOnsets(WhichCycle-1))
    PlotIntervals( [In.time(In.exhalePauseOnsets(WhichCycle-1))]+[0,In.exhalePauseDurations(WhichCycle-1)])
    end
    
    subplot(2,2,3);
    plot(In.time(In.CycleStart(WhichCycle):In.CycleEnd(WhichCycle)),In.smoothedRespiration(In.CycleStart(WhichCycle):In.CycleEnd(WhichCycle)));
    PlotIntervals( [In.time([In.inhaleOnsets(WhichCycle)])  In.time(In.inhaleOffsets(WhichCycle) )],'Color','r')
    hold on ;
    scatter(In.time(In.inhalePeaks(WhichCycle)),In.smoothedRespiration(In.inhalePeaks(WhichCycle)))
    scatter(In.time(In.exhaleTroughs(WhichCycle)),In.smoothedRespiration(In.exhaleTroughs(WhichCycle)))
    if ~isnan(In.inhalePauseOnsets(WhichCycle))
    PlotIntervals( [In.time(In.inhalePauseOnsets(WhichCycle))]+[0,In.inhalePauseDurations(WhichCycle)])
    end
    subplot(2,2,2);
    plot(bmObj.time(bmObj.CycleStart(WhichCycle-1):bmObj.CycleEnd(WhichCycle-1)),bmObj.smoothedRespiration(bmObj.CycleStart(WhichCycle-1):bmObj.CycleEnd(WhichCycle-1)));
    hold on ;
    scatter(bmObj.time(bmObj.inhalePeaks(WhichCycle-1)),bmObj.smoothedRespiration(bmObj.inhalePeaks(WhichCycle-1)),'r')
    scatter(bmObj.time(bmObj.exhaleTroughs(WhichCycle-1)),bmObj.smoothedRespiration(bmObj.exhaleTroughs(WhichCycle-1)),'b')
    if ~isnan(bmObj.inhalePauseOnsets(WhichCycle-1))
    PlotIntervals( [bmObj.time(bmObj.inhalePauseOnsets(WhichCycle-1))]+[0,bmObj.inhalePauseDurations(WhichCycle-1)])
    end
    if ~isnan(bmObj.exhalePauseOnsets(WhichCycle-1))
    PlotIntervals( [bmObj.time(bmObj.exhalePauseOnsets(WhichCycle-1))]+[0,bmObj.exhalePauseDurations(WhichCycle-1)])
    end
    
    subplot(2,2,4);
    plot(bmObj.time(bmObj.CycleStart(WhichCycle):bmObj.CycleEnd(WhichCycle)),bmObj.smoothedRespiration(bmObj.CycleStart(WhichCycle):bmObj.CycleEnd(WhichCycle)));
    PlotIntervals( [bmObj.time([bmObj.inhaleOnsets(WhichCycle)])  bmObj.time(bmObj.inhaleOffsets(WhichCycle) )],'Color','r')
    hold on ;
    scatter(bmObj.time(bmObj.inhalePeaks(WhichCycle)),bmObj.smoothedRespiration(bmObj.inhalePeaks(WhichCycle)))
    scatter(bmObj.time(bmObj.exhaleTroughs(WhichCycle)),bmObj.smoothedRespiration(bmObj.exhaleTroughs(WhichCycle)))
    if ~isnan(bmObj.inhalePauseOnsets(WhichCycle))
    PlotIntervals( [bmObj.time(bmObj.inhalePauseOnsets(WhichCycle))]+[0,bmObj.inhalePauseDurations(WhichCycle)])
    end
    linkaxes([subplot(2,2,1),subplot(2,2,2),subplot(2,2,3),subplot(2,2,4)])
   end
   clear iCycle NewOnset
    end
    
CycleFields = fields(bmObj) ;
CycleFields(ismember(CycleFields,{'dataType','srate','time','rawRespiration','smoothedRespiration','baselineCorrectedRespiration'})) =[];
for iFeature = 1 :numel(CycleFields)
eval(['bmObj.' CycleFields{iFeature} '(CyclesToRemove) = [];' ])
end
clear iFeature CycleFields CyclesToRemove
end



%% 2) Check that cycles within good intervals are joined together. If not - link them;
N_Cycles = numel(bmObj.CycleStart);
if any([ bmObj.CycleStart(2:N_Cycles) ~= bmObj.CycleEnd(1:N_Cycles-1)+1])
     %bmObj = StitchUnlabeledEndsOfSnifflets(bmObj ,DetectedGoodSniffInt , false ) ; 
     bmObj = StitchUnlabeledEndsOfSnifflets(bmObj ,OriginalBmWindow , false ) ; 
end  
%% 3) Finally remove cycles which are simply impossibly too long;

CyclesToRemove = find(diff(bmObj.time(RemoveNansFromHorizontalRows([ bmObj.CycleStart ,  bmObj.CycleEnd ])),[],2) > ImpossibleLength  ) ;
if ~isempty(CyclesToRemove)
    MinDistanceBetweenInts =30;
    TsToRemove = logical(zeros(size( LowFrequencySampling.Ts ,1) ,1 ));
    TsIntsToRemove = [ bmObj.time(bmObj.CycleStart(CyclesToRemove ))    , [  bmObj.time(bmObj.CycleEnd(CyclesToRemove ))   ] ] ;
    TsIntsToRemove = [floor(TsIntsToRemove(:,1)),ceil(TsIntsToRemove(:,2))] ;
    if size(TsIntsToRemove,1)>1
        ExpandendTsIntsToRemove = ...
        [TsIntsToRemove + [-1,1 ]*MinDistanceBetweenInts    ] ; %% ; TsIntsToRemove(1:end-1,2)  ,  TsIntsToRemove(2:end,1) 
        ExpandendTsIntsToRemove = ConsolidateIntervals(ExpandendTsIntsToRemove) ;
    
        ExpandendTsIntsToRemove(... 
        ismember(ExpandendTsIntsToRemove(:,1) , TsIntsToRemove(:,1)+[-1]*MinDistanceBetweenInts ),1) = ...
        ExpandendTsIntsToRemove(... 
        ismember(ExpandendTsIntsToRemove(:,1) , TsIntsToRemove(:,1)+[-1]*MinDistanceBetweenInts ),1) + [1]*MinDistanceBetweenInts  ; 
    
        ExpandendTsIntsToRemove(... 
        ismember(ExpandendTsIntsToRemove(:,2) , TsIntsToRemove(:,2) + [+1]*MinDistanceBetweenInts ),2) = ...
        ExpandendTsIntsToRemove(... 
        ismember(ExpandendTsIntsToRemove(:,2) , TsIntsToRemove(:,2) + [+1]*MinDistanceBetweenInts ),2) + [-1]*MinDistanceBetweenInts   ;
        TsIntsToRemove = ExpandendTsIntsToRemove;
        clear ExpandendTsIntsToRemove;
    end   
    
    
    if size(TsIntsToRemove,1)>1
        TsIntsToRemove = ConsolidateIntervals(TsIntsToRemove);    
    end
    CyclesToRemove = InIntervals(  bmObj.time([bmObj.CycleStart]) ,     [  TsIntsToRemove]) |  InIntervals(  bmObj.time([bmObj.CycleEnd]) ,     [  TsIntsToRemove])   ;
    TsToRemove = InIntervals(    bmObj.time , [ TsIntsToRemove]) ;
    %LowFrequencySampling.ValidData(TsToRemove) = 0;
    %LowFrequencySampling.ValidIndices = find(LowFrequencySampling.ValidData==1 ) ;
    N_Cycles = numel(bmObj.inhaleOnsets);
    bmFields = fields(bmObj);
    TsFields= {'inhalePeaks'  'exhaleTroughs'   'inhaleOnsets' , 'exhaleOnsets'  , 'inhaleOffsets' , 'exhaleOffsets'  , 'inhalePauseOnsets' , 'exhalePauseOnsets' 'CycleStart' , 'CycleEnd'  } ;
    for iField =1 : numel(TsFields) 
        eval(['bmObj.' TsFields{iField } 'Ts = NaN(size( bmObj.'  TsFields{iField } ',1 ),1) ;' ]) 
        eval(['bmObj.' TsFields{iField } 'Ts(~isnan( bmObj.' TsFields{iField } ')) = bmObj.time( bmObj.' TsFields{iField } '(~isnan( bmObj.' TsFields{iField } ')));' ]);
        clear iField;
    end
    
    
    
    %% Remove cycles now;
    %bmObj.time(TsToRemove) = [];
    %bmObj.rawRespiration(TsToRemove) = [];
    %bmObj.smoothedRespiration(TsToRemove) = [];
    %bmObj.baselineCorrectedRespiration(TsToRemove) = [];
    PostProcessesSniffIntToUse = SubtractIntervals(SniffIntToUse,TsIntsToRemove)  ;
    PostProcessesGoodSniffInt = SubtractIntervals(DetectedGoodSniffInt,TsIntsToRemove)  ;

    for iField = 1 : numel(bmFields)
        if      eval(['isequal(N_Cycles,numel(bmObj.' bmFields{iField} '))' ]);
                eval(['bmObj.' bmFields{iField} '(CyclesToRemove) =[]; ' ] );
                if ismember([bmFields{iField} ],TsFields)
                    eval(['bmObj.' bmFields{iField} 'Ts(CyclesToRemove) = []; ' ]);
                    %eval(['bmObj.' bmFields{iField} '(~isnan(bmObj.' bmFields{iField} 'Ts) ) = knnsearch(bmObj.time,bmObj.' bmFields{iField} 'Ts(~isnan(bmObj.' bmFields{iField} 'Ts)))  ;' ]);
                end
            
        end
    end
    
    clear  bmFields N_Cycles TsIntsToRemove iField
    bmObj = RemoveFieldsFromStrucrue(bmObj,strcat(TsFields,'Ts'));
else
    PostProcessesSniffIntToUse  =SniffIntToUse;
    PostProcessesGoodSniffInt  =DetectedGoodSniffInt;  
end


end