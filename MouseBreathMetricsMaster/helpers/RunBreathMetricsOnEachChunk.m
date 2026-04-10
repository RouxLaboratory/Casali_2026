function ConcBmObj = RunBreathMetricsOnEachChunk(Data , LowFrequencySampling ,SniffInt , StateName , FixParametersForInhExh) 
%% Function written by Giulio Casali - giulio.casali.pro@gmail.com.
% This performs breathmetrics a number of times to maximimize the number of cycles extracted from raw signals recorded with intra-nasal pressure sensors.
% SniffInt is a critical input because it fragments the analyses onto valid
% sniff chunks which could have been split by state to improve the
% precision of the cycle extraction.
% Note - the StateName (a string for each SniffInt ) does not change the computaton, is just for storing info of kind of signal will be produced.

if not(exist('StateName','var')) | isempty(StateName);  StateName = repmat({'Unclassified'},size(SniffInt,1),1) ; end;
if not(exist('FixParametersForInhExh','var')) | isempty(FixParametersForInhExh);  FixParametersForInhExh=false; end;

MasterBmObj = [];
zScore = 0;
baselineCorrectionMethod = 'sliding';
simplify = true;
verbose = false;
ShowPlot = 0;
ChunkLength = diff(SniffInt,[],2) ;
MinimumDistanceBetweenConsecutivePeaksThrough = 0.020; %% in seconds; == 20 ms;

%% 1) Run breathmetrics just to produce the best baseline corrected signal, so that cycle component detection work best ;

MousePath = char(bz_BasenameFromBasepath(cd) );
ChunkBar = waitbar(0, ['Running BmObj through from' MousePath ': total ' num2str(size(SniffInt,1))  ' Chunks ...']);

