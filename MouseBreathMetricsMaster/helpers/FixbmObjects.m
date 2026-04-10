function bmObj = FixBMObjects( bmObj ,FixParametersForInhExh, VideoTitle)
        %% Function written by Giulo Casali (Roux Lab, IINS, Bordeaux) 
        % The point of this function is to consolidate the pause detection
        % occurring within and between sniff cycles detected by
        % breathmetrics toolbox;
        
        % The approach used here aims at fixing some "un-detected pauses
        % and/or errors in the onset/offset alignments". The majority of
        % the problems arise from the fact that the sniff signal is not
        % always stationary, and despite detrending was ran previusly
        % sometimes the drift persists. To account for that, small chunks
        % of data are run iteratively to "flat" the signal and maximize the
        % number of cycles possibly detected.




        if exist('VideoTitle','var') & not(VideoTitle)
            MakeVideo = true ;
        else
            MakeVideo = false;
        end
        ShowPlot = false ;
        simplify = false;
        verbose = false; 
        bmObj.inhalePauseDurations(isnan( bmObj.inhalePauseDurations)) = 0;
        bmObj.exhalePauseDurations(isnan( bmObj.exhalePauseDurations)) = 0;
        DetectLocalPeaks = false;
        ReRunBm = true;
        N_Cycles = numel(bmObj.inhaleDurations);
        MaxNIterations= 20;
        MaxSecondsSpanOfMovingAverageWindow = 3;
        LogIterations = logspace(1,MaxSecondsSpanOfMovingAverageWindow,MaxNIterations) ;
        MousePath = char(bz_BasenameFromBasepath(cd) );
        MinimumDistanceBetweenConsecutivePeaksThrough = 0.020; %% in seconds; == 5 ms;
        MinimumNumberOfCycles = 10;
        if N_Cycles < MinimumNumberOfCycles
            bmObj.CycleStart = [ ] ; 
            bmObj.CycleEnd = [ ] ; 
            bmObj = RemoveFieldsFromStrucrue(bmObj,{'indices'});
            return
        end
        CycleToFix = true ;
        MasterBM = [ ] ;
        CycleToRemove = [];
          if FixParametersForInhExh;
            bmObj.baselineCorrectedRespiration = bmObj.smoothedRespiration;
          end
          
            inhalePauseStats.BaselineCorrected.FifthPercentile = prctile(  bmObj.baselineCorrectedRespiration(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])),...
            5) ;
            inhalePauseStats.BaselineCorrected.NinetyFifthPercentile = prctile(  bmObj.baselineCorrectedRespiration(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])),...
            95) ;
        
            inhalePauseStats.RawSignal.FifthPercentile = prctile(  bmObj.rawRespiration(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])),...
            5) ;
            inhalePauseStats.RawSignal.NinetyFifthPercentile = prctile(  bmObj.rawRespiration(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])),...
            95) ;
        
        
        
        if FixParametersForInhExh;
            [inhalePauseStats.BaselineCorrected.FifthPercentile , inhalePauseStats.BaselineCorrected.NinetyFifthPercentile ] = deal(nanmean(abs([inhalePauseStats.BaselineCorrected.FifthPercentile  inhalePauseStats.BaselineCorrected.NinetyFifthPercentile]))) ;
            inhalePauseStats.BaselineCorrected.FifthPercentile = -inhalePauseStats.BaselineCorrected.FifthPercentile;
        end;
        
        %   inhalePauseStats.BaselineCorrected.FifthPercentile = [-0.4 ];
        %   inhalePauseStats.BaselineCorrected.NinetyFifthPercentile = [+0.4 ];
%         PauseThreshold= min(abs([inhalePauseStats.BaselineCorrected.FifthPercentile,inhalePauseStats.BaselineCorrected.NinetyFifthPercentile ]));
%         inhalePauseStats.BaselineCorrected.FifthPercentile = -PauseThreshold;
%         inhalePauseStats.BaselineCorrected.NinetyFifthPercentile = +PauseThreshold;
        
        
        FirstDerivative = [diff(bmObj.baselineCorrectedRespiration);NaN];
        SecondDerivative = [diff(FirstDerivative);NaN];
%         
%         DerivativeBand = nanmean(FirstDerivative(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + ...
%                 [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ]))) +...
%                 [-1,1 ] *3*StError(FirstDerivative(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + ...
%                 [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])));
                %DerivativeBand = min(abs(DerivativeBand))*[-1,1];
        
        if FixParametersForInhExh;
            DerivativeBand = [-1,1 ] * 0.0010;
        else
            DerivativeBand = [-1,1 ] * 0.005;
        end
