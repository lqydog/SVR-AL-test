function [stopFlag, consecCount, relChange] = stopCriteria(pfHistory, nTrain, options, consecCount)
%STOPCRITERIA Determine whether to stop active learning.
%
% Usage:
%   [stopFlag, consecCount, relChange] = stopCriteria(pfHistory, nTrain, options, consecCount)
%
% Stop when:
%   - nTrain reaches Nmax, OR
%   - Pf relative change < eta for Kconsec consecutive iterations.

arguments
    pfHistory (:,1) double {mustBeFinite}
    nTrain (1,1) double {mustBeInteger,mustBeFinite,mustBeNonnegative}
    options (1,1) struct
    consecCount (1,1) double {mustBeInteger,mustBeFinite,mustBeNonnegative} = 0
end

if ~isfield(options, "Nmax") || ~isfield(options, "eta") || ~isfield(options, "Kconsec")
    error("stopCriteria:MissingOption", "options must include Nmax, eta, Kconsec.");
end

stopFlag = false;
relChange = NaN;

if nTrain >= options.Nmax
    stopFlag = true;
    return;
end

if numel(pfHistory) < 2
    return;
end

prev = pfHistory(end-1);
curr = pfHistory(end);
relChange = abs(curr - prev) / max(prev, 1e-6);

if relChange < options.eta
    consecCount = consecCount + 1;
else
    consecCount = 0;
end

if consecCount >= options.Kconsec
    stopFlag = true;
end
end

