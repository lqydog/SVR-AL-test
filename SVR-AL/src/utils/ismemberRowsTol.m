function tf = ismemberRowsTol(A, B, tol)
%ISMEMBERROWSTOL Row-wise membership test with tolerance.
%
% Usage:
%   tf = ismemberRowsTol(A, B, tol)
%
% Returns:
%   tf (logical): size(A,1)-by-1, true if row A(i,:) exists in B within tol.

if nargin < 3 || isempty(tol)
    tol = 0;
end

validateattributes(A, {'numeric'}, {'2d','finite'});
validateattributes(B, {'numeric'}, {'2d','finite'});
validateattributes(tol, {'numeric'}, {'scalar','nonnegative','finite'});

if size(A, 2) ~= size(B, 2)
    error("ismemberRowsTol:DimMismatch", "A and B must have same number of columns.");
end

if isempty(A)
    tf = false(0, 1);
    return;
end
if isempty(B)
    tf = false(size(A, 1), 1);
    return;
end

if tol == 0
    tf = ismember(A, B, 'rows');
    return;
end

tf = false(size(A, 1), 1);
for i = 1:size(A, 1)
    diffs = abs(B - A(i, :));
    tf(i) = any(all(diffs <= tol, 2));
end
end