%         SecondDerivativeBand = prctile(SecondDerivative(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + ...
%                 [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])),[10,90]);
%         SecondDerivativeBand = min(abs(SecondDerivativeBand))*[-1,1];
        
      SecondDerivativeBand = nanmean(SecondDerivative(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + ...
                [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ]))) +...
                [-1,1 ] *3*StError(SecondDerivative(InIntervals(bmObj.time,[bmObj.time(bmObj.inhalePauseOnsets(not(isnan(bmObj.inhalePauseOnsets))))] + ...
                [zeros(size(bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))),1),1 ) bmObj.inhalePauseDurations(not(isnan(bmObj.inhalePauseOnsets))) ])));
      SecondDerivativeBand = min(abs(SecondDerivativeBand))*[-1,1];
     



        N_BoundingCycles = 10;
        N_OverhangingCycles = 2;
        
        CyclesToCheck = repmat([reshape([ 1 :  N_BoundingCycles : N_Cycles] ,[],1) ],1,2) ;
        CyclesToCheck(:,2) = CyclesToCheck(:,2) + N_BoundingCycles + N_OverhangingCycles ;
        CyclesToCheck(CyclesToCheck> N_Cycles) = N_Cycles;
        %CyclesToCheck(diff(CyclesToCheck , [],2)==0,:)= [];
        if size(CyclesToCheck,1)>=2
            CyclesToCheck(end,:) = [CyclesToCheck(end-1,1), CyclesToCheck(end,2)] ;
            CyclesToCheck(end-1,:) = [] ; 
        end
        WB = waitbar(0, ['Fixing BmObj from' MousePath ': total ' num2str(size(CyclesToCheck,1))  ' cycles ...']) ;
        for i = 1  : size(CyclesToCheck ,1 )
            %% 1)  Check that inhalation windows too long because there are undetected inhalation cycles;
                    waitbar(i/size(CyclesToCheck,1 ), WB);
                    Iterations =  1;
                    CycleRange = [ CyclesToCheck( i , : )] ;
                    cycles_indices = reshape([ bmObj.inhaleOnsets(CycleRange(1)) : bmObj.exhaleOffsets(CycleRange(2)) + (bmObj.exhalePauseDurations(CycleRange(2))/bmObj.srate) ] , [] ,1 ) ;
                        if i == size(CyclesToCheck ,1 )
                                indices_to_use = InIntervals(  cycles_indices  ,   [ bmObj.inhaleOnsets(CycleRange(1)) , bmObj.exhaleOffsets(CycleRange(2)) + (bmObj.exhalePauseDurations(CycleRange(2))/bmObj.srate) ] ) ;
                        else
                                indices_to_use = InIntervals(  cycles_indices  ,   [ bmObj.inhaleOnsets(CycleRange(1)) , bmObj.exhaleOffsets(CycleRange(2)-N_OverhangingCycles) + (bmObj.exhalePauseDurations(CycleRange(2)-N_OverhangingCycles)/bmObj.srate) ] ) ;
                        end;
                        t = [ bmObj.time(cycles_indices)] ;
                        signal = [  bmObj.baselineCorrectedRespiration(cycles_indices)] ;
                        raw_signal = [  bmObj.rawRespiration(cycles_indices)] ;
                        
                        %while CycleToFix %& Iterations
                            
                            clear bm;
                            MaxNPeaks = [];
                            for Iteration = [LogIterations ]
                                method = 'simple';
                                if isequal(Iteration,1)
                                    average_trace = zeros(size(signal));
                                else
                                    %average_trace = [movmean(signal, [bmObj.srate] * 1*[ MaxIterations/Iterations] )];
                                    average_trace = movmean(signal, bmObj.srate*log10(Iteration) ) ;
                                end
                                signal_to_use = signal - average_trace ;;
                                bm = breathmetrics(signal_to_use,bmObj.srate,'rodentAirflow') ;
                                bm.baselineCorrectedRespiration = reshape(signal_to_use , 1 , []) ;
                                bm.findExtrema(true, verbose);
                                MaxNPeaks = [MaxNPeaks; numel(bm.inhalePeaks)];
                                clear Iteration average_trace signal_to_use bm
                            end
                            [ ~, Iteration ] = max(MaxNPeaks)  ;
                            if ~isequal(Iteration,1)
                                average_trace = movmean(signal, bmObj.srate*log10(LogIterations(Iteration)) ) ;
                            else
                                    average_trace = zeros(size(signal));
                            end
                            signal_to_use = signal - average_trace ;;
                            % if ShowPlot
                            % clf ; hold on ;
                            % plot(t, signal,'k');
                            % plot(t, average_trace,'r');
                            %yyaxis right
                            % plot(t, signal_to_use,'g');
                            % end
                            if DetectLocalPeaks
                                [~,t_peaks] = findpeaks(signal_to_use(indices_to_use), 'MinPeakHeight', prctile(bmObj.peakInspiratoryFlows,10),'MinPeakDistance',[  0.05*bmObj.srate ] );
                                n_putative_peaks = numel(t_peaks);
                                [~,t_through] = findpeaks(invert(signal_to_use(indices_to_use)), 'MinPeakHeight', prctile(-1*bmObj.troughExpiratoryFlows,10),'MinPeakDistance',[  0.05*bmObj.srate ] ) ;
                                n_putative_through = numel(t_through);
                                UseBreathMetrics = ...
                                    not(isequal(n_putative_peaks,n_putative_through))   | ...
                                numel(Restrict(bmObj.inhalePeaks , [ FindExtremesOfArray([cycles_indices(indices_to_use)])    ])) , 

                                not(isequal( bmObj.inhalePeaks(iCycle) , cycles_indices(t_peaks) )) | ... ...
                                    not(isequal(bmObj.exhaleTroughs(iCycle) , cycles_indices(t_through) )) ;
                            else
                                UseBreathMetrics = true;
                            end

                if ReRunBm
                    bm = breathmetrics(signal_to_use,bmObj.srate,'rodentAirflow') ;
                    bm.baselineCorrectedRespiration = reshape(signal_to_use , 1 , []) ;
                    
                    try
                        bm.findExtrema(true, verbose);
                        bm.findOnsetsAndPauses(verbose);
                        bm.findInhaleAndExhaleOffsets(verbose);
                        bm.findBreathAndPauseDurations();
                        bm.findInhaleAndExhaleVolumes(verbose);
                    catch
                        
                        disp('local breathmetrics could not run, keep smoothing...');
                        KeepSmoothing=true;
                        k=5;
