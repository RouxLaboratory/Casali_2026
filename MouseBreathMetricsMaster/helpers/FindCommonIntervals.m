function int3 = FindCommonIntervals(OrigInt1, OrigInt2)
%% Function written by GC;
%The idea is to find common intervals of both lists
int3 = [];

% if ~isempty(OrigInt1) & ~isempty(OrigInt2)
% [~,which ] = ExcludeIntervals(OrigInt1,OrigInt2);
% OrigInt1(which,:) = [];
% end
% if ~isempty(OrigInt1) & ~isempty(OrigInt2)
% [l,r] =RangeIntersection(OrigInt1(:,1),OrigInt1(:,2),OrigInt2(:,1),OrigInt2(:,2) ) ;
% int3 = [l(:),r(:)];
% end


if ~isempty(OrigInt1) & ~isempty(OrigInt2)
temp = SubtractIntervals(OrigInt1,OrigInt2) ;
int3 = SubtractIntervals(OrigInt1,temp) ;
end
end

