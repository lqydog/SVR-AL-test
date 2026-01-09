function assertNoDuplicates(X, tol)
%ASSERTNODUPLICATES Error if X contains duplicate rows (within tolerance).
%
% Usage:
%   assertNoDuplicates(X)
%   assertNoDuplicates(X, tol)

if nargin < 2 || isempty(tol)
    tol = 0;
end

validateattributes(X, {'numeric'}, {'2d','finite'});
validateattributes(tol, {'numeric'}, {'scalar','nonnegative','finite'});

if isempty(X)
    return;
end

if tol == 0
    [~, ia] = unique(X, 'rows', 'stable');
    if numel(ia) ~= size(X, 1)
        error("assertNoDuplicates:Duplicates", "Duplicate rows found.");
    end
    return;
end

scale = 1 / tol;
Xq = round(X .* scale) ./ scale;
[~, ia] = unique(Xq, 'rows', 'stable');
if numel(ia) ~= size(Xq, 1)
    error("assertNoDuplicates:DuplicatesTol", "Duplicate rows found within tolerance %.3g.", tol);
end
end

