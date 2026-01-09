function result = runActiveLearning(problem, options)
%RUNACTIVELEARNING Pool-based active learning loop for SVR surrogate.
%
% Usage:
%   result = runActiveLearning(problem, options)
%
% Inputs:
%   problem : struct with fields dists (1xd) and gfun (handle: NxD -> Nx1)
%   options : configuration struct (see src/config/defaultOptions.m)
%
% Outputs:
%   result  : struct with fields:
%     log, modelFinal

arguments
    problem (1,1) struct
    options (1,1) struct
end

requiredProblem = ["dists","gfun"];
for f = requiredProblem
    if ~isfield(problem, f)
        error("runActiveLearning:MissingProblemField", "problem.%s is required.", f);
    end
end

requiredOptions = ["alpha","Npool","N0","Nmax","acqMethod","eps_d","eps_sigma","bootstrapM","eta","Kconsec","bayesoptMaxEvals","rngSeed"];
for f = requiredOptions
    if ~isfield(options, f)
        error("runActiveLearning:MissingOption", "options.%s is required.", f);
    end
end

setRng(options.rngSeed);

[Xpool, poolMeta] = buildPoolTruncInvLhs(problem.dists, options.alpha, options.Npool);
Xpool01 = applyMinMax01(Xpool, poolMeta.lb, poolMeta.ub);

idxDoe = kmeansDoeFromPool(Xpool01, options.N0);
idxAll = idxDoe(:);
idxAl = zeros(0, 1);

Xtrain = Xpool(idxAll, :);
ytrain = problem.gfun(Xtrain);

pfHistory = zeros(0, 1);
scoreMinHistory = zeros(0, 1);
consecCount = 0;
scoreName = string(options.acqMethod);

poolAvailable = true(size(Xpool, 1), 1);
poolAvailable(idxAll) = false;

while true
    normModel = fitNormModel(Xtrain, poolMeta.lb, poolMeta.ub);

    modelMain = trainSvrMain(Xtrain, ytrain, normModel, options);
    bootstrap = trainBootstrapSigma(Xtrain, ytrain, normModel, modelMain, options);

    [gHatPool, sigmaPool] = predictMainAndSigmaOnPool(Xpool, normModel, modelMain, bootstrap);
    pfHistory(end+1, 1) = computePfHat(gHatPool); %#ok<AGROW>

    [stopFlag, consecCount] = stopCriteria(pfHistory, size(Xtrain, 1), options, consecCount);
    if stopFlag
        break;
    end

    Xtrain01 = Xpool01(idxAll, :);
    minDistPool = min(pdist2Compat(Xpool01, Xtrain01), [], 2);

    [idxNext, scoreMin, scoreName] = selectNextPoint(options.acqMethod, gHatPool, sigmaPool, minDistPool, poolAvailable, options);
    scoreMinHistory(end+1, 1) = scoreMin; %#ok<AGROW>

    idxAl(end+1, 1) = idxNext; %#ok<AGROW>
    idxAll(end+1, 1) = idxNext; %#ok<AGROW>
    poolAvailable(idxNext) = false;

    xNew = Xpool(idxNext, :);
    yNew = problem.gfun(xNew);
    Xtrain(end+1, :) = xNew; %#ok<AGROW>
    ytrain(end+1, 1) = yNew; %#ok<AGROW>
end

log = struct();
log.acqMethod = string(scoreName);
log.scoreName = string(scoreName);
log.scoreMinHistory = scoreMinHistory;
log.pfHistory = pfHistory;
log.idxDoe = idxDoe;
log.idxAl = idxAl;
log.idxAll = idxAll;
log.Xtrain = Xtrain;
log.ytrain = ytrain;
log.poolMeta = poolMeta;
log.options = options;

modelFinal = struct();
modelFinal.modelMain = modelMain;
modelFinal.normModel = normModel;
modelFinal.hyperparams = struct( ...
    'KernelScale', modelMain.KernelParameters.Scale, ...
    'Epsilon', modelMain.Epsilon, ...
    'BoxConstraint', modelMain.BoxConstraints(1));
modelFinal.Xtrain = Xtrain;
modelFinal.ytrain = ytrain;
modelFinal.options = options;

result = struct();
result.log = log;
result.modelFinal = modelFinal;
end
