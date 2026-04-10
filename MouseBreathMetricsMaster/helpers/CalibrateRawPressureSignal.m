function [PsiSignal ,BarSignal  ] = CalibrateRawPressureSignal(Signal,PressureSignalParameters ,  PLOT_ON,TimeWindow ,IntanRecording)
% Function written by GC to account for the calibration in instantaneous intra-nasal 
% pressure sensor recorded with Honeywell sensors; 
% Note, the resistance in "PressureSignalParameters" must be precise to
% perfrom correct calibration in PSI
if ~exist('IntanRecording','var');IntanRecording = true; end;
MaxPressureVoltage = 5;                 %% R2 = 180; R1 = 100;
MaxRecordedVoltage = MaxPressureVoltage * [PressureSignalParameters.R2]/[PressureSignalParameters.R2+PressureSignalParameters.R1];%3.3;

V_Range = [ 0.1,.9 ]*MaxPressureVoltage; % Volts; 
Conversion = [0, MaxRecordedVoltage ]; %Volts;
PressureRange = [4 ] *[-1,1] ;%% PSI;
PsiToBar = 0.069 ; %% Bar
VoltageConversor  = MaxRecordedVoltage /  MaxPressureVoltage ;
RawToVolt = [10^4 ];
VoltToBar =  max(PressureRange) / nanmean(V_Range) ;

Signal_3V = Signal; 
if IntanRecording;
    Signal_3V(:,2) =2* Signal(:,2) *[0.000050354  ] ;
    Signal_3V(:,2) = Signal_3V(:,2) + PressureSignalParameters.OffsetToAddTo3_3V ;
else
    Signal_3V(:,2) = Signal_3V(:,2) + PressureSignalParameters.OffsetToAddTo3_3V ;
end;

Signal_5V  = Signal_3V; 
Signal_5V(:,2) = Signal_3V(:,2) * 1/VoltageConversor;

PsiSignal(:,1) = Signal_5V(:,1);
PsiSignal(:,2) = Signal_5V(:,2) - nanmean(V_Range) ;
PsiSignal(:,2) = PsiSignal(:,2) / max(V_Range-nanmean(V_Range));
PsiSignal(:,2) = PsiSignal(:,2)* max(PressureRange);
BarSignal(:,1) = PsiSignal(:,1);
BarSignal(:,2) = PsiSignal(:,2) * PsiToBar;

if PLOT_ON;; 
%% Display if visual examination is necessary
clf;
s1 = subplot(5,1,1); PlotXY(Restrict(Signal,[TimeWindow] ));        ylim([[nanmean([Signal(:,2) ] )] .* [-3,3]] ) ;   ylabel('Volt'); hold on ; line(xlim(), [3.3 3.3]/2,'Color','r' )
s2 = subplot(5,1,2); PlotXY(Restrict(Signal_3V,[TimeWindow] ));     ylim([nanmean([0,MaxRecordedVoltage ] )]*[0,2]);   ylabel('Volt'); hold on ; line(xlim(), [3.3 3.3]/2,'Color','r' )
s3 = subplot(5,1,3); PlotXY(Restrict(Signal_5V,[TimeWindow] ));     ylim([nanmean([0,MaxPressureVoltage] )]*[0,2]);      ylabel('Volt');hold on ; line(xlim(), [5 5]/2,'Color','r' )
s4 = subplot(5,1,4); PlotXY(Restrict(PsiSignal,[TimeWindow] ));     ylim([PressureRange]);              ylabel('PSI');;hold on ; line(xlim(), [0, 0]/2,'Color','r' )
s5 = subplot(5,1,5); PlotXY(Restrict(BarSignal,[TimeWindow ] ));    ylim([PressureRange*PsiToBar]);     ylabel('Bar');    hold on ; line(xlim(), [0, 0 ]/2,'Color','r' );
linkaxes([s1,s2,s3,s4,s5], 'x')
end

end