for iChunk = 1 : size(SniffInt,1) ;    % for each SniffIntervals...
                    waitbar(iChunk/size(SniffInt,1) , ChunkBar); 
                    clear tmpbmObj;
                    bmObj = [];
                    TimeChunk = SniffInt(iChunk,:);
                    disp(['Chunk #' num2str(iChunk)  ' (' num2str(TimeChunk(1))  '-' num2str(TimeChunk(2)) ' s)' ] )
                    
                    tmpbmObj = breathmetrics(Data(:,2), LowFrequencySampling.SampleRate, 'rodentAirflow'); % tmpbmObj is an object class (contains data and functions)
                    
                    if ~FixParametersForInhExh
                        tmpbmObj.correctRespirationToBaseline(baselineCorrectionMethod, zScore, verbose) ; % removes drift or offset in signal. USELESS because recreated from smoothsignal in the next section 
                    end
                    %% Restrict Sniff Signal to indicated Sniff Intervals, and detrend the signal until some peaks can be detected using breathmetrics findextrema function.
                    % If you run each chunk then the baseline correction does not work as good;
                    
                    % Restrict sinff signal
                    
                    tmpData = Restrict([Data(:,1),reshape(tmpbmObj.rawRespiration,[],1) , reshape(tmpbmObj.smoothedRespiration,[],1) ,reshape(tmpbmObj.baselineCorrectedRespiration,[],1) ] ,TimeChunk); % restrict sniff signals to the chunk time
                    tmpbmObj.time = reshape(tmpData(:,1),1,[]); % convert to row vector
                    tmpbmObj.rawRespiration = reshape(tmpData(:,2),1,[]);
                    tmpbmObj.smoothedRespiration = reshape(tmpData(:,3),1,[]);
                    if ~FixParametersForInhExh;
                        tmpbmObj.baselineCorrectedRespiration = reshape(tmpData(:,4),1,[]);end;
                    
                    % detrend signal
                    
                    PeaksNotDetected = true;
                    
                    while PeaksNotDetected
                        try;
                            tmpbmObj.findExtrema(simplify, verbose);
                            PeaksNotDetected = isempty(tmpbmObj.inhalePeaks);
                            if PeaksNotDetected
                                tmpbmObj.baselineCorrectedRespiration =detrend(tmpbmObj.smoothedRespiration-[movmean(tmpbmObj.smoothedRespiration,tmpbmObj.srate)]) ;;
                            end
                        catch
                            tmpbmObj.baselineCorrectedRespiration =detrend(tmpbmObj.smoothedRespiration-[movmean(tmpbmObj.smoothedRespiration,tmpbmObj.srate)]) ;
                            PeaksNotDetected = true;
                        end
                    end
                    %% When inhale peaks have been found : find cycles onsets and pauses, or smooth the signal if you do not manage. Then find other features
                    if ~isempty(tmpbmObj.inhalePeaks)
                        try;
                            tmpbmObj.findOnsetsAndPauses(verbose);
                        catch
                           try;
                               KeepSmoothing = 1;
                               k=3;
                               while KeepSmoothing;
                                   k = k+2;
                                   tmpbmObj.baselineCorrectedRespiration = sgolayfilt(tmpbmObj.baselineCorrectedRespiration,[ 2 ] , [ k] ) ;
                                            try;
                                                tmpbmObj.findOnsetsAndPauses(verbose);
                                                KeepSmoothing=false;
                                                clear k;
                                            catch
                                                KeepSmoothing = true;
                                            end
                                end
                               
                               
                           end    
                        end
                        
                        % find other components
                        clear KeepSmoothing k;
                        tmpbmObj.findInhaleAndExhaleOffsets(verbose);
                        tmpbmObj.findBreathAndPauseDurations();
                        tmpbmObj.findInhaleAndExhaleVolumes(verbose);
                        tmpbmObj.getSecondaryFeatures(verbose);
                        
                        % remove last cycle if not all components detected                        
                        RemoveLastCycle  = sum(isnan(tmpbmObj.inhaleOnsets(end))) | sum(isnan(tmpbmObj.inhaleOffsets(end))) |sum(isnan(tmpbmObj.exhaleOnsets(end))) | sum(isnan(tmpbmObj.exhaleOffsets(end)));
                    else
                        RemoveLastCycle = 0;
                    end
                    
                    tmpbmObj.time = tmpData(:,1);
                        
                    %% reshape and transfer that to bmObj
                    
                    eval(['nCycles =numel(tmpbmObj.inhaleOnsets);']);
                    eval(['nData =size(tmpData,1);']);
                    eval(['bmFields =fields(tmpbmObj);' ]);
                    
                    % remove some fields
                    bmFields(ismember(bmFields,{'featuresManuallyEdited' , 'featureEstimationsComplete' 'secondaryFeatures' ,'featureEstimationsComplete'})) = []; 
                    
                    % reshape tmpbmObj
                    for   iField = 1 : numel(bmFields); 
                        if eval(['isequal( nData, numel(tmpbmObj.' bmFields{iField} ') ) ' ]);
                            eval([ 'tmpbmObj.' bmFields{iField}  '='  'reshape(tmpbmObj.' bmFields{iField} ',[],1);; ' ]);;
                        end
                        if eval(['isequal( nCycles, numel(tmpbmObj.' bmFields{iField} ') ) ' ]);
                            eval([ 'tmpbmObj.' bmFields{iField}  '='  'reshape(tmpbmObj.' bmFields{iField} ',[],1);; ' ]);;
                            if RemoveLastCycle;
                                eval([ 'tmpbmObj.' bmFields{iField}  '='  'tmpbmObj.' bmFields{iField} '(1:nCycles-1); ' ]);
                            end
                        end
                           
                    % transfer data to bmObj 
                    eval([ 'bmObj.' bmFields{iField}  '='  'tmpbmObj.' bmFields{iField} '; ' ]);
                    clear iField;
                    
                    end

                   %% section to improve pause detection 
                    try;
                        bmObj = FixbmObjects( bmObj ,FixParametersForInhExh)  ;
                    catch
                       keyboard ; 
                    end

                    %% Store Ts to have times instead of indices
                    bmObj.inhalePeaksTs   =   bmObj.time(bmObj.inhalePeaks) ;
                    bmObj.exhaleTroughsTs = bmObj.time(bmObj.exhaleTroughs) ;
                    bmObj.inhaleOnsetsTs  =  bmObj.time(bmObj.inhaleOnsets) ;
                    bmObj.exhaleOnsetsTs  =  bmObj.time(bmObj.exhaleOnsets);
                    bmObj.inhaleOffsetsTs =  bmObj.time(bmObj.inhaleOffsets);
                    bmObj.exhaleOffsetsTs =  bmObj.time(bmObj.exhaleOffsets);
                    bmObj.inhalePauseOnsetsTs = NaN(size( bmObj.inhalePauseOnsets));
                    bmObj.exhalePauseOnsetsTs = NaN(size( bmObj.exhalePauseOnsets));
                    bmObj.inhalePauseOnsetsTs(~isnan(bmObj.inhalePauseOnsets)) = bmObj.time(bmObj.inhalePauseOnsets(~isnan(bmObj.inhalePauseOnsets)))   ;
                    bmObj.exhalePauseOnsetsTs(~isnan(bmObj.exhalePauseOnsets)) = bmObj.time(bmObj.exhalePauseOnsets(~isnan(bmObj.exhalePauseOnsets)))   ;
                    bmObj.CycleStartTs=    bmObj.time(bmObj.CycleStart);
                    bmObj.CycleEndTs = bmObj.time(bmObj.CycleEnd);
                    try
                    MasterBmObj= [MasterBmObj;bmObj] ; % concatenate those chunk bmObj into Master bmObj
                    end
                    clear tmpbmObj bmObj;
