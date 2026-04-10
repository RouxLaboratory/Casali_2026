function [ Y , y ] = GetValueFromIndex( X , index );

%% Function written by GC (g.casali@ucl.ac.uk, giulio.casali.pro@gmail.com)
% Useful for instances where x(index) cannot be performed so I created a
% function which can do this to avoid error; 
% Input: 
%1) X : the full array...
%2) index : the indices of the array X to take...

% Output
%Y  = X(index);
%y = logical for X(index);


index = RemoveNaNsFromVector(index) ; 
Y = X(index) ;
y = [zeros(size(X))];
y(index) = 1;
end

