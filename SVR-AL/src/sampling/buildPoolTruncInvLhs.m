function [Xpool, meta] = buildPoolTruncInvLhs(dists, alpha, Npool)
%BUILDPOOLTRUNCINVLHS Build fixed candidate pool via truncated inverse CDF + LHS.
%
% Usage:
%   [Xpool, meta] = buildPoolTruncInvLhs(dists, alpha, Npool)
%
% Inputs:
%   dists : 1-by-d array of probability distribution objects supporting icdf.
%   alpha : total tail probability mass outside the augmented interval (0<alpha<1)
%   Npool : number of pool points
%
% Outputs:
%   Xpool : Npool-by-d pool points (physical space)
%   meta  : struct with fields pmin, pmax, lb, ub

if isempty(dists)
    error("buildPoolTruncInvLhs:EmptyDists", "dists must be non-empty.");
end

validateattributes(alpha, {'numeric'}, {'scalar','>',0,'<',1,'finite'});
validateattributes(Npool, {'numeric'}, {'scalar','integer','>',0,'finite'});

d = numel(dists);
pmin = alpha / 2;
pmax = 1 - alpha / 2;

lb = zeros(1, d);
ub = zeros(1, d);
for j = 1:d
    lb(j) = icdfCompat(dists(j), pmin);
    ub(j) = icdfCompat(dists(j), pmax);
end

R = lhsdesignCompat(Npool, d);
U = pmin + (pmax - pmin) .* R;

Xpool = zeros(Npool, d);
for j = 1:d
    Xpool(:, j) = icdfCompat(dists(j), U(:, j));
end

if any(~isfinite(Xpool), 'all')
    error("buildPoolTruncInvLhs:NonFinite", "Xpool contains non-finite values.");
end

meta = struct();
meta.pmin = pmin;
meta.pmax = pmax;
meta.lb = lb;
meta.ub = ub;
end
