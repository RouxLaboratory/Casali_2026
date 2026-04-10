function y = StError( varargin )
if nargin == 1
    x = varargin{1};
    dimension = 1 ;
elseif nargin == 2
    x = varargin{1};
    dimension = varargin{2};
end




if size(x,1)>1 & size(x,2)>1
y=  nanstd(x,1,dimension) ./sqrt(sum(~isnan(x),dimension))   ;
else    
y=  nanstd(x,1,dimension) ./sqrt(sum(~isnan(x),dimension))   ;  %% it was y = nanstd(x)/sqrt(sum(~isnan(x)));
end


end