function [y_hat, m_hat] = nadaraya_watson(x,y,h,kern)
% Calculate the Nadaraya-Watson nonparametric kernel estimator for the
% relationship between two scalar variables related by 
%           y = m(x) + e
%   INPUTS
%       y: dep. var
%       x: indep. var
%       h: bandwidth for smoothing
%       kern: choice of kernel
%

% check arguments
if nargin < 4
    kern = 'epan';
end

% check dimensions
if size(x,1) > 1
    x = x';
end

if size(y,1) > 1
    y = y';
end

% estimator
m_hat = @(z) 1/h * kernel((z - x) /h, kern) * y' ./ sum(1/h * kernel((z - x) / h, kern));
y_hat = arrayfun(m_hat,x);

end