function setRng(seed)
%SETRNG Set MATLAB RNG for reproducible runs.
%
% Usage:
%   setRng(seed)

if nargin < 1 || isempty(seed)
    return;
end

validateattributes(seed, {'numeric'}, {'scalar','integer','finite'});
rng(double(seed), 'twister');
end