%                             bm.smoothedRespiration =... = breathmetrics(signal_to_use,bmObj.srate,'rodentAirflow') ;
%                             fftSmooth(bm.rawRespiration, floor((bm.srate/1000) * 10));
                        while KeepSmoothing 
                            try 
                                k=k+2;
                                if k>125
                                    try;
                                        KeepDetrending =true;   
                                        k= bm.srate*0.500;
                                        while KeepDetrending;
                                            k = k+ bm.srate*0.01;
                                            DeTrended= signal_to_use;%    detrend(signal_to_use);
                                            respSlidingMean=fftSmooth(DeTrended, k ) ;
                                            %hold on ;
                                            %plot(DeTrended,'b');
                                            %plot(respSlidingMean,'g') ;
                                            %subplot(2,1,2);
                                            BaseCorrected = DeTrended-respSlidingMean;
                                            %plot(BaseCorrected);
                                            %hold on;
                                            %line(xlim(),[0,0],'Color','r');ylim([-1,1]*1)
                                            bm.smoothedRespiration=BaseCorrected;
                                            bm.baselineCorrectedRespiration = reshape(bm.smoothedRespiration , 1 , []) ;                                   
                                            bm.findExtrema(true, verbose);
                                            bm.findOnsetsAndPauses(verbose);
                                            bm.findInhaleAndExhaleOffsets(verbose);
                                            bm.findBreathAndPauseDurations();
                                            bm.findInhaleAndExhaleVolumes(verbose);  
                                            KeepDetrending = false;
                                            KeepSmoothing = false;
                                            clear DeTrended  respSlidingMean BaseCorrected;
                                        end
                                    end
                                
                                else
                                    bm.smoothedRespiration=(sgolayfilt(signal_to_use,[ 2 ] , [ k] )) ;
                                    bm.baselineCorrectedRespiration = reshape(bm.smoothedRespiration , 1 , []) ;
                                    bm.findExtrema(true, verbose);
                                    bm.findOnsetsAndPauses(verbose);
                                    bm.findInhaleAndExhaleOffsets(verbose);
                                    bm.findBreathAndPauseDurations();
                                    bm.findInhaleAndExhaleVolumes(verbose);
                                    KeepSmoothing = false;
                                end
                            end
                        end
                    end    
                        

                        if ~isnan(bm.inhaleOnsets(end)) &  ~isnan(bm.inhaleOffsets(end)) &  ~isnan(bm.exhaleOnsets(end)) &  isnan(bm.exhaleOffsets(end))
                            threshold = nanmean( bm.baselineCorrectedRespiration(bm.exhaleOnsets(bm.exhaleOnsets<=numel(bm.baselineCorrectedRespiration))));
                            offset = find(bm.baselineCorrectedRespiration( bm.exhaleTroughs(end):end)>threshold ,1) ;
                            if isempty(offset);
                                bm.exhaleOffsets(end) = numel(bm.baselineCorrectedRespiration);
                            else
                                bm.exhaleOffsets(end) = bm.exhaleTroughs(end) +offset;
                                if bm.exhaleOffsets(end) > numel(bm.time)
                                    bm.exhaleOffsets(end) = numel(bm.time);
                                end
                            end
                        end;

                        if  sum(ismember(bm.exhaleOnsets , bm.exhaleOffsets)) | sum(bm.exhaleOffsets-bm.exhaleTroughs<0)
                            PeaksToFix = sort(unique([find(ismember(bm.exhaleOnsets , bm.exhaleOffsets)) , find(([bm.exhaleOffsets-bm.exhaleTroughs]<0))]));
                            for iPeak = 1 : numel(PeaksToFix)
                                threshold = nanmean( bm.baselineCorrectedRespiration(bm.inhaleOffsets));
                                offset = find(bm.baselineCorrectedRespiration( bm.exhaleTroughs(PeaksToFix(iPeak)):end)>threshold ,1) ;
                                if isempty(offset);offset = 0;; end;                                  
                                bm.exhaleOffsets(PeaksToFix(iPeak)) = bm.exhaleTroughs(PeaksToFix(iPeak)) +offset;
                            end
                        end
