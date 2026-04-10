function Data = PrepareBmObjForCnnPrediction(bmObj, statesint)

bmObj.inhalePauseDurations(isnan(bmObj.inhalePauseDurations)) = 0;
bmObj.exhalePauseDurations(isnan(bmObj.exhalePauseDurations)) = 0;

if ~isfield(bmObj,'exhaleTimeToTrough')   % remove 'exhaleTimeToTrough' field
    bmObj.exhaleTimeToTrough = bmObj.timeToTroughs;
    bmObj = rmfield(bmObj,'timeToTroughs');
end

ValidWindows = bmObj.ValidWindows;

 States = {'wake','sws','rem' }; % Why Alllicking ?
        for iState = 1 : numel(States);
            try
            eval(['statesint.' States{iState} ' = FindCommonIntervals(statesint.' States{iState} ',ValidWindows);' ]);
            catch
            eval(['statesint.' States{iState} ' = [];' ]);
            end
        end        
        Wint = statesint.wake;  try Wint = Wint + [-0.5,0.5];end; % increases a bit intervals size
        Sint = statesint.sws ;  try Sint = Sint + [-0.5,0.5];end; % Only works if State scoring took into account sleep substate
        Rint = statesint.rem ;  try Rint = Rint + [-0.5,0.5];end;
     CyOnsets = bmObj.time(bmObj.inhaleOnsets); % 1250Hz, referential of the entire session
    [statusW,intervalW,iCyWAK] = InIntervals(CyOnsets,Wint);
    [statusS,intervalS,iCySWS] = InIntervals(CyOnsets,Sint);
    [statusR,intervalR,iCyREM] = InIntervals(CyOnsets,Rint);
    [statusLicking,intervalLicking,iCyLicking] = InIntervals(CyOnsets,Rint);
    State = double(statusW); % 1 is wake
    State(statusS)= 2; % 2 is sws
    State(statusR)= 3; % 3 is REM
    MATRIX = [      reshape(bmObj.inhalePeaks , [],1) ,...
                    reshape(bmObj.exhaleTroughs, [],1) ,...
                    reshape(bmObj.peakInspiratoryFlows, [],1) ,...
                    reshape(bmObj.troughExpiratoryFlows, [],1) ,...
                    reshape(bmObj.inhaleTimeToPeak, [],1) ,...
                    reshape(bmObj.exhaleTimeToTrough,[],1) ,...
                    reshape(bmObj.inhaleVolumes,[],1) ,...
                    reshape(bmObj.exhaleVolumes,[],1) ,...
                    reshape(bmObj.inhaleDurations,[],1) ,...
                    reshape(bmObj.exhaleDurations,[],1) ,...
                    reshape(bmObj.inhalePauseDurations, [],1) ,...
                    reshape( bmObj.exhalePauseDurations, [],1) ];

    eval(['Data.Single.Matrix = MATRIX; '])
    eval(['Data.Single.State = State; '])
    save('Data', 'Data' , '-v7.3' );  
end