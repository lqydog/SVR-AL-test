function X01 = applyMinMax01(X, lb, ub)
%APPLYMINMAX01 Map physical-space samples to [0,1]^d using bounds.
%
% Usage:
%   X01 = applyMinMax01(X, lb, ub)

validateattributes(X, {'numeric'}, {'2d','finite'});
lb = lb(:).';
ub = ub(:).';
if size(X, 2) ~= numel(lb) || size(X, 2) ~= numel(ub)
    error("applyMinMax01:DimMismatch", "X columns must match lb/ub length.");
end

den = (ub - lb);
if any(den <= 0)
    error("applyMinMax01:InvalidBounds", "All ub-lb must be positive.");
end

X01 = (X - lb) ./ den;
end

