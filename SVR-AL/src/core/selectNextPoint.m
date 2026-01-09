function [idxNext, scoreMin, scoreName, score] = selectNextPoint(acqMethod, gHatPool, sigmaPool, minDistPool, poolAvailable, options)
%SELECTNEXTPOINT Select next sampling point from pool based on acquisition score.
%
% Usage:
%   [idxNext, scoreMin, scoreName] = selectNextPoint(acqMethod, gHatPool, sigmaPool, minDistPool, poolAvailable, options)
%
% Acquisition methods:
%   A1    : |gHat| / (d + eps_d)
%   Uboot : |gHat| / (sigma + eps_sigma)
%
% The selection rule is to minimize the score over available pool points.

acqMethod = string(acqMethod);

validateattributes(gHatPool, {'numeric'}, {'vector','finite'});
validateattributes(minDistPool, {'numeric'}, {'vector','finite','nonnegative'});
validateattributes(poolAvailable, {'logical'}, {'vector'});

gHatPool = gHatPool(:);
minDistPool = minDistPool(:);
poolAvailable = poolAvailable(:);

if numel(gHatPool) ~= numel(minDistPool) || numel(gHatPool) ~= numel(poolAvailable)
    error("selectNextPoint:SizeMismatch", "Inputs must have the same length.");
end

switch upper(acqMethod)
    case "A1"
        if ~isfield(options, "eps_d")
            error("selectNextPoint:MissingOption", "options.eps_d is required for A1.");
        end
        scoreName = "A1";
        score = abs(gHatPool) ./ (minDistPool + options.eps_d);
    case "UBOOT"
        if ~isfield(options, "eps_sigma")
            error("selectNextPoint:MissingOption", "options.eps_sigma is required for Uboot.");
        end
        validateattributes(sigmaPool, {'numeric'}, {'vector','finite','nonnegative'});
        sigmaPool = sigmaPool(:);
        if numel(sigmaPool) ~= numel(gHatPool)
            error("selectNextPoint:SizeMismatch", "sigmaPool must match gHatPool length.");
        end
        scoreName = "Uboot";
        score = abs(gHatPool) ./ (sigmaPool + options.eps_sigma);
    otherwise
        error("selectNextPoint:InvalidMethod", "Unknown acquisition method: %s", acqMethod);
end

score(~poolAvailable) = inf;

[scoreMin, idxNext] = min(score);
if ~isfinite(scoreMin)
    error("selectNextPoint:NoAvailablePoints", "No available pool point to select.");
end
end

