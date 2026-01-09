function [gHat, sigmaHat] = predictMainAndSigmaOnPool(Xpool, normModel, modelMain, bootstrap)
%PREDICTMAINANDSIGMAONPOOL Predict g(x) with main model and sigma(x) via bootstrap.
%
% Usage:
%   [gHat, sigmaHat] = predictMainAndSigmaOnPool(Xpool, normModel, modelMain, bootstrap)

arguments
    Xpool (:,:) double {mustBeFinite}
    normModel (1,1) struct
    modelMain
    bootstrap (1,1) struct
end

XzPool = applyNormForSvrPredict(Xpool, normModel);
gHat = predictCompat(modelMain, XzPool);

M = bootstrap.M;
nPool = size(Xpool, 1);
preds = zeros(nPool, M);
for m = 1:M
    preds(:, m) = predictCompat(bootstrap.models{m}, XzPool);
end
sigmaHat = std(preds, 0, 2);
end
