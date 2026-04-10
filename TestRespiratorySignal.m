%% Respiratory pipeline shared via gitHub
% Matlab Script produced by Dr. Giulio Casali (giulio.casali.pro@gmail.com) and Tim Gervois (tim.gervois@u-bordeaux.fr)
% from Dr. Lisa Roux (lisa.roux@u-bordeaux.fr) laboratory at IINS, Bordeaux, France.

% This pipeline is used for the paper Casali et al., "Respiratory pauses highlight sleep
% architecture" published in Nature Communications 2026 
% Below there are few lines of code summarizing the analytical work used in the study 
% to examine respiratory signal recoreded in freely-moving mice with portable pressure sensors.
% Before running the code, please read the instructions in the READ me section given here.
 
% Be aware: data collection and formatting is largely consistent with that from Buzsaki lab (buzcode-master, https://github.com/buzsakilab/buzcode)
% which is necessary to have in the Matlab Path in order to read respiratory data and perform cycle extraction
%%%%%%%%%%%%%%%
clear
%% 1) Extract the resp data acquired with Intan technology:
% Original sampling rate at 20KHz and downsampled to 1250 Hz same as LFP signal) and check that the full respiration signal is indeed valid for the entire session;
% For familiarizing with the dataset, here one example of session is given and can be loaded as follows:
TestSession = [ '3C060-S16'];
load([cd  '\RawData\' TestSession '\respiration.mat'])
Signal = [ respiration.timestamps, double(respiration.data)] ;
%% For loading a different/new session, it is possible to use the following codes (check the formatting is compatible with the buzcode-master)
% sessionPath = [cd  '\' '3C060-SXX\'];
% sessionInfo = bz_getSessionInfo(sessionPath, 'noPrompts',true,'saveMat',false);
% % sessionInfo.AnalogChannelInfo.Respiration.Channel is the analog channel
% % dedicated to respiration recording in Intan
% respiration = bz_GetLFP( sessionInfo.AnalogChannelInfo.Respiration.Channel,'basepath',sessionPath);
% save('respiration','respiration')
%[fList,pList] = matlab.codetools.requiredFilesAndProducts('PreliminarySniffExamination.m');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2) Examine the resp signal and select the ValidSniffInt - this is crucial for using only chunks of time with real respiratory signal.
[ValidSniffInt] = VisuallyInspectSniffSignalForSniffInt(Signal) ;
Signal = Restrict(Signal, [ValidSniffInt] );
StateBlindSniffIntToUse =ValidSniffInt ;

%% 3) Run MouseBreathMetricsWrapper using ALL the intervals of Valid Sniff Int (i.e. the same as the StateBlindSniffIntToUse)
subplot(2,1,1);StateBlindSniffing = MouseBreathMetricsWrapper(Signal(:,1),Signal(:,2),respiration.samplingRate,ValidSniffInt , StateBlindSniffIntToUse,true); 
disp('State blind Resp signal');

%% 4) Run MouseBreathMetricsWrapper using ALL the intervals of Valid Sniff Int but also split by state (i.e. the same as the ValidSniffIntByState)
%The goal is to make MouseBreathMetric more "tuned" for examinining resp where the signal is more homogeneous
load([cd  '\RawData\' TestSession '\StatesIntervals.mat'])
StateInts = sortrows([ statesint.sws;statesint.wake;statesint.rem],[2 ]);
ValidSniffIntByState = FindCommonIntervals(ValidSniffInt , StateInts) ; % it splits the valid blocks with state-blocks.
subplot(2,1,2);StateDependentSniffing = MouseBreathMetricsWrapper(Signal(:,1),Signal(:,2),respiration.samplingRate,ValidSniffInt, ValidSniffIntByState, true);

%% 5) Use the results from "StateBlindSniffing" to perform state predictions based on respiratory cycles.
DataFromStateBlind = PrepareBmObjForCnnPrediction(StateBlindSniffing.bmObj,statesint) ;
% Now use the Data.mat file saved from "PrepareBmObjForCnnPrediction" to
% perform cycle prediction.

%% 6) Examine the Predition from the CNN.
load  CNN_Prediction

