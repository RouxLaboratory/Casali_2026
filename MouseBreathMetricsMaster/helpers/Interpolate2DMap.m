function Output = Interpolate2DMap(Input , IncludeBW)
%% Function written by GC to interpolate NaN in a 2D map.
% It is useful when you need to fill the unvisited bins
% before running the SAC of a ratemap for instance.
% Importantly, it interpolates only the bins in the centre of the 2D map, not at the extremes.
if ~exist('IncludeBW','var') 
    IncludeBW =false;
end

nanMask = isnan(Input);%subplot(3,1,1);imagesc(nanMask);
BW = bwperim(Input);%;subplot(3,1,2);imagesc(BW);
if IncludeBW
    BW(:)=false;
end
nanMask = nanMask & ~BW; %subplot(3,1,3);imagesc(nanMask);


[r, c] = find(~nanMask);
[rNan, cNan] = find(nanMask);
F = scatteredInterpolant(c, r, Input(~nanMask), 'nearest');
interpVals = F(cNan, rNan);
Output = Input;
if isempty(interpVals);interpVals=NaN;end


Output(nanMask) = interpVals;
end