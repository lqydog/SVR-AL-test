function [idx, C] = kmeansCompat(X, k, varargin)
%KMEANSCOMPAT k-means clustering (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, calls kmeans.
% Otherwise runs a lightweight Lloyd algorithm with a few replicates.
%
% Supported name-value (fallback mode):
%   'Replicates' (default 1), 'MaxIter' (default 100)

validateattributes(X, {'numeric'}, {'2d','finite','nonempty'});
validateattributes(k, {'numeric'}, {'scalar','integer','>',0,'finite'});

if exist('kmeans', 'file') == 2
    [idx, C] = kmeans(X, k, varargin{:});
    return;
end

p = inputParser();
p.addParameter('Replicates', 1);
p.addParameter('MaxIter', 100);
p.parse(varargin{:});

reps = double(p.Results.Replicates);
maxIter = double(p.Results.MaxIter);

n = size(X, 1);
bestInertia = inf;
bestIdx = [];
bestC = [];

for r = 1:reps
    perm = randperm(n);
    C = X(perm(1:k), :);
    idx = ones(n, 1);

    for it = 1:maxIter
        D = pdist2Compat(X, C);
        [~, newIdx] = min(D, [], 2);
        if all(newIdx == idx)
            break;
        end
        idx = newIdx;
        for j = 1:k
            mask = (idx == j);
            if any(mask)
                C(j, :) = mean(X(mask, :), 1);
            else
                C(j, :) = X(randi(n), :);
            end
        end
    end

    D = pdist2Compat(X, C);
    inertia = sum(min(D.^2, [], 2));
    if inertia < bestInertia
        bestInertia = inertia;
        bestIdx = idx;
        bestC = C;
    end
end

idx = bestIdx;
C = bestC;
end