%                             bm.findBreathAndPauseDurations();
%                             bm.findInhaleAndExhaleVolumes(verbose);
%                         try;
%                             bm.findInhaleAndExhaleVolumes(verbose);
%                         catch
%                             bm.inhaleOnsets(bm.inhaleOnsets>numel(bm.baselineCorrectedRespiration))
%                             bm.inhaleOffsets(bm.inhaleOffsets>numel(bm.baselineCorrectedRespiration))
%                             bm.exhaleOnsets(bm.inhaleOffsets>numel(bm.baselineCorrectedRespiration))
%                         end
%                    
                    
                    
                    nCycles = numel( bm.exhaleTroughs ) ;
                    nData = numel(t);
                    if nCycles >1
                        RemoveLastCycle  = sum(isnan(bm.inhaleOnsets(end))) | sum(isnan(bm.inhaleOffsets(end))) |sum(isnan(bm.exhaleOnsets(end))) | sum(isnan(bm.exhaleOffsets(end)));
                    else
                        RemoveLastCycle = 0;
                    end
                    eval(['bmFields =fields(bm);' ]);
                    bmFields(ismember(bmFields,{'dataType','srate'})) = [];
                    NewBm = [];
                    for   iField = 1 : numel(bmFields);
                        if eval(['isequal( nData, numel(bm.' bmFields{iField} ') ) ' ]);
                            eval([ 'NewBm.' bmFields{iField}  '='  'reshape(bm.' bmFields{iField} ',[],1);; ' ]);;
                        end
                        if eval(['isequal( nCycles, numel(bm.' bmFields{iField} ') ) ' ]);
                            eval([ 'NewBm.' bmFields{iField}  '='  'reshape(bm.' bmFields{iField} ',[],1);; ' ]);;
                            if RemoveLastCycle;
                                eval([ 'NewBm.' bmFields{iField}  '='  'reshape(bm.' bmFields{iField} '(1:nCycles-1),[],1); ' ]);
                            end
                        end
                        clear iField;
                    end;
                    clear bmFields;

                    %% Turn into ts ;
                    NewBm.time = reshape(t,[],1);
                    NewBm.inhalePauseDurations(isnan(NewBm.inhalePauseOnsets))=0;
                    NewBm.exhalePauseDurations(isnan(NewBm.exhalePauseOnsets))=0;
                    KeepThisCycles = InIntervals( [NewBm.time(NewBm.inhalePeaks) ] ,[min(t(indices_to_use)),max(t(indices_to_use))]);
                    NewBm.inhalePeaks =  NewBm.inhalePeaks(KeepThisCycles);
                    NewBm.exhaleTroughs = NewBm.exhaleTroughs(KeepThisCycles);  ;
                    NewBm.peakInspiratoryFlows =  NewBm.peakInspiratoryFlows(KeepThisCycles); ;
                    NewBm.troughExpiratoryFlows = NewBm.troughExpiratoryFlows(KeepThisCycles);  ;
                    NewBm.inhaleOnsets = NewBm.inhaleOnsets(KeepThisCycles);  ;
                    NewBm.exhaleOnsets = NewBm.exhaleOnsets(KeepThisCycles); ;
                    NewBm.inhaleOffsets =  NewBm.inhaleOffsets(KeepThisCycles);  ;
                    NewBm.exhaleOffsets = NewBm.exhaleOffsets(KeepThisCycles);  ;
                    NewBm.inhaleTimeToPeak = NewBm.inhaleTimeToPeak(KeepThisCycles); ;
                    NewBm.exhaleTimeToTrough = NewBm.exhaleTimeToTrough(KeepThisCycles); ;
                    NewBm.inhaleVolumes = NewBm.inhaleVolumes(KeepThisCycles); ;
                    NewBm.exhaleVolumes = NewBm.exhaleVolumes(KeepThisCycles); ;
                    NewBm.inhaleDurations = NewBm.inhaleDurations(KeepThisCycles);  ;
                    NewBm.exhaleDurations = NewBm.exhaleDurations(KeepThisCycles); ;
                    NewBm.inhalePauseOnsets = NewBm.inhalePauseOnsets(KeepThisCycles);  ;
                    NewBm.exhalePauseOnsets = NewBm.exhalePauseOnsets(KeepThisCycles); ;
                    NewBm.inhalePauseDurations = NewBm.inhalePauseDurations(KeepThisCycles);  ;
                    NewBm.exhalePauseDurations =  NewBm.exhalePauseDurations(KeepThisCycles);  ;
                    NewBm.inhalePauseDurations(isnan(NewBm.inhalePauseOnsets )) = 0;
                    NewBm.exhalePauseDurations(isnan(NewBm.exhalePauseOnsets )) = 0;
                   
                end;
                
                    CycleGained = false;
                    CycleLost = false;
                    IntersectCycles = false;
                    if numel( [ t(NewBm.inhalePeaks) ] ) >  numel( [ Restrict( bmObj.time((bmObj.inhalePeaks)) , [ FindExtremesOfArray(t(indices_to_use)) ] ) ] )
                        CycleGained = true ; IntersectCycles = true ;
                    elseif  numel( [ t(NewBm.inhalePeaks) ] ) <  numel( [ Restrict( bmObj.time((bmObj.inhalePeaks)) , [ FindExtremesOfArray(t(indices_to_use)) ] ) ] )
                        CycleLost = true;IntersectCycles = true ;                    
                    end
                
                    IntersectCycles = any([IntersectCycles , any(NewBm.inhaleDurations<0)  any(NewBm.exhaleDurations<0)]) ;
                    
                    if  IntersectCycles
                        if CycleLost
                            PeaksCyclesToRescue = find(not(ismember(  [ Restrict( bmObj.time(bmObj.inhalePeaks ) , [ FindExtremesOfArray( t(indices_to_use) ) ] ) ]  , [ t(NewBm.inhalePeaks) ]))) ;
                            ThroughCyclesToRescue = find(not(ismember(  [ Restrict( bmObj.time(bmObj.exhaleTroughs ) , [ FindExtremesOfArray( t(indices_to_use) ) ] ) ]  , [ t(NewBm.exhaleTroughs) ]))) ;
                            %ThroughCyclesToRescue = PeaksCyclesToRescue-1;
                            if isempty(ThroughCyclesToRescue)
                                ThroughCyclesToRescue = PeaksCyclesToRescue;
                            end
                            if numel(PeaksCyclesToRescue) <  numel(ThroughCyclesToRescue) ;
                                    ThroughCyclesToRescue(end-numel(PeaksCyclesToRescue)+1)  = [] ;
                            elseif  numel(PeaksCyclesToRescue) >  numel(ThroughCyclesToRescue) 
                                    ThroughCyclesToRescue(end :numel(PeaksCyclesToRescue)  )    = PeaksCyclesToRescue(numel(ThroughCyclesToRescue):numel(PeaksCyclesToRescue) )      ;                
                            end;
                            
                             
                                bm.time = t;
                            [   bm.inhalePeaks , bm.exhaleTroughs , bm.peakInspiratoryFlows, bm.troughExpiratoryFlows, ...
                                bm.inhaleOnsets , bm.exhaleOnsets , bm.inhaleOffsets , bm.exhaleOffsets  , bm.inhaleTimeToPeak , ...
                                bm.exhaleTimeToTrough , bm.inhaleVolumes , bm.exhaleVolumes , bm.inhaleDurations , bm.exhaleDurations , ...
                                bm.inhalePauseOnsets , bm.exhalePauseOnsets , bm.inhalePauseDurations, bm.exhalePauseDurations ] = deal([]);
                            
                            bm.inhalePeaks = knnsearch(t,unique(sort([Restrict( bmObj.time(bmObj.inhalePeaks ) , [ FindExtremesOfArray( t(indices_to_use) ) ])      ;       Restrict( t(NewBm.inhalePeaks) ,    [ FindExtremesOfArray( t(indices_to_use) ) ]) ]))) ;
                            bm.exhaleTroughs = knnsearch(t,unique(sort([Restrict( bmObj.time(bmObj.exhaleTroughs ) , [ FindExtremesOfArray( t(indices_to_use) ) ])  ;       Restrict( t(NewBm.exhaleTroughs) ,  [ FindExtremesOfArray( t(indices_to_use) ) ]) ]))) ;
                            %% Check that there are not multiple indices for the same peak or through;
                            bm.inhalePeaks = sort(bm.inhalePeaks) ; 
                            bm.exhaleTroughs = sort(bm.exhaleTroughs) ; 
                            bm.inhalePeaks([diff(bm.inhalePeaks)<= 100 ;false]) = [];
                            bm.exhaleTroughs([diff(bm.exhaleTroughs)<= 100 ;false]) = [];
                            alternation = [bm.inhalePeaks ones(size(bm.inhalePeaks,1),1) ; bm.exhaleTroughs , 2*ones(size(bm.exhaleTroughs,1),1)];
                            alternation = sortrows(alternation,1) ;
                            alternation(diff(alternation(:,2))==0,:)=[];
                            alternation = alternation(find(alternation(:,2)==1,1):end,:);
                            n_cycles = min(accumarray( alternation(:,2), 1 , [] ,@sum)  );
                            alternation(n_cycles*2+1:end,:) = [];
                            bm.inhalePeaks = alternation(1:2:2*n_cycles,1) ; 
                            bm.exhaleTroughs =  alternation(2:2:2*n_cycles,1) ;
                            try;
                                bm.findOnsetsAndPauses(verbose);
                            catch
                                try
                                    KeepSmoothing = true;
                                    k=3;
                                    while KeepSmoothing
                                        k = k+2;
                                        bm.baselineCorrectedRespiration = sgolayfilt(bm.baselineCorrectedRespiration,[ 2 ] , [ k] ) ;
                                        try;
                                            bm.findOnsetsAndPauses(verbose);
                                            KeepSmoothing=false;
                                        catch
                                            KeepSmoothing = true;
                                        end
                                    end
                                end
                            end
                            
                            bm.findInhaleAndExhaleOffsets(verbose);
                            bm.findBreathAndPauseDurations();
                            bm.findInhaleAndExhaleVolumes(verbose) ;
                        
                            NewBm.inhalePeaks  = reshape(bm.inhalePeaks , [] , 1 ) ;
                            NewBm.exhaleTroughs  = reshape(bm.exhaleTroughs , [] , 1 ) ;
                            NewBm.inhaleOnsets  = reshape(bm.inhaleOnsets , [] , 1 ) ;
                            NewBm.exhaleOnsets  = reshape(bm.exhaleOnsets , [] , 1 ) ;
                            NewBm.inhaleOffsets  = reshape(bm.inhaleOffsets , [] , 1 ) ;
                            NewBm.exhaleOffsets  = reshape(bm.exhaleOffsets , [] , 1 ) ;
                            NewBm.inhalePauseOnsets  = reshape(bm.inhalePauseOnsets , [] , 1 ) ;
                            NewBm.exhalePauseOnsets  = reshape(bm.exhalePauseOnsets , [] , 1 ) ;
                            NewBm.inhalePauseDurations  = reshape(bm.inhalePauseDurations , [] , 1 ) ;
                            NewBm.exhalePauseDurations  = reshape(bm.exhalePauseDurations , [] , 1 ) ;
                            NewBm.inhalePauseDurations((isnan(NewBm.inhalePauseOnsets))) = 0 ;
                            NewBm.exhalePauseDurations((isnan(NewBm.exhalePauseOnsets))) = 0 ;
                            [NewBm.inhaleDurations,NewBm.exhaleDurations,  NewBm.peakInspiratoryFlows , NewBm.troughExpiratoryFlows ,  NewBm.inhaleTimeToPeak   ,  NewBm.exhaleTimeToTrough  , NewBm.inhaleVolumes , NewBm.exhaleVolumes, ] = deal( [] ) ;
                            end
                    end 
                      
                        NewBm.CycleStart =  NewBm.inhaleOnsets ;
                        NewBm.CycleEnd = [ NewBm.CycleStart(2:end)-1 ;  find( indices_to_use,1,'last')] ;
                        %MakeVideo= false;    
                        NewBm.rawRespiration = raw_signal;
                            try
                                %if i==148;
                                     % MakeVideo= true;
                                    %else
                                     %MakeVideo= false;;
                                     %end
                                NewBm = FindPausesFromBmChunk_FromMaxima(NewBm,indices_to_use,inhalePauseStats,DerivativeBand,SecondDerivativeBand ,  i , MakeVideo  )   ;
                            catch
                                disp(['impossible Fto Find Pauses from BmChunk' num2str(i)]);
                                FindPausesFromBmChunk_FromMaxima(NewBm,indices_to_use,inhalePauseStats,DerivativeBand, SecondDerivativeBand, i , 1  )   ;
                                %NewBm = FindPausesFromBmChunk(NewBm,indices_to_use,inhalePauseStats.BaselineCorrected,DerivativeBand,  i , MakeVideo  )   ;
                            end
                             %disp([i, transpose(NewBm.time([1,end]))]); % if MakeVideo; VideoFrame(i) = getframe(gcf); end
                            
                    NewBm.inhalePeaksTs   =     NewBm.time(NewBm.inhalePeaks) ;
                    NewBm.exhaleTroughsTs =     NewBm.time(NewBm.exhaleTroughs);
                    NewBm.inhaleOnsetsTs  =     NewBm.time(NewBm.inhaleOnsets) ;
                    NewBm.exhaleOnsetsTs  =     NewBm.time(NewBm.exhaleOnsets);
                    NewBm.inhaleOffsetsTs =     NewBm.time(NewBm.inhaleOffsets);
                    NewBm.exhaleOffsetsTs =     NewBm.time(NewBm.exhaleOffsets);
                    NewBm.inhalePauseOnsetsTs = NaN(size( NewBm.inhalePauseOnsets));
                    NewBm.exhalePauseOnsetsTs = NaN(size( NewBm.exhalePauseOnsets));
                    NewBm.inhalePauseOnsetsTs(~isnan(NewBm.inhalePauseOnsets)) = NewBm.time(NewBm.inhalePauseOnsets(~isnan(NewBm.inhalePauseOnsets)))   ;
                    NewBm.exhalePauseOnsetsTs(~isnan(NewBm.exhalePauseOnsets)) = NewBm.time(NewBm.exhalePauseOnsets(~isnan(NewBm.exhalePauseOnsets)))   ;
                    NewBm.CycleStartTs = NewBm.time(NewBm.CycleStart) ; 
                    NewBm.CycleEndTs = NewBm.time(NewBm.CycleEnd) ; 
                    NewBm.KeepThisCycle = logical(ones(size(NewBm.CycleStart))) ; 
                    
    if ~isempty(MasterBM)
        PeakDetectedTwice = any(diff(   sort([ MasterBM(i-1).time(MasterBM(i-1).inhalePeaks) ; NewBm.time(NewBm.inhalePeaks) ]))  <    MinimumDistanceBetweenConsecutivePeaksThrough) ;
    else
        PeakDetectedTwice = 0;
    end
    
 
 if PeakDetectedTwice
         PlotPeakDetectedTwice = false;
         Matrix = [ MasterBM(i-1).time(MasterBM(i-1).inhalePeaks) , ones( numel( MasterBM(i-1).inhalePeaks),1)  , reshape(1: numel( MasterBM(i-1).inhalePeaks),[],1)    ; ...
             NewBm.time(NewBm.inhalePeaks) , 2*ones( numel( NewBm.inhalePeaks),1)  , reshape(1: numel(NewBm.inhalePeaks),[],1)    ] ;

         Matrix = sortrows(Matrix,1);
         Matrix(:,end+1:end+2) = [ [diff(Matrix(:,1)) ;NaN] , zeros( size(Matrix,1),1 ) ] ;
         Matrix( find(Matrix(:,end-1)    < MinimumDistanceBetweenConsecutivePeaksThrough  ) + [0,1],end) = 1 ;
         N_Doubled = sum(Matrix(:,end-1)    < MinimumDistanceBetweenConsecutivePeaksThrough);
         
             [~, Shortest ]=  min([,...
                 diff([MasterBM(i-1).CycleStartTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==1),3)),MasterBM(i-1).CycleEndTs( Matrix((find(Matrix(:,end) & Matrix(:,2)==1)),3)) ] , [] , 2) ,...
                 diff([NewBm.CycleStartTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==2),3)),NewBm.CycleEndTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==2),3)) ] , [] , 2) ], []  , 2) ;
          for iDouble = 1 : N_Doubled
            if Shortest(iDouble) == 1
                 NewBm.KeepThisCycle( GetThisRowFromMatrix( Matrix(find(Matrix(:,end) & Matrix(:,2)==2),3) , iDouble) ) = false;
             elseif Shortest(iDouble) == 2
                 MasterBM(i-1).KeepThisCycle(GetThisRowFromMatrix( Matrix(find(Matrix(:,end) & Matrix(:,2)==1),3),iDouble) ) = false;
             end
          end
         
        if PlotPeakDetectedTwice
            clf;
            s1 = subplot(3,1,1);hold on ;
            plot(MasterBM(i-1).time, MasterBM(i-1).baselineCorrectedRespiration,'r')
            scatter(MasterBM(i-1).time(MasterBM(i-1).inhalePeaks), MasterBM(i-1).baselineCorrectedRespiration(MasterBM(i-1).inhalePeaks),'r')
            PlotIntervals([MasterBM(i-1).CycleStartTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==1),3)),MasterBM(i-1).CycleEndTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==1),3))],'color',rgb('Red'),'alpha',0.2)

            s2 = subplot(3,1,2);hold on ;
            plot(NewBm.time, NewBm.baselineCorrectedRespiration,'b')
            scatter(NewBm.time(NewBm.inhalePeaks), NewBm.baselineCorrectedRespiration(NewBm.inhalePeaks),'b')
            PlotIntervals([NewBm(end).CycleStartTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==2),3)),NewBm(end).CycleEndTs( Matrix(find(Matrix(:,end) & Matrix(:,2)==2),3))],'color',rgb('Blue'),'alpha',0.2)

            s3 = subplot(3,1,3);hold on ;
            plot(MasterBM(i-1).time, MasterBM(i-1).baselineCorrectedRespiration,'k')
            plot(NewBm.time, NewBm.baselineCorrectedRespiration,'k')
            scatter(MasterBM(i-1).time(MasterBM(i-1).inhalePeaks(MasterBM(i-1).KeepThisCycle)), MasterBM(i-1).baselineCorrectedRespiration(MasterBM(i-1).inhalePeaks(MasterBM(i-1).KeepThisCycle)),'r')
            scatter(NewBm.time(NewBm.inhalePeaks(NewBm.KeepThisCycle)), NewBm.baselineCorrectedRespiration(NewBm.inhalePeaks(NewBm.KeepThisCycle)),'b')
            linkaxes([s1,s2 , s3],'x')
        end
    clear iDouble Matrix N_Doubled Shortest iDouble 
 end
                    
                           
                    NewBm = RemoveFieldsFromStrucrue(NewBm,{'secondaryFeatures' 'respiratoryPhase' 'featureEstimationsComplete' ,'featuresManuallyEdited' ,'ERPMatrix' ,'ERPxAxis' , 'resampledERPMatrix' 'resampledERPxAxis' 'ERPtrialEvents' 'ERPrejectedEvents', 'ERPtrialEventInds', 'ERPrejectedEventInds' , 'statuses' , 'notes'} ) ;
                    
                    if UseBreathMetrics %& ~isempty(NewBm.inhaleOnsets) ;%& sum(NewBm.inhaleDurations)>0 & sum(NewBm.exhaleDurations)>0
                        try
                            MasterBM = [MasterBM ; NewBm];
                            %CycleToRemove = [CycleToRemove;  iCycle] ;
                        catch
                            %CycleToRemove = [CycleToRemove;  iCycle] ;
                            %disp(['here'])
                        end
                    end
                    clear bm NewBm;
                    
        end  
        delete(WB);
