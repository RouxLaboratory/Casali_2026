function Out= CorrectAccOffset(in,  Fs,swSize)
Fs = 1250;
swSize = 60;
% first remove any global linear trend in data;
DeTrendedIn = detrend(in);

%find mean detrended
%Out1 = DeTrendedIn - nanmean(DeTrendedIn);
srateCorrectedSW = floor(Fs * swSize);
for iColumn= 1: size(in,2)
SlidingMean(:,iColumn)=fftSmooth(DeTrendedIn(:,iColumn), srateCorrectedSW);
end
Out = DeTrendedIn - SlidingMean;
end

            
            