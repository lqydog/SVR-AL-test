function dist = makedistCompat(name, varargin)
%MAKEDISTCOMPAT Create a distribution object (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, calls makedist.
% Otherwise, supports:
%   - Normal distribution: makedistCompat('Normal','mu',mu,'sigma',sigma)
%
% Returns:
%   dist: toolbox distribution object OR a lightweight struct.

if exist('makedist', 'file') == 2
    dist = makedist(name, varargin{:});
    return;
end

name = string(name);
if lower(name) ~= "normal"
    error("makedistCompat:Unsupported", "Only Normal is supported without toolbox.");
end

p = inputParser();
p.addParameter('mu', 0);
p.addParameter('sigma', 1);
p.parse(varargin{:});

mu = double(p.Results.mu);
sigma = double(p.Results.sigma);
if ~(isfinite(mu) && isfinite(sigma) && sigma > 0)
    error("makedistCompat:InvalidParams", "Normal(mu,sigma) requires finite mu and sigma>0.");
end

dist = struct();
dist.Name = 'Normal';
dist.mu = mu;
dist.sigma = sigma;
end

