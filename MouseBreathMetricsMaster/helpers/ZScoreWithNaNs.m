function [ZScore] = ZScoreWithNaNs(X, dim)
%% Performs z-score of each array speciefied by dim (if not default = 1);
% deals well with nans;
if ~exist('dim','var'); dim = 1; end;

ZScore = [X- nanmean(X,dim)] ./ nanstd(X,[],dim) ;


end

