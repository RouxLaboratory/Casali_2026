function [out] = RandomPosNegLogic(m, n)
%Logic +1/-1 generator;

out = rand(m,n);
out(out>=0.5) =1;
out(out<=0.5)= -1;
end

