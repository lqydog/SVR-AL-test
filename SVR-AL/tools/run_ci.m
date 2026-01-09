function run_ci(mode)
%RUN_CI Unified local CI entrypoint for Codex/Windows.
%
% Usage:
%   run_ci("fast")
%   run_ci("full")
%
% Behavior:
% - Adds src/ to path
% - Ensures outputs/ exists
% - Runs tests
% - Runs 2D demo (A1 + Uboot, same seed/DOE)
% - Verifies outputs
% - Persists logs/results/reports under outputs/
% - Exits with code 0 on success, 1 on failure

if nargin < 1 || strlength(string(mode)) == 0
    mode = "fast";
end
mode = lower(string(mode));

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(rootDir, 'src')));
addpath(fullfile(rootDir, 'tools'));

outDir = fullfile(rootDir, 'outputs');
if ~isfolder(outDir)
    mkdir(outDir);
end

runTag = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
runTag = mode + "_" + runTag;

exitCode = 1;
tStart = tic;

logPath = fullfile(outDir, "test_log_" + mode + ".txt");
if isfile(logPath)
    delete(logPath);
end
diary(logPath);
diary on;
cleanupDiary = onCleanup(@() diary('off')); %#ok<NASGU>

try
    % Demo options (script reads demoOptions if present)
    demoOptions = struct();
    demoOptions.runTag = runTag;

    if mode == "fast"
        demoOptions.Npool = 5000;
        demoOptions.N0 = 10;
        demoOptions.Nmax = 30;
        demoOptions.bayesoptMaxEvals = 10;
        demoOptions.rngSeed = 42;
    elseif mode == "full"
        % Full uses defaultOptions() except runTag (do not shrink defaults here)
        demoOptions = struct('runTag', runTag);
    else
        error("run_ci:InvalidMode", "Mode must be ""fast"" or ""full"".");
    end

    % Run tests
    if mode == "full"
        results = runTestsFull(rootDir, outDir);
        writeSimpleHtmlReport(fullfile(outDir, "test_report_full.html"), results);
    else
        results = runtests(fullfile(rootDir, 'tests'));
    end

    disp(results);
    assert(all([results.Passed]), "Some tests failed.");

    resultsPath = fullfile(outDir, "test_results_" + mode + ".mat");
    if isfile(resultsPath)
        delete(resultsPath);
    end
    save(resultsPath, "results");

    % Run demo (A1 + Uboot)
    run(fullfile(rootDir, 'scripts', 'demo2d_analytic.m'));

    % Verify artifacts
    verify_outputs(mode, runTag);

    exitCode = 0;
catch ME
    disp(getReport(ME, 'extended'));
    exitCode = 1;
end

elapsedSec = toc(tStart);
appendAcceptanceSummary(outDir, mode, runTag, exitCode, elapsedSec);

exit(exitCode);
end

function results = runTestsFull(rootDir, outDir)
import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.XMLPlugin

suite = TestSuite.fromFolder(fullfile(rootDir, 'tests'), 'IncludingSubfolders', true);
runner = TestRunner.withTextOutput('Verbosity', 2);

try
    junitPath = fullfile(outDir, 'junit_full.xml');
    runner.addPlugin(XMLPlugin.producingJUnitFormat(junitPath));
catch
    % Optional
end

results = runner.run(suite);
end

function writeSimpleHtmlReport(pathHtml, results)
nTotal = numel(results);
nPassed = sum([results.Passed]);
nFailed = nTotal - nPassed;

fid = fopen(pathHtml, 'w');
if fid < 0
    error("run_ci:ReportWriteFailed", "Cannot write report: %s", pathHtml);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '<!doctype html><html><head><meta charset="utf-8"><title>Test Report</title></head><body>\n');
fprintf(fid, '<h1>MATLAB Test Report (Full)</h1>\n');
fprintf(fid, '<p>Total: %d, Passed: %d, Failed: %d</p>\n', nTotal, nPassed, nFailed);
fprintf(fid, '<ul>\n');
for i = 1:nTotal
    fprintf(fid, '<li>%s : %s</li>\n', results(i).Name, ternary(results(i).Passed, "PASS", "FAIL"));
end
fprintf(fid, '</ul>\n');
fprintf(fid, '</body></html>\n');
end

function s = ternary(cond, a, b)
if cond
    s = a;
else
    s = b;
end
end

function appendAcceptanceSummary(outDir, mode, runTag, exitCode, elapsedSec)
pathMd = fullfile(outDir, 'acceptance_summary.md');
ts = char(datetime('now'));

fid = fopen(pathMd, 'a');
if fid < 0
    warning("run_ci:AcceptanceWriteFailed", "Cannot write acceptance summary: %s", pathMd);
    return;
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, "## CI Run: %s (%s)\n\n", upper(mode), ts);
fprintf(fid, "- Run tag: `%s`\n", runTag);
fprintf(fid, "- Exit code: `%d`\n", exitCode);
fprintf(fid, "- Elapsed: `%.2f s`\n", elapsedSec);
fprintf(fid, "- Key outputs (this run tag):\n");
fprintf(fid, "  - `pf_curve_A1_%s.png`\n", runTag);
fprintf(fid, "  - `pf_curve_Uboot_%s.png`\n", runTag);
fprintf(fid, "  - `samples_lsf_A1_%s.png`\n", runTag);
fprintf(fid, "  - `samples_lsf_Uboot_%s.png`\n", runTag);
fprintf(fid, "  - `log_A1_%s.mat`\n", runTag);
fprintf(fid, "  - `log_Uboot_%s.mat`\n", runTag);
fprintf(fid, "  - `model_final_A1_%s.mat`\n", runTag);
fprintf(fid, "  - `model_final_Uboot_%s.mat`\n\n", runTag);
end
