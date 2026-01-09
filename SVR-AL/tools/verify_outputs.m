function verify_outputs(mode, runTag)
%VERIFY_OUTPUTS Validate required artifacts in outputs/ for fast/full modes.
%
% Usage:
%   verify_outputs("fast", runTag)
%   verify_outputs("full", runTag)
%
% Checks:
% - Required demo artifacts exist for both A1 and Uboot runs
% - Required CI artifacts exist for the given mode (logs/results/report)
% - PNG files exist and are non-empty

mode = lower(string(mode));
runTag = string(runTag);

rootDir = fileparts(fileparts(mfilename('fullpath')));
outDir = fullfile(rootDir, 'outputs');
if ~isfolder(outDir)
    error("verify_outputs:MissingOutputsDir", "Missing outputs directory: %s", outDir);
end

% CI artifacts
logTxt = fullfile(outDir, "test_log_" + mode + ".txt");
resMat = fullfile(outDir, "test_results_" + mode + ".mat");
assertFileExists(logTxt);
assertFileExists(resMat);

if mode == "full"
    reportHtml = fullfile(outDir, "test_report_full.html");
    assertFileExists(reportHtml);
end

% Demo artifacts (both acquisition methods)
methods = ["A1", "Uboot"];
for m = 1:numel(methods)
    method = methods(m);
    assertFileExists(fullfile(outDir, "log_" + method + "_" + runTag + ".mat"));
    assertFileExists(fullfile(outDir, "model_final_" + method + "_" + runTag + ".mat"));

    pfPng = fullfile(outDir, "pf_curve_" + method + "_" + runTag + ".png");
    samplesPng = fullfile(outDir, "samples_lsf_" + method + "_" + runTag + ".png");
    assertNonEmptyFile(pfPng);
    assertNonEmptyFile(samplesPng);

    % Light sanity: log includes acqMethod field
    S = load(fullfile(outDir, "log_" + method + "_" + runTag + ".mat"));
    if ~isfield(S, "log") || ~isstruct(S.log) || ~isfield(S.log, "acqMethod")
        error("verify_outputs:BadLog", "Log file missing expected fields: %s", method);
    end
end
end

function assertFileExists(p)
if ~isfile(p)
    error("verify_outputs:MissingFile", "Missing required file: %s", p);
end
end

function assertNonEmptyFile(p)
assertFileExists(p);
info = dir(p);
if isempty(info) || info.bytes <= 0
    error("verify_outputs:EmptyFile", "File is empty: %s", p);
end
end

