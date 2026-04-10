function Sniffing = PreliminarySniffExamination(t_Input,Data_Input,Fs,ValidSniffInt,SniffIntToUse , PLOT);
%% Wrapper function for examining sniff trace using MouseBreathmetrics - a Matlab toolbox written by Giulio Casali (ROUX LAB, CNRS) -
%based on the redundant/intensive exploitation of "breathmetrics"  (Zelano 2018) designed to extract sniff cycles embedded inside human airflow traces;

% These parameters are the ones used in ROUX team -
% These are the features of the resistors used in the voltage-divider built
% by Pascal Ravassard.
% Important to know: The original signal was collected at 20kHz and with original signal using [-4,4 psi] mapped between 0-5V;
% The signal fed into the intan board is shifted to 0-3.3V.
% It is important to deal with these parameters correctly if the amplitude of the waveforms need to be examined thoroughly.

%% Inputs:
% 1) t_Input = vector of time-stamps
% 2) Data_Input = vector of raw pressure data in Volts same as t_Input;
% 3) Fs = sampling rate of the raw signal;
% 4) SniffIntToUse = [ intervals of interest for examining sniffing traces]

%% Outputs:
% 1) Sniffing: a mat structure


%% Hardcore parameters:
Params.ImpossibleLength = 5; % in seconds - if cycles are longer than this duration it means an error occurred- better to discard this window and exclude from future analyses;

%%  Output
%   1) Sniffing

%%  1) Format Input data;
%   1A) Turn signal in columsn;
t = reshape(t_Input,[],1);
Data = reshape(Data_Input,[],1);

%   1B) Create output structure
Sniffing = [];
Sniffing.SampleRate = Fs;
Sniffing.TimeWindow =[0,ceil(t(end)) ]  ;
Sniffing.Ts =  reshape(EqualBinning([ Sniffing.TimeWindow ] , Sniffing.SampleRate^-1 )  , [],1) ;%% bmObj.time ;

%%  2) Convert signal in PSI - for this the parameters of the voltage-divider should be checked.
%   2A)   Here the features used in ROUX lab are described - but it is something it can vary across setups/labs ecc...
PressureSignalParameters =[];
PressureSignalParameters.OffsetToAddTo3_3V = 0.0;
PressureSignalParameters.R2 = 180 *10^3;
PressureSignalParameters.R1 = 100 *10^3;

%   2B) Calibration of the signal is performed here;
CalibratedSniffSignal = CalibrateRawPressureSignal([t,Data],PressureSignalParameters , false ,SniffIntToUse );
t = CalibratedSniffSignal(:,1) ; % ts over time
Data = CalibratedSniffSignal(:,2) ; % Raw Voltage Signal over time
clear CalibratedSniffSignal;

%   2C) Formattin the signal for breathmetrics - the inverted signal is because the human signal ...
%   is with the opposite polarity (inhalation upwards, exhalation downwards) - so first invert the signal to detect inhalation/exhalation peaks correctly
InvertedData  = -1*(Data) ;

%%  3) MOUSE-BREATHMETRICS
%   3A) The actual computation occurs here with the ivnerted data - in this exampl;
bmObj = RunBreathMetricsOnEachChunk([t,InvertedData] , Sniffing , SniffIntToUse )  ;

%   3B) Update now the ivnerted signal wit the real one;
bmObj.rawRespiration = Data;
InvertedBreathMetrics = breathmetrics(bmObj.rawRespiration, Sniffing.SampleRate, 'rodentAirflow');
InvertedBreathMetrics.correctRespirationToBaseline('sliding', 0, true);
bmObj.rawRespiration                = (InvertedBreathMetrics.rawRespiration) ;
bmObj.smoothedRespiration           = (InvertedBreathMetrics.smoothedRespiration) ;
bmObj.baselineCorrectedRespiration  = (InvertedBreathMetrics.baselineCorrectedRespiration) ;
clear InvertedBreathMetrics ;

%% 4) Post-hoc curing of the signal -
%   4A) - Curing cycles using minimum threshold duration, overlapping cycles
%   or cycles which require stitching
[bmObj , PostProcessesSniffIntToUse  , PostProcessesGoodSniffInt ]  = RemoveExtraCyclesFromSniffTrace(bmObj , Params.ImpossibleLength ,Sniffing ,SniffIntToUse  , SniffIntToUse, SniffIntToUse)  ;

%4B) Now re-interpolate cycles relative to the Sniffing.Ts (
Sniffing.bmObj = UpdataBmBobj(bmObj, Sniffing.Ts  , PostProcessesGoodSniffInt, Sniffing.TimeWindow)  ;
clear bmObj;


Sniffing.SniffIntToUse =SniffIntToUse;
Sniffing.PostProcessesGoodSniffInt =PostProcessesGoodSniffInt;

%% Plot the 2 seconds for inspection
if PLOT
hold on ; ;ylim([-1,1]*5);
ThisTimeWindow = [10]+[0,2];
PlotXY(Restrict([Sniffing.bmObj.time,Sniffing.bmObj.rawRespiration],ThisTimeWindow),'k')
PlotXY(Restrict([Sniffing.bmObj.time(Sniffing.bmObj.inhalePeaks),Sniffing.bmObj.rawRespiration(Sniffing.bmObj.inhalePeaks)],ThisTimeWindow),'r.') ; % inhale peaks
PlotXY(Restrict([Sniffing.bmObj.time(Sniffing.bmObj.exhaleTroughs),Sniffing.bmObj.rawRespiration(Sniffing.bmObj.exhaleTroughs)],ThisTimeWindow),'b.') ; % exhale peaks
PlotIntervals(  Restrict(  Sniffing.bmObj.time([Sniffing.bmObj.inhaleOnsets Sniffing.bmObj.inhaleOffsets ] ) , ThisTimeWindow) , 'color','r','alpha',0.2)
PlotIntervals(  Restrict(  Sniffing.bmObj.time([Sniffing.bmObj.exhaleOnsets Sniffing.bmObj.exhaleOffsets ] ) , ThisTimeWindow) , 'color','b','alpha',0.2);
PlotIntervals(  Restrict(  Sniffing.bmObj.time(RemoveNansFromHorizontalRows([Sniffing.bmObj.inhalePauseOnsets Sniffing.bmObj.exhaleOnsets ] )) , ThisTimeWindow) , 'color','k','alpha',0.2);
PlotIntervals(  Restrict(  Sniffing.bmObj.time(RemoveNansFromHorizontalRows([Sniffing.bmObj.exhalePauseOnsets Sniffing.bmObj.CycleEnd ] )) ,ThisTimeWindow) , 'color','k','alpha',0.2);
xlabel('Time (s)');
ylabel('Pressure (PSI)');
xlim(ThisTimeWindow);
end;
end





