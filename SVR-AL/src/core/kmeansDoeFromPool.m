function idxDoe = kmeansDoeFromPool(Xpool01, N0)
%KMEANSDOEFROMPOOL Select initial DOE points from pool using k-means.
%
% Usage:
%   idxDoe = kmeansDoeFromPool(Xpool01, N0)
%
% Inputs:
%   Xpool01 : Npool-by-d pool in [0,1]^d
%   N0      : number of DOE points (clusters)
%
% Output:
%   idxDoe  : N0-by-1 indices into Xpool01

validateattributes(Xpool01, {'numeric'}, {'2d','finite','nonempty'});
validateattributes(N0, {'numeric'}, {'scalar','integer','>',0,'finite'});

Npool = size(Xpool01, 1);
if N0 > Npool
    error("kmeansDoeFromPool:InvalidN0", "N0 must be <= Npool.");
end

% k-means in normalized space
[~, C] = kmeansCompat(Xpool01, N0, 'Replicates', 3, 'MaxIter', 200);

idxDoe = zeros(N0, 1);
used = false(Npool, 1);

for k = 1:N0
    d2 = pdist2Compat(C(k, :), Xpool01);
    [~, order] = sort(d2, 'ascend');
    picked = false;
    for t = 1:numel(order)
        idx = order(t);
        if ~used(idx)
            idxDoe(k) = idx;
            used(idx) = true;
            picked = true;
            break;
        end
    end
    if ~picked
        error("kmeansDoeFromPool:SelectionFailed", "Failed to pick a unique DOE point.");
    end
end

if numel(unique(idxDoe)) ~= N0
    error("kmeansDoeFromPool:NotUnique", "DOE indices are not unique.");
end
end
