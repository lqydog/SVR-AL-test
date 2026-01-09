function Xz = applyNormForSvrTrain(Xtrain, normModel)
%APPLYNORMFORSVRTRAIN Apply two-layer normalization for SVR training.
%
% Usage:
%   Xz = applyNormForSvrTrain(Xtrain, normModel)

X01 = applyMinMax01(Xtrain, normModel.lb, normModel.ub);
Xz = applyZScore(X01, normModel.mu, normModel.sigma);
end