%         if MakeVideo
%             writerObj = VideoWriter([VideoTitle],'MPEG-4');
%             writerObj.FrameRate =5;
%             open(writerObj);
%             writeVideo(writerObj,VideoFrame)
%             close(writerObj )
%         end
            %% 1 Concatenate fields of cycles to Keep

            ConcBmObj = [bmObj];
            
            if isempty(MasterBM )
                return
            else
            
            BMFields =fields(MasterBM);BMFields(contains(BMFields,{'secondaryFeatures','time' ,'rawRespiration' , 'smoothedRespiration' , 'baselineCorrectedRespiration' }))=[];
            KeepThisCycle = logical(ConcatentateIntoStructureIndices(   MasterBM , '.' , 'KeepThisCycle',[],[9])) ;
            CycleStartTs = (ConcatentateIntoStructureIndices(   MasterBM , '.' , 'CycleStartTs',[],[9])) ;
            CycleStartTs = CycleStartTs(KeepThisCycle);
            [~, Order ] = sort(CycleStartTs) ; clear CycleStartTs;
            for iField = 1 : numel(BMFields)
                eval(['ConcBmObj.' BMFields{iField} ' = ConcatentateIntoStructureIndices(   MasterBM ,' char(39) '.' char(39) ',' char(39) BMFields{iField} char(39) ',[],[9]) ;' ]);
                eval(['ConcBmObj.' BMFields{iField} ' =  ConcBmObj.' BMFields{iField} '(KeepThisCycle) ; ' ])
                eval(['ConcBmObj.' BMFields{iField} ' =  ConcBmObj.' BMFields{iField} '(Order) ; ' ])
                clear iField ;
            end
            clear KeepThisCycle Order;
            
            %% Order the cycles; 
            
            [~, Order ] = sort(ConcBmObj.CycleStartTs) ; 
            
            
            
            ConcBmObj.dataType = bmObj.dataType;
            ConcBmObj.srate = bmObj.srate;
            ConcBmObj.inhalePauseDurations(isnan(ConcBmObj.inhalePauseDurations)) = 0; 
            ConcBmObj.exhalePauseDurations(isnan(ConcBmObj.exhalePauseDurations)) = 0; 
            ConcBmObj.inhaleDurations(isnan(ConcBmObj.inhaleDurations)) = 0; 
            ConcBmObj.exhaleDurations(isnan(ConcBmObj.exhaleDurations)) = 0; 

            TsFields = BMFields(contains(BMFields,'Ts'));
            %nCycles = numel(bmObj.inhaleOnsets);
