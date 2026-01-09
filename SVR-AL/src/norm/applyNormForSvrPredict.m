function Xz = applyNormForSvrPredict(X, normModel)
%APPLYNORMFORSVRPREDICT Apply two-layer normalization for SVR prediction.
%
% Usage:
%   Xz = applyNormForSvrPredict(X, normModel)

X01 = applyMinMax01(X, normModel.lb, normModel.ub);
Xz = applyZScore(X01, normModel.mu, normModel.sigma);
end

