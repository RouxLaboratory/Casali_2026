function bmObj = StitchUnlabeledEndsOfSnifflets(bmObj ,OriginalBmWindow , PLOT_SNIFFLET)
    N_Cycles = numel(bmObj.CycleStart);

    InhalePauseWindow = repmat(bmObj.time([bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))) ]),1,2)  + [zeros(sum(not(isnan(bmObj.inhalePauseOnsets))),1)  ,     bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ];
    ExhalePauseWindow = repmat(bmObj.time([bmObj.exhalePauseOnsets(not(isnan(bmObj.exhalePauseOnsets))) ]),1,2)  + [zeros(sum(not(isnan(bmObj.exhalePauseOnsets))),1)  ,     bmObj.exhalePauseDurations(not(isnan(bmObj.exhalePauseOnsets))) ];
    Derivative = [diff(reshape(bmObj.smoothedRespiration, [], 1));NaN] ;
    CyclesToJoin = find([bmObj.CycleStart(2:N_Cycles) ~= bmObj.CycleEnd(1:N_Cycles-1)+1]);
    CyclesToJoin = CyclesToJoin+1;
    CyclesToJoin = CyclesToJoin(InIntervals([bmObj.time( bmObj.CycleStart(    CyclesToJoin) )],OriginalBmWindow) & InIntervals([bmObj.time( bmObj.CycleEnd(    CyclesToJoin) )],OriginalBmWindow));
    disp([ 'Fraction of cycles joined = ' num2str(100*numel(CyclesToJoin) / N_Cycles ) ' % from breathmetrics...' ] )
    %TheseCycles = find(InIntervals(bmObj.time(bmObj.CycleStart)        , [statesint.wake(1,:) ] )) ; 
    %CyclesToJoin = Restrict(CyclesToJoin,[TheseCycles(1),TheseCycles(end)]);
    %CyclesToJoin = CyclesToJoin(end-11:end);
    CycleStatsWindow = 5;
    

