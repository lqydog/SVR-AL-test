function D = pdist2Compat(A, B)
%PDIST2COMPAT Pairwise Euclidean distances (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, calls pdist2(A,B).
% Otherwise computes Euclidean distances in pure MATLAB.

validateattributes(A, {'numeric'}, {'2d','finite'});
validateattributes(B, {'numeric'}, {'2d','finite'});
if size(A, 2) ~= size(B, 2)
    error("pdist2Compat:DimMismatch", "A and B must have same number of columns.");
end

if exist('pdist2', 'file') == 2
    D = pdist2(A, B);
    return;
end

AA = sum(A.^2, 2);
BB = sum(B.^2, 2).';
D2 = AA + BB - 2*(A*B.');
D2(D2 < 0) = 0;
D = sqrt(D2);
end

