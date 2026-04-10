function [Out] = CircShiftAlongEachColumn(In,k)
%% Similar to circshift but each column is independent from each other in the k shift;
if size(In,2) ~= numel(k); 
    In = repmat(In,1,numel(k));  
end
Out = In;

for iK = 1: numel(k)
    Out(:,iK) = circshift(Out(:,iK),k(iK));
end

end

