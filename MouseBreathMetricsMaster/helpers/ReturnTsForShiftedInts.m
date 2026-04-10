function [Restricted, Shifted, FixTs,WhichInt] = ReturnTsForShiftedInts(Data,int);
%% function written by GC
% returns the original links from the Restricted(X,int,'shift','on');
InInt= InIntervals(Data(:,1),int);
X = Restrict(Data,int) ;
[~,WhichInt] = InIntervals(X,int) ;
%r = [ Restrict([ X]'  ,[int],'shift','on') , Restrict([X]'  ,[int],'shift','off') ]
dt = cumsum([0;   diff(int,[],2)]) ;
InInt= InIntervals(X(:,1),int);
Restricted = Restrict([ X(:,1)]  ,[int],'shift','off');
Shifted = Restrict([ X(:,1)]  ,[int],'shift','on');

FixTs = ...int(WhichInt,1) - dt(WhichInt) ;
Restricted(:,1) -Shifted(:,1);
Restricted(:,2) = Data(InInt,2);
Shifted(:,2) = Data(InInt,2);


%Original = Shifted + FixTs ;
% if ~isequal( Data ,Y);
%     
% end
end