%             for iField = 1 :numel(BMFields);
%                 if eval(['isfield(bmObj,  BMFields{iField} ) && isequal(nCycles ,numel(bmObj.'  BMFields{iField} ')) & ~ismember(BMFields{iField} , TsFields )' ])
%                     eval(['bmObj.'  BMFields{iField} '(CycleToRemove ) = [];' ]);
%                end
%             end;

            %% 1 Fix indices of nTs;
            NonTsFieds = BMFields(~ismember(BMFields , TsFields) );
            nCycles = numel(ConcBmObj.inhaleOnsets);    
%             for iField = 1 : numel(NonTsFieds);
%                     if eval(['isequal(nCycles ,numel(ConcBmObj.'  BMFields{iField} ')) & ~ismember([ BMFields{iField} ' char(39)  'Ts' char(39) '],TsFields) ' ])
%                         eval(['bmObj.' NonTsFieds{iField} ' = [bmObj.' NonTsFieds{iField} '; ConcBmObj.' NonTsFieds{iField} '] ;' ])
%                     end
%                 end
%             %% 2 Fix indices of Ts;
%             for iField = 1 : numel(TsFields);
%                     eval([ TsFields{iField} ' =  ConcatentateIntoStructureIndices(   MasterBM,' char(39) '.' char(39) ',' char(39) TsFields{iField} char(39) ',[],[]) ; ' ])
%                     eval([ TsFields{iField}(1:end-2) 'ToAdd   = knnsearch(bmObj.time , [ConcBmObj.'  TsFields{iField} '] ) ;' ]);
%                     eval(['bmObj.' TsFields{iField}(1:end-2) ' = [bmObj.' TsFields{iField}(1:end-2) '; ' TsFields{iField}(1:end-2) 'ToAdd];' ])
%                     clear ([TsFields{iField}])
%             end

            for iField = 1 : numel(TsFields);
                if eval(['isempty([ConcBmObj.'  TsFields{iField} '])    ' ])
                    eval([ 'ConcBmObj.' TsFields{iField}(1:end-2) ' = [];' ])
                else
                    eval([ 'ConcBmObj.' TsFields{iField}(1:end-2) '   = knnsearch(ConcBmObj.time , [ConcBmObj.'  TsFields{iField} '] ) ;' ]);
                    %eval(['bmObj.' TsFields{iField}(1:end-2) ' = [bmObj.' TsFields{iField}(1:end-2) '; ' TsFields{iField}(1:end-2) 'ToAdd];' ])
                    %clear ([TsFields{iField}])
                end
            end





