%DEMO2D_ANALYTIC End-to-end demo on the 2D analytic limit-state function.
%
% This script runs pool-based active learning twice under the same seed/DOE:
%   1) Acquisition A1
%   2) Acquisition Uboot
%
% Outputs (saved under outputs/):
%   pf_curve_<METHOD>_*.png
%   samples_lsf_<METHOD>_*.png
%   log_<METHOD>_*.mat
%   model_final_<METHOD>_*.mat
%
% Optional:
%   If a struct variable named `demoOptions` exists in the base workspace,
%   its fields override `defaultOptions()`.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(rootDir, 'src')));

outDir = fullfile(rootDir, 'outputs');
if ~isfolder(outDir)
    mkdir(outDir);
end

problem = make2dNormalProblem();
options = defaultOptions();

if exist('demoOptions', 'var') && isstruct(demoOptions)
    f = fieldnames(demoOptions);
    for k = 1:numel(f)
        options.(f{k}) = demoOptions.(f{k});
    end
end

if ~isfield(options, "runTag") || strlength(string(options.runTag)) == 0
    options.runTag = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
end

methods = ["A1", "Uboot"];
for m = 1:numel(methods)
    method = methods(m);

    runOptions = options;
    runOptions.acqMethod = method;

    setRng(runOptions.rngSeed);
    result = runActiveLearning(problem, runOptions);

    runTag = string(runOptions.runTag);
    methodTag = string(method);

    logPath = fullfile(outDir, "log_" + methodTag + "_" + runTag + ".mat");
    modelPath = fullfile(outDir, "model_final_" + methodTag + "_" + runTag + ".mat");
    save(logPath, '-struct', 'result', 'log');
    save(modelPath, '-struct', 'result', 'modelFinal');

    % Pf curve
    fig1 = figure('Visible', 'off');
    n0 = runOptions.N0;
    x = (n0:(n0 + numel(result.log.pfHistory) - 1)).';
    plot(x, result.log.pfHistory, '-o', 'LineWidth', 1.5);
    grid on;
    xlabel('Query count (training size)');
    ylabel('$\hat{P}_{f}$ (on pool)', 'Interpreter', 'latex');
    title("Pf Convergence (Acquisition: " + methodTag + ")");
    pfPng = fullfile(outDir, "pf_curve_" + methodTag + "_" + runTag + ".png");
    saveFigurePng(fig1, pfPng, 160);
    close(fig1);

    % Sample distribution + LSF contours (true vs surrogate)
    fig2 = figure('Visible', 'off');
    lb = result.log.poolMeta.lb;
    ub = result.log.poolMeta.ub;
    nGrid = 200;
    x1 = linspace(lb(1), ub(1), nGrid);
    x2 = linspace(lb(2), ub(2), nGrid);
    [X1, X2] = meshgrid(x1, x2);
    Xg = [X1(:), X2(:)];
    gTrue = gfun2d_analytic(Xg);
    gz = applyNormForSvrPredict(Xg, result.modelFinal.normModel);
    gPred = predictCompat(result.modelFinal.modelMain, gz);

    contour(X1, X2, reshape(gTrue, nGrid, nGrid), [0 0], 'k-', 'LineWidth', 1.5);
    hold on;
    contour(X1, X2, reshape(gPred, nGrid, nGrid), [0 0], 'r--', 'LineWidth', 1.5);

    Xdoe = result.log.Xtrain(1:runOptions.N0, :);
    scatter(Xdoe(:, 1), Xdoe(:, 2), 28, 'b', 'filled', 'DisplayName', 'DOE');
    if ~isempty(result.log.idxAl)
        Xal = result.log.Xtrain((runOptions.N0 + 1):end, :);
        scatter(Xal(:, 1), Xal(:, 2), 28, 'r', 'x', 'LineWidth', 1.2, 'DisplayName', 'AL');
    end

    legend('Location', 'best');
    xlabel('x_1');
    ylabel('x_2');
    title("Samples + LSF (Acquisition: " + methodTag + ")");
    grid on;
    axis tight;

    samplesPng = fullfile(outDir, "samples_lsf_" + methodTag + "_" + runTag + ".png");
    saveFigurePng(fig2, samplesPng, 160);
    close(fig2);
end
