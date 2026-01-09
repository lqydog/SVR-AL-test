function R = lhsdesignCompat(N, d)
%LHSDESIGNCOMPAT Latin hypercube sampling (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, calls lhsdesign.
% Otherwise uses a simple Latin hypercube implementation.
%
% Output:
%   R : N-by-d, in (0,1)

validateattributes(N, {'numeric'}, {'scalar','integer','>',0,'finite'});
validateattributes(d, {'numeric'}, {'scalar','integer','>',0,'finite'});

if exist('lhsdesign', 'file') == 2
    R = lhsdesign(N, d, 'criterion', 'maximin', 'iterations', 30);
    return;
end

R = zeros(N, d);
edges = (0:N)' ./ N;
for j = 1:d
    u = rand(N, 1);
    pts = edges(1:end-1) + (edges(2:end) - edges(1:end-1)) .* u;
    R(:, j) = pts(randperm(N));
end
end

