function k = kernel(x,type)
% Return the kernel evaluated at x
% A kernel is a non-negative function that is symmetric around zero and
% integrates to unity.
if nargin < 2
    type = 'epan';
end

switch type
    case 'unif'
        k = 1/2 * (abs(x) <= 1);
    case 'epan'
        k = 3/4 * (1 - x.^2) .* (abs(x) <= 1);
    case 'triangular'
        k = (1 - abs(x)) .* (abs(x) <= 1);
    case 'normal'
        k = 1/sqrt(2*pi) .* exp(-1/2 .* x.^2);
end

end