for iCycle = 1 : numel(CyclesToJoin)
        ThisCycle = CyclesToJoin(iCycle) ;
        TheseStatWindows = ThisCycle-CycleStatsWindow:ThisCycle+CycleStatsWindow ;
        ThisWindow = reshape( [ bmObj.time( [bmObj.CycleStart(ThisCycle-CycleStatsWindow),bmObj.CycleEnd(ThisCycle+CycleStatsWindow) ] ) ] , [] , 2) ;
        ThisUnlabelled = [reshape( bmObj.time( [bmObj.CycleEnd(ThisCycle-1), bmObj.CycleStart(ThisCycle) ]) , [1] ,[] )] ;
        ThisDerivativeThreshold = nanmean(Derivative( RemoveNaNsFromVector([bmObj.inhalePauseOnsets(TheseStatWindows) ; bmObj.exhalePauseOnsets(TheseStatWindows)]))) ;
        ThisDerivativeThreshold = sort([-1,1 ] *ThisDerivativeThreshold);
        ExhaleOffSetThreshold = nanmean(bmObj.smoothedRespiration( bmObj.exhaleOffsets(TheseStatWindows(~ismember(TheseStatWindows,ThisCycle) ))));
        InhaleOnSetThreshold =  nanmean(bmObj.smoothedRespiration( bmObj.inhaleOnsets(TheseStatWindows(~ismember(TheseStatWindows,ThisCycle) ))));
        MeanThreshold = nanmean([ExhaleOffSetThreshold, InhaleOnSetThreshold]);
          
        if PLOT_SNIFFLET;
        figure(iCycle);clf;
        subplot(3,1,1);
        PlotXY( Restrict( [ bmObj.time,reshape(bmObj.smoothedRespiration, [], 1) ],ThisWindow),'k');
        ylim([-1,1]*4);hold on ;
        PlotIntervals( bmObj.time( [bmObj.inhaleOnsets(TheseStatWindows),bmObj.inhaleOffsets(TheseStatWindows) ]),'Color','r','alpha',0.2);
        PlotIntervals( bmObj.time( [bmObj.exhaleOnsets(TheseStatWindows),bmObj.exhaleOffsets(TheseStatWindows) ]),'Color','b','alpha',0.2);
        PlotIntervals(Restrict(InhalePauseWindow,ThisWindow),'Color','k','alpha',0.2);
        PlotIntervals(Restrict(ExhalePauseWindow,ThisWindow),'Color','k','alpha',0.2);
        PlotIntervals(  ThisUnlabelled,'Color','g','alpha',0.2);
        line(xlim,[MeanThreshold,MeanThreshold ],'Color','r')
        
        delete(subplot(3,1,2));  subplot(3,1,2);
        PlotXY( Restrict( [ bmObj.time, [Derivative] ],ThisWindow),'k');
        ylim([-1,1]*0.02);
        hold on ;
        PlotIntervals( bmObj.time( [bmObj.inhaleOnsets(TheseStatWindows),bmObj.inhaleOffsets(TheseStatWindows) ]),'Color','r','alpha',0.2);
        PlotIntervals( bmObj.time( [bmObj.exhaleOnsets(TheseStatWindows),bmObj.exhaleOffsets(TheseStatWindows) ]),'Color','b','alpha',0.2);
        PlotIntervals(Restrict(InhalePauseWindow,ThisWindow),'Color','k','alpha',0.2);
        PlotIntervals(Restrict(ExhalePauseWindow,ThisWindow),'Color','k','alpha',0.2);
        PlotIntervals(  ThisUnlabelled,'Color','g','alpha',0.2);
        line( [ThisWindow ] ,[ ThisDerivativeThreshold(1) , ThisDerivativeThreshold(1)] ,'Color','g')
        line( [ThisWindow ] ,[ ThisDerivativeThreshold(2) ,ThisDerivativeThreshold(2)] ,'Color','g')
        linkaxes([subplot(3,1,1),subplot(3,1,2)],'x')
        end;
        
        DerivativeBelowThreshold =  DetectMarginsFromArray( ...
                                        Derivative([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) > ThisDerivativeThreshold(1) & ...
                                        Derivative([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) < ThisDerivativeThreshold(2) , ...
                                        Derivative([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) > ThisDerivativeThreshold(1) & ...
                                        Derivative([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) < ThisDerivativeThreshold(2) );
                                    
        if isempty(DerivativeBelowThreshold ) 
           DerivativeBelowThreshold = [0,0];
        end
        DerivativeBelowThreshold=DerivativeBelowThreshold(1,:);
        
        AboveThresholds = DetectMarginsFromArray( bmObj.baselineCorrectedRespiration([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) > MeanThreshold  , ...
                                bmObj.baselineCorrectedRespiration([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) > MeanThreshold);
        if isempty(AboveThresholds ) 
           AboveThresholds = [0,0];
        end
        AboveThresholds = AboveThresholds(1,:);
        
        BelowThresholds =   DetectMarginsFromArray( bmObj.baselineCorrectedRespiration([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) < MeanThreshold  , ...
                                bmObj.baselineCorrectedRespiration([bmObj.CycleEnd(ThisCycle-1) : bmObj.CycleStart(ThisCycle) ]) < MeanThreshold);
        if isempty(BelowThresholds ) 
           BelowThresholds = [0,0];
        end       
        BelowThresholds = BelowThresholds(1,:);
        
        %% If the Signal in the unlabelled time-stamp is ALL below the mean average threshold better to anticipate the inhalation onset;
        if BelowThresholds(1) <= 2 && DerivativeBelowThreshold(1) ==1 |  BelowThresholds(1) <= 2 && ~sum(DerivativeBelowThreshold) 
                bmObj.CycleStart( ThisCycle)  = ...
                bmObj.CycleEnd(ThisCycle-1)+1 ;
                bmObj.inhaleOnsets( ThisCycle) = bmObj.CycleStart( ThisCycle) ; 
                bmObj.inhaleDurations( ThisCycle) = diff(bmObj.time([bmObj.inhaleOnsets(ThisCycle),bmObj.inhaleOffsets(ThisCycle) ] ));
                bmObj.inhaleTimeToPeak( ThisCycle) = diff(bmObj.time([bmObj.inhaleOnsets(ThisCycle),bmObj.inhalePeaks(ThisCycle) ] ));
        
        else
        %% if not add this delta time to exhalation pause, but check first that some of it does not belong to the tail of the exhalation;
                bmObj.exhaleOffsets(ThisCycle-1) = bmObj.exhaleOffsets(ThisCycle-1)+ AboveThresholds(2) ; 
                AddedPauses = [bmObj.exhaleOffsets(ThisCycle-1)+1 ,  bmObj.CycleStart(ThisCycle)-1 ];
                bmObj.CycleEnd(ThisCycle-1) = bmObj.CycleStart(ThisCycle)-1 ;
                bmObj.exhalePauseOnsets(ThisCycle-1) = AddedPauses(1);
                bmObj.exhalePauseDurations(ThisCycle-1) = diff(bmObj.time([bmObj.exhalePauseOnsets(ThisCycle-1) ,    bmObj.CycleEnd(ThisCycle-1) ])) ;
        end
        if PLOT_SNIFFLET;
        delete(subplot(3,1,3));  subplot(3,1,3);
        PlotXY( Restrict( [ bmObj.time,reshape(bmObj.smoothedRespiration, [], 1) ],ThisWindow),'k');
        ylim([-1,1]*4);hold on ;
        PlotIntervals( bmObj.time( [bmObj.inhaleOnsets(TheseStatWindows),bmObj.inhaleOffsets(TheseStatWindows) ]),'Color','r','alpha',0.2);
        PlotIntervals( bmObj.time( [bmObj.exhaleOnsets(TheseStatWindows),bmObj.exhaleOffsets(TheseStatWindows) ]),'Color','b','alpha',0.2);
        if ~isnan(bmObj.exhalePauseOnsets(ThisCycle-1) )
                        PlotIntervals( [repmat([ bmObj.time( [bmObj.exhalePauseOnsets(ThisCycle-1) ])],1,2) + ...
                        [0, bmObj.exhalePauseDurations(ThisCycle-1)] ] , 'Color','k','alpha',0.2)
        end ;
        linkaxes([subplot(3,1,1),subplot(3,1,2),subplot(3,1,3)],'x') ; 
        end
end

%% Now exclude cycles which should not be linked together as they are the last in each original BM chunk;
LastCycleByChunks = [];
for iChunk = 1 : size(OriginalBmWindow,1)
    LastCycleByChunks = [LastCycleByChunks;...
    ...find( InIntervals( bmObj.time(bmObj.CycleStart) , OriginalBmWindow(iChunk,:)),1,'first');...
    find( InIntervals( bmObj.time(bmObj.CycleStart) , OriginalBmWindow(iChunk,:)),1,'last') ];
end

    nCycles = numel(bmObj.inhalePeaks);
    bmObjFields = fields(bmObj);
   
    for iField = 1 : numel(bmObjFields) ;
        if  eval(['    isequal(nCycles,numel(bmObj.' bmObjFields{iField} '));']);
            eval(['bmObj.' bmObjFields{iField} '(LastCycleByChunks) =[]; ;']);
            disp([ bmObjFields{iField} ' last cycles removed'])
        end
    end


end