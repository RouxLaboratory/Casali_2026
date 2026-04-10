function [ NewData ] = InterpolateVector(X, OldData,NewX,Type )


%% Function written by GC (g.casali@ucl.ac.uk, giulio.casali.pro@gmail.com)

%Wrapper function written by GC to interpolate each row of Data file
%initially mapped along the X row, so that each row in NewDataFile is
%linearly (default) interpolated along the NewX row;

%% Inputs:
% X = timebins of original array to resample (it should not include NaNs but the function will deal with it later on...; 
% OldData = values of original array to resample (it should not include
% NaNs but the function will deal with it later on...; Note that this can
% be ALSO a matrix, in which case the resampling will occur for each ROW.

% NewX = timebins of new array 
%Type: this is not necessary, the default is a linear resampling but other
%methods can be used from  "edit griddedInterpolant" such as: "nearest",
%"cubic", "pchip" ecc...

%% Outputs: 
%1) New Data: the resampled values for each row of OldData;

%% IMPORTANT: in case the NewX has a higher sampling rate, this function has been written to account for ONLY
% data points "within" windows with KNOWN values, everything before and/or
% after is SET to NaN to avoid weird results of linear interpolations;
% potentially this can be avoided by commenting lines 47-53 but data must
% then be treated with extra care.


%% Usage...
%    clf;
%    t = reshape(EqualBinning([0,10],0.1),1,[]);
%    OldData = t + rand(size(t));
%    NewT = EqualBinning([0,10],0.001);
%    [ NewData ] =  InterpolateVector(t, OldData, NewT,'linear' );
%     plot(t,OldData,'.');
%     hold on;    
%     plot(NewT,NewData,'r');

if ~exist('Type') ; Type = 'linear'; end ; 
X = reshape(X,1,[]);
Data = reshape(OldData,[],size(X,2));
NewData = NaN(size(Data,1), length(NewX) );
for iRow = 1 : size(Data,1)
    Valid = ~isnan(Data(iRow,:)) & ~isnan(X) ;
    
    if sum(Valid)>1
        F = griddedInterpolant(X(Valid),Data(iRow,Valid) , Type);
        tmp = F(NewX);
        [~,iStart]= min( abs( [NewX- min(X(Valid))]));
        [~,iEnd]= min( abs( [NewX- max(X(Valid))]));
        NewData(iRow,iStart : iEnd) = tmp(iStart :iEnd);
        clear tmp NewValid Valid;
    end;
end

end

