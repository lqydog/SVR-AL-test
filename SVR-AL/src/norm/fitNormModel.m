function normModel = fitNormModel(Xtrain, lb, ub)
%FITNORMMODEL Fit the two-layer normalization model.
%
% Layer 1: physical -> [0,1]^d using lb/ub (for pool, distances, k-means).
% Layer 2: z-score using current training set statistics in [0,1]^d space.
%
% Usage:
%   normModel = fitNormModel(Xtrain, lb, ub)
%
% Returns:
%   normModel (struct): fields lb, ub, mu, sigma

validateattributes(Xtrain, {'numeric'}, {'2d','finite','nonempty'});
lb = lb(:).';
ub = ub(:).';
if size(Xtrain, 2) ~= numel(lb) || size(Xtrain, 2) ~= numel(ub)
    error("fitNormModel:DimMismatch", "Xtrain columns must match lb/ub length.");
end

X01 = applyMinMax01(Xtrain, lb, ub);
mu = mean(X01, 1);
sigma = std(X01, 0, 1);
sigma(sigma == 0) = 1;

normModel = struct('lb', lb, 'ub', ub, 'mu', mu, 'sigma', sigma);
end

