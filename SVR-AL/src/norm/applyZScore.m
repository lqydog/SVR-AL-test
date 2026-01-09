function Z = applyZScore(X, mu, sigma)
%APPLYZSCORE Apply z-score standardization using provided mu/sigma.
%
% Usage:
%   Z = applyZScore(X, mu, sigma)

validateattributes(X, {'numeric'}, {'2d','finite'});
mu = mu(:).';
sigma = sigma(:).';
if size(X, 2) ~= numel(mu) || size(X, 2) ~= numel(sigma)
    error("applyZScore:DimMismatch", "X columns must match mu/sigma length.");
end

sigmaSafe = sigma;
sigmaSafe(sigmaSafe == 0) = 1;
Z = (X - mu) ./ sigmaSafe;
end

