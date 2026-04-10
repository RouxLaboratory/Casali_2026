function [ Bins ] = EqualBinning( Extremes , Bin )
%% Function written by GC (g.casali@ucl.ac.uk, giulio.casali.pro@gmail.com)
% Useful to create in one line an array of bins with the name of the center
% of the bin
% Input:
% 1) Extremes (first and last)
% 2) Bin : size of the bins;

% Output
%Bins = center of the bins;

% example of usage:
%[ Bins ] = EqualBinning( [0,10] ,[2] )
%Bins = [ 1     3     5     7     9  ];

 Bins = [min(Extremes)+Bin/2 : Bin : max(Extremes) ] ; 

end