figure(1);clf;
s1=subplot(3,1,1); p=plot(CNN_Prediction.CycleTs, CNN_Prediction.confidence);
xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])
ylabel('Probability');legend(p,{'Wake','NREM','REM'}, 'box','off');title('Confidence');

s2=CleandSubplot(3,1,2);
hold on ;s=scatter(...
DataFromStateBlind.Single.CycleTs(DataFromStateBlind.Single.State==1),...
DataFromStateBlind.Single.State(DataFromStateBlind.Single.State==1),'SizeData',10,'CData',rgb('Black'));
hold on ;scatter(...
DataFromStateBlind.Single.CycleTs(DataFromStateBlind.Single.State==2),...
DataFromStateBlind.Single.State(DataFromStateBlind.Single.State==2),'SizeData',10,'CData',rgb('Black'));
hold on ;scatter(...
DataFromStateBlind.Single.CycleTs(DataFromStateBlind.Single.State==3),...
DataFromStateBlind.Single.State(DataFromStateBlind.Single.State==3),'SizeData',10,'CData',rgb('Black'));
xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])
ylim([0,4]) ; xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])
set(gca,'YTick',[1,2,3],'YTickLabel', {'Wake','NREM','REM'}); title('Annotated Cycles');
PlotIntervals(statesint.wake,'Color','b','alpha',0.3);
PlotIntervals(statesint.sws,'Color','r','alpha',0.3);
PlotIntervals(statesint.rem,'Color',rgb('orange'),'alpha',0.3);
xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])

s3= subplot(3,1,3);
hold on ;scatter(CNN_Prediction.CycleTs(CNN_Prediction.prediction(:,1)==1),...
    CNN_Prediction.prediction(CNN_Prediction.prediction(:,1)==1,1),'SizeData',10,'CData',rgb('Black'));
hold on ;scatter(CNN_Prediction.CycleTs(CNN_Prediction.prediction(:,2)==1),...
    CNN_Prediction.prediction(CNN_Prediction.prediction(:,2)==1,2)*2,'SizeData',10,'CData',rgb('Black'));
hold on ;scatter(CNN_Prediction.CycleTs(CNN_Prediction.prediction(:,3)==1),...
    CNN_Prediction.prediction(CNN_Prediction.prediction(:,3)==1,3)*3,'SizeData',10,'CData',rgb('Black'));
xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])
ylim([0,4]) ; 
xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])
set(gca,'YTick',[1,2,3],'YTickLabel', {'Wake','NREM','REM'}); title('Predicted Cycles');

CNN_Prediction.predicted_wake = (CNN_Prediction.CycleTs(DetectMarginsFromArray( CNN_Prediction.prediction(:,1)==1,CNN_Prediction.prediction(:,1)==1)));
CNN_Prediction.predicted_nrem = (CNN_Prediction.CycleTs(DetectMarginsFromArray( CNN_Prediction.prediction(:,2)==1,CNN_Prediction.prediction(:,2)==1))) ; 
CNN_Prediction.predicted_rem = (CNN_Prediction.CycleTs(DetectMarginsFromArray( CNN_Prediction.prediction(:,3)==1,CNN_Prediction.prediction(:,3)==1))) ; 
CNN_Prediction.predicted_wake(diff(CNN_Prediction.predicted_wake,[],2)==0,:) = [];
CNN_Prediction.predicted_nrem(diff(CNN_Prediction.predicted_nrem,[],2)==0,:) = [];
CNN_Prediction.predicted_rem(diff(CNN_Prediction.predicted_rem,[],2)==0,:) = [];
PlotIntervals(CNN_Prediction.predicted_wake,'Color','b','alpha',0.3);
PlotIntervals(CNN_Prediction.predicted_nrem,'Color','r','alpha',0.3);
PlotIntervals(CNN_Prediction.predicted_rem,'Color',rgb('orange'),'alpha',0.3);
xlim([min(StateBlindSniffing.SniffIntToUse(:)),max(StateBlindSniffing.SniffIntToUse(:))])




