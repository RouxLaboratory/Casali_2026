function [ Output ] = RemoveNaNsFromVector( Input );
%% Function written by GC (g.casali@ucl.ac.uk, giulio.casali.pro@gmail.com)
%% sometimes it is useful to remove NaNs from a vector in a single line;
%Deletes NANs from an vector...

Output = Input(~isnan(Input));

end