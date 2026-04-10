function Extremes = FindConsecutiveData(X)

if ~isempty(X)

X_starts(1) = X(1);


X_ends = X(find(diff(X)~= 1));


X_starts =[X_starts  X(find(diff(X)~= 1)+1) ];


X_ends = [X_ends X(end) ] ;




Extremes = [X_starts' X_ends'] ;

else
    
    
Extremes = [];
end



end