function g = gfun2d_analytic(X)
%GFUN2D_ANALYTIC 2D analytic limit-state function for validation.
%
% g(x1,x2) = sin(5*x1/2) + 2 - ((x1^2+4)*(x2-1))/20
%
% Usage:
%   g = gfun2d_analytic(X)
% where X is N-by-2 and g is N-by-1.

validateattributes(X, {'numeric'}, {'2d','ncols',2,'finite'});
x1 = X(:, 1);
x2 = X(:, 2);
g = sin(5 .* x1 ./ 2) + 2 - ((x1.^2 + 4) .* (x2 - 1)) ./ 20;
end

