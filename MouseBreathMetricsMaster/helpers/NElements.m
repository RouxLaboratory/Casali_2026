function [ n ] = NElements( x )
% Determine the number of n elements different from NaN;

n = sum(~isnan(x)) ;


end
