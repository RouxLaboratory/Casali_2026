function PUTATIVE_PAUSE_INDS = ProducePlotForCycleOfInhalationWindow(Data, FirstDerivateWindow ,ZERO_CROSS_THRESHOLD, PlotFigure)
%% Function written by Dr Giulio Casali (giulio.casali.pro@gmail.com) in Roux laboratory at IINS, Bordeaux, France.
%% The aim of this function is to extract indices (PUTATIVE_PAUSE_INDS) where based on the derivative of the original sniff signal, the flat window is detected;
% INPUTs
% 1) Original data of the inhalation/exhalation window;
% 2)Derivative of the original signal
% 3) ZERO_CROSS_THRESHOLD: useful as hardcore threshold (defined in the parent function)
% 4) PlotFigure: logical to plot for a given sniff cycle the result; It is useful for debugging but during running should be set to 0;

t = [1:numel(Data) ] ;
MeanValue = nanmean(Data) ; 
StdValue =  nanstd(Data) ; 
SHIFTED_Data = Data - MeanValue;
FirstDerivative =  [diff(SHIFTED_Data), NaN] ; 
SecondDerivative = [diff(FirstDerivative), NaN] ;
FirstCondition = InIntervals(Data ,[-StdValue MeanValue;MeanValue StdValue ]) ;%prctile(SHIFTED_Data,[85 , 100 ]) ) ; 
SecondCondition = zeros(size(FirstCondition));
ThirdCondition = zeros(size(FirstCondition));
SecondCondition =  FirstCondition & InIntervals(FirstDerivative , FirstDerivateWindow*[-1,1])  ; % prctile(FirstDerivative(FirstCondition),[0 , 75 ]) ) ; 
ThirdCondition =  FirstCondition & InIntervals(SecondDerivative , prctile(SecondDerivative(FirstCondition),[2.5 , 97.5 ])) ;
PUTATIVE_PAUSE_INDS = [ SecondCondition +  ThirdCondition ]==2;
if ~sum(PUTATIVE_PAUSE_INDS) ; 
    SecondCondition =  InIntervals(FirstDerivative , FirstDerivateWindow*[-1,1])  ; 
    FirstCondition = SecondCondition & InIntervals( Data, prctile(Data,[30,70 ]) ) ; 
    ThirdCondition =  FirstCondition & InIntervals(SecondDerivative , prctile(SecondDerivative(FirstCondition),[2.5 , 97.5 ])) ;
    PUTATIVE_PAUSE_INDS = [ SecondCondition +  ThirdCondition ]==2;
end

PUTATIVE_PAUSE_INDS(min(find(PUTATIVE_PAUSE_INDS))  : max(find(PUTATIVE_PAUSE_INDS))  )  =1;

if PlotFigure;
    clf;
    subplot(4,1,1);hold on;
    plot(t,Data,'b');hold on;
    plot(t(FirstCondition),Data(FirstCondition),'.y');hold on;
    line(xlim(),1*[ZERO_CROSS_THRESHOLD,ZERO_CROSS_THRESHOLD],'Color','r');
    line(xlim(),-1*[ZERO_CROSS_THRESHOLD,ZERO_CROSS_THRESHOLD],'Color','r');
    
    delete(subplot(4,1,2));subplot(4,1,2);;
    hold on ;
    plot(t,FirstDerivative);
    plot(t(FirstCondition),FirstDerivative(FirstCondition),'.y');
    plot(t(SecondCondition),FirstDerivative(SecondCondition),'.g');
    line(xlim(),FirstDerivateWindow*[-1,-1],'Color','r');
    line(xlim(),FirstDerivateWindow*[1,1],'Color','r');
    
    delete(subplot(4,1,3));subplot(4,1,3);;
    plot(t,SecondDerivative);hold on ;
    plot(t(FirstCondition),SecondDerivative(FirstCondition),'.y');
    plot(t(SecondCondition),SecondDerivative(SecondCondition),'.g');
    plot(t(ThirdCondition),SecondDerivative(ThirdCondition),'.r');
    delete(subplot(4,1,4));subplot(4,1,4);;
    plot(t,Data);hold on;
    plot(t(PUTATIVE_PAUSE_INDS),Data(PUTATIVE_PAUSE_INDS),'.g');hold on;
end;
    
clear FirstCondition  SecondCondition ThirdCondition  FourthCondition ; 
clear t MeanValue StdValue SHIFTED_Data;
clear FirstDerivative SecondDerivative  ; 
PUTATIVE_PAUSE_INDS(min(find(PUTATIVE_PAUSE_INDS==1)):max(find(PUTATIVE_PAUSE_INDS==1))) = 1 ;  
PUTATIVE_PAUSE_INDS = find(PUTATIVE_PAUSE_INDS) ; 


end