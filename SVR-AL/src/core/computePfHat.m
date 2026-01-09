function pfHat = computePfHat(gHatPool)
%COMPUTEPFHAT Estimate failure probability on the entire pool.
%
% Usage:
%   pfHat = computePfHat(gHatPool)
%
% Definition:
%   pfHat = mean( gHatPool <= 0 )

validateattributes(gHatPool, {'numeric'}, {'vector','finite'});
pfHat = mean(gHatPool(:) <= 0);
end