end;
delete(ChunkBar);

%% 2) Concatenate MasterbmObj into ConcBmObj, Sort indices of Ts, remove some cycles, choose unique fields 
ConcBmObj = [];
BMFields =fields(MasterBmObj);
BMFields(contains(BMFields,'secondaryFeatures'))=[]; % delete secondary features fields

% Concatenate each chunk inhale peaks 
ConcBmObj.inhalePeaksTs = ConcatentateIntoStructureIndices( MasterBmObj ,'.' , 'inhalePeaksTs' ,[],[]) ; 
n_cycles = numel(ConcBmObj.inhalePeaksTs); % weired, not the same number of cycles than precedently... : FixBmObj function may explain that
[ConcBmObj.inhalePeaksTs , Order] = sort(ConcBmObj.inhalePeaksTs) ;

% Determines NaNs or too close cycles to be removed later
ToRemove = or( isnan(ConcBmObj.inhalePeaksTs ) ,[diff(ConcBmObj.inhalePeaksTs);NaN] <= MinimumDistanceBetweenConsecutivePeaksThrough ) ;

%Transfer all other fields to ConcBmObj
for iField = 1 : numel(BMFields)
    eval(['ConcBmObj.' BMFields{iField} ' = ConcatentateIntoStructureIndices(   MasterBmObj ,' char(39) '.' char(39) ',' char(39) BMFields{iField} char(39) ',[],[]) ;' ]);
    if eval([' isequal(numel(ConcBmObj.' BMFields{iField} '),n_cycles);' ])
        eval(['ConcBmObj.' BMFields{iField} ' = ConcBmObj.' BMFields{iField} '(Order,:);' ]) % Order Cycles
        eval(['ConcBmObj.' BMFields{iField} '(ToRemove,:)=[];;' ]) % Remove NaNs or too close cycles
    end
    clear iField ;
end

clear n_cycles ToKeep  ToRemove;

% Transfer time and signals 
ConcBmObj.dataType = MasterBmObj(1).dataType;
ConcBmObj.srate = MasterBmObj(1).srate;
ConcBmObj.time = Data(:,1) ;
ConcBmObj.rawRespiration = Data(:,2) ;
ConcBmObj = RemoveFieldsFromStrucrue(ConcBmObj, {'smoothedRespiration', 'baselineCorrectedRespiration'}) ;
   
%% Transform timestamps into time index : what's the point ?
TsFields = BMFields(contains(BMFields,'Ts'));
n_cycles = numel(ConcBmObj.inhalePeaksTs);
for iField = 1 : numel(TsFields)
        eval([ TsFields{iField} ' =  ConcatentateIntoStructureIndices(   ConcBmObj,' char(39) '.' char(39) ',' char(39) TsFields{iField} char(39) ',[],[]) ; ' ]) % extract timestamp field data
         eval(['ConcBmObj.' TsFields{iField}(1:end-2) '=[NaN(n_cycles,1)];']) % initialise index field
        eval(['ConcBmObj.' TsFields{iField}(1:end-2) '(~isnan(' TsFields{iField} '))  = knnsearch(ConcBmObj.time , [ '  TsFields{iField} '(~isnan(' TsFields{iField} '))] ) ;' ]); % replace with closest time index
        clear ([TsFields{iField}])
end 
%% 3 Remove Ts unnecessary; Why removing Ts fields now ?? (Tim)
ConcBmObj = RemoveFieldsFromStrucrue(ConcBmObj , TsFields ) ;
%% 4 Remove useless fields; what's the point of bm_field variable ?
n_cycles = numel(ConcBmObj.inhaleOnsets);

bm_fields = fields(ConcBmObj) ;
bm_fields(...
    ismember(bm_fields,{'inhalePauseOnsets' ,'exhalePauseOnsets' ,'notes','statuses'  ,...
    'inhalePauseDurations','exhalePauseDurations','respiratoryPhase' , ...
    } ) ) = [];;

ConcBmObj = RemoveFieldsFromStrucrue(ConcBmObj,{'notes','statuses' ,'respiratoryPhase'  ,'ERPMatrix' ,'ERPxAxis' ,'resampledERPMatrix'  ,'resampledERPxAxis' ,'ERPtrialEvents',...
    'ERPrejectedEvents','ERPtrialEventInds','ERPrejectedEventInds' ,'KeepThisCycle'} ) ;

end

                   