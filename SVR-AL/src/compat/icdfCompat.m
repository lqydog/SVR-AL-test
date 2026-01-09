function x = icdfCompat(dist, p)
%ICDFCOMPAT Inverse CDF (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, uses icdf(dist,p).
% Otherwise supports Normal distribution structs from makedistCompat.

validateattributes(p, {'numeric'}, {'real','>=',0,'<=',1,'finite'});

if exist('icdf', 'file') == 2
    x = icdf(dist, p);
    return;
end

if isstruct(dist) && isfield(dist, 'Name') && strcmpi(dist.Name, 'Normal')
    mu = dist.mu;
    sigma = dist.sigma;
    % Normal inverse CDF via erfinv
    x = mu + sigma .* sqrt(2) .* erfinv(2 .* p - 1);
    return;
end

error("icdfCompat:Unsupported", "Unsupported dist type without toolbox.");
end

