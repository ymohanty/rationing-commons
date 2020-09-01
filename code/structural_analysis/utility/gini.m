function [ G ] = gini( x, excludeNegative )
%gini Calculate Gini coefficient of vector x
    
if nargin < 2
    excludeNegative = false;
end

N = length(x);
i = [1:N]';

if excludeNegative 
    x(x<0) = 0;
end
x    = sort(x,1,'ascend');
xRun = cumsum(x);
xTot = sum(x);

Lorenz = xRun / xTot;
Forty5 = i/N;
Gap    = Forty5 - Lorenz;

G = sum(Gap) / sum(Forty5);

end

