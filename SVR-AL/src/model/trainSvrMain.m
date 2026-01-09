function [modelMain, info] = trainSvrMain(Xtrain, ytrain, normModel, options)
%TRAINSVRMAIN Train the main RBF-SVR model with BayesOpt + 10-fold CV.
%
% Usage:
%   [modelMain, info] = trainSvrMain(Xtrain, ytrain, normModel, options)
%
% Notes:
% - Input Xtrain is in physical space; normalization is applied internally.
% - Hyperparameter tuning uses fitrsvm(...,'OptimizeHyperparameters','auto').

arguments
    Xtrain (:,:) double {mustBeFinite}
    ytrain (:,1) double {mustBeFinite}
    normModel (1,1) struct
    options (1,1) struct
end

if size(Xtrain, 1) ~= size(ytrain, 1)
    error("trainSvrMain:SizeMismatch", "Xtrain and ytrain must have same number of rows.");
end

Xz = applyNormForSvrTrain(Xtrain, normModel);

if ~isfield(options, "bayesoptMaxEvals")
    error("trainSvrMain:MissingOption", "options.bayesoptMaxEvals is required.");
end

hopts = struct();
hopts.KFold = 10;
hopts.MaxObjectiveEvaluations = double(options.bayesoptMaxEvals);
hopts.ShowPlots = false;
hopts.Verbose = 0;
hopts.UseParallel = false;

modelMain = fitrsvmCompat( ...
    Xz, ytrain, ...
    'KernelFunction', 'gaussian', ...
    'Standardize', false, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', hopts);

info = struct();
info.nTrain = size(Xtrain, 1);
info.bayesoptMaxEvals = hopts.MaxObjectiveEvaluations;
end