%             %% 3 Order cycles from Ts;
%             [~,Order]= sort(bmObj.inhalePeaks);
%             nCycles = numel(bmObj.inhaleOnsets);
%             BMFields = BMFields(~ismember(BMFields,TsFields)) ;
%             for iField = 1 : numel(TsFields);
%                 if eval(['isequal(nCycles,numel(bmObj.' BMFields{iField}  ') ) ' ])
%                     eval(['bmObj.' BMFields{iField} ' = bmObj.' BMFields{iField} '(Order); '] );
%                 end
%             end
            %% 4 Set as NaNs those with no pauses
            ConcBmObj.inhalePauseOnsets(ConcBmObj.inhalePauseDurations==0) = NaN;
            ConcBmObj.exhalePauseOnsets(ConcBmObj.exhalePauseDurations==0) = NaN;
            %% 5 Check there are no NaNs...
            %[~,UniqueCycles] = unique([ ConcBmObj.inhalePeaksTs ] ) ; 
            %Replicates = reshape([ (not(ismember([1:numel(ConcBmObj.inhalePeaksTs) ],UniqueCycles))) ] ,[],1) ;  
            
            Replicates = [diff([ConcBmObj.inhalePeaksTs]);NaN]<=MinimumDistanceBetweenConsecutivePeaksThrough  & [diff([ConcBmObj.exhaleTroughsTs]);NaN]<=MinimumDistanceBetweenConsecutivePeaksThrough  ;
            CyclesToRemove =  find([Replicates | isnan(ConcBmObj.peakInspiratoryFlows) | isnan(ConcBmObj.troughExpiratoryFlows) | isnan(ConcBmObj.inhaleOnsets) | isnan(ConcBmObj.inhaleOffsets) | isnan(ConcBmObj.exhaleOnsets)  | isnan(ConcBmObj.exhaleOffsets)] ) ;
            for iField = 1 : numel(BMFields);
                if eval(['isequal(nCycles,numel(ConcBmObj.' BMFields{iField}  ') ) ' ])
                    eval(['ConcBmObj.' BMFields{iField} '(CyclesToRemove,:) = [];; '] );
                end
            end
        
            ConcBmObj = RemoveFieldsFromStrucrue(ConcBmObj,TsFields);
            ConcBmObj = RemoveFieldsFromStrucrue(ConcBmObj,{'indices'}) ;
            clear bmObj; 
            bmObj = ConcBmObj;
            end
        
end