function [Output] = ResortMap(Input,order,dim)
%% Resort matrix according to order of each dim;
if dim==1
    Output = Input(order,:);
else
    Output = Input(:, order);
end
    
end

