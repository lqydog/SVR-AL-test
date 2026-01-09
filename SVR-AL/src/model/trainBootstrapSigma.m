function bootstrap = trainBootstrapSigma(Xtrain, ytrain, normModel, modelMain, options)
%TRAINBOOTSTRAPSIGMA Train bootstrap SVR sub-models to estimate sigma(x).
%
% Usage:
%   bootstrap = trainBootstrapSigma(Xtrain, ytrain, normModel, modelMain, options)
%
% Notes:
% - Sub-models reuse main model hyperparameters (no BayesOpt) for speed.
% - sigma(x) is computed from the std of bootstrap predictions.

arguments
    Xtrain (:,:) double {mustBeFinite}
    ytrain (:,1) double {mustBeFinite}
    normModel (1,1) struct
    modelMain
    options (1,1) struct
end

if ~isfield(options, "bootstrapM")
    error("trainBootstrapSigma:MissingOption", "options.bootstrapM is required.");
end

M = double(options.bootstrapM);
validateattributes(M, {'double'}, {'scalar','integer','>',0,'finite'});

kernelScale = modelMain.KernelParameters.Scale;
epsilon = modelMain.Epsilon;
box = modelMain.BoxConstraints(1);

Xz = applyNormForSvrTrain(Xtrain, normModel);
n = size(Xz, 1);

models = cell(M, 1);
for m = 1:M
    idx = randi(n, n, 1);
    Xm = Xz(idx, :);
    ym = ytrain(idx, :);
    models{m} = fitrsvmCompat( ...
        Xm, ym, ...
        'KernelFunction', 'gaussian', ...
        'Standardize', false, ...
        'KernelScale', kernelScale, ...
        'Epsilon', epsilon, ...
        'BoxConstraint', box);
end

bootstrap = struct();
bootstrap.M = M;
bootstrap.kernelScale = kernelScale;
bootstrap.epsilon = epsilon;
bootstrap.box = box;
bootstrap.models = models;
end
