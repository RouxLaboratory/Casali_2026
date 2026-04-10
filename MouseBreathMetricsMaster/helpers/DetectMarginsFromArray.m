function [ Boundaries ,BoundariesXs] = DetectMarginsFromArray( x , indices )
% Function written by GC to detect discontinuity in the array.

Boundaries = [];
BoundariesXs =[];

x = reshape(x,1,[]);
indices = reshape(indices,1,[]);

t = 1 : numel(x);
y = diff(indices); y(end+1) = NaN;

a = y>1 ;
a_indices = find(a==1) +1;


b_indices = (find(y>1));

%% PLOT
% clf; 
% subplot(3,1,1);
% plot(t,x,'k');
% hold on ;
% plot(t(indices),x(indices),'r.');
% xlim([0 400]);
% 
% subplot(3,1,2);
% plot(t(indices),y>1);
% subplot(3,1,3);
% plot(t,x,'k');
% hold on ;
% plot(t(indices(a_indices)),x(indices(a_indices)),'g.');
% plot(t(indices(b_indices)),x(indices(b_indices)),'r.');
% xlim([0 400]);


Boundaries = FindConsecutiveData(t(indices));
BoundariesXs =x(Boundaries);

% Entries = indices(a_indices);
% Exits = indices(b_indices) ; 
% 
% if ismember(t(1),indices)
% Entries = [t(1)  Entries] ;
% end
% 
% if ismember(t(end),indices)
% Exits = [ Exits t(end) ] ;
% end
% 
% if numel(Entries)==numel(Exits)    
%         if Entries(1) > Exits(1)
%             Entries = [Exits(1) Entries];
%         end   
% end
% 
% if numel(Entries) > numel(Exits)
%     
%     if Entries(end) > Exits(end)
%         Exits(end+1) = Entries(end);
%     end
% 
% end
% Entries = reshape(Entries,[],1) ;
% Exits = reshape(Exits,[],1);
% 
% Boundaries = [ Entries  Exits] ;


end

