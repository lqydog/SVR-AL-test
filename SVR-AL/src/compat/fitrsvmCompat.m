function model = fitrsvmCompat(X, y, varargin)
%FITRSVMCOMPAT SVR training (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, calls fitrsvm.
% Otherwise trains a lightweight RBF kernel regressor (LS-SVR / KRR style)
% with optional random-search hyperparameter tuning using K-fold CV.
%
% Supported name-value pairs (fallback mode):
%   'KernelFunction' ('gaussian' only)
%   'KernelScale' (positive scalar)
%   'BoxConstraint' (positive scalar)
%   'Epsilon' (stored for compatibility; not used in LS-SVR solve)
%   'OptimizeHyperparameters' ('auto' triggers tuning)
%   'HyperparameterOptimizationOptions' (struct with KFold, MaxObjectiveEvaluations)

validateattributes(X, {'numeric'}, {'2d','finite','nonempty'});
validateattributes(y, {'numeric'}, {'column','finite'});
if size(X, 1) ~= size(y, 1)
    error("fitrsvmCompat:SizeMismatch", "X and y must have the same number of rows.");
end

if exist('fitrsvm', 'file') == 2
    model = fitrsvm(X, y, varargin{:});
    return;
end

% Parse options
kernelFunction = 'gaussian';
kernelScale = 1.0;
boxConstraint = 1.0;
epsilon = 0.1;
doOptimize = false;
hopts = struct('KFold', 10, 'MaxObjectiveEvaluations', 20);

v = varargin;
i = 1;
while i <= numel(v)
    key = string(v{i});
    val = v{i+1};
    switch lower(key)
        case "kernelfunction"
            kernelFunction = char(val);
        case "kernelscale"
            kernelScale = double(val);
        case "boxconstraint"
            boxConstraint = double(val);
        case "epsilon"
            epsilon = double(val);
        case "optimizehyperparameters"
            doOptimize = strcmpi(string(val), "auto");
        case "hyperparameteroptimizationoptions"
            hoptsIn = val;
            if isstruct(hoptsIn)
                hopts = mergeStruct(hopts, hoptsIn);
            end
        otherwise
            % Ignore unsupported parameters in fallback mode (e.g., Standardize)
    end
    i = i + 2;
end

if ~strcmpi(kernelFunction, 'gaussian')
    error("fitrsvmCompat:UnsupportedKernel", "Only gaussian kernel is supported.");
end

if doOptimize
    [kernelScale, boxConstraint] = tuneHyperparams(X, y, hopts);
end

model = trainLSSVR(X, y, kernelScale, boxConstraint, epsilon);
end

function S = mergeStruct(S, T)
f = fieldnames(T);
for k = 1:numel(f)
    S.(f{k}) = T.(f{k});
end
end

function [bestScale, bestBox] = tuneHyperparams(X, y, hopts)
K = hopts.KFold;
maxEvals = hopts.MaxObjectiveEvaluations;
K = min(double(K), size(X, 1));
maxEvals = max(1, double(maxEvals));

bestLoss = inf;
bestScale = 1.0;
bestBox = 1.0;

perm = randperm(size(X, 1));
foldId = mod((0:(numel(perm)-1)), K) + 1;
foldId(perm) = foldId;

for t = 1:maxEvals
    scale = 10^(randUniform(log10(0.1), log10(10)));
    box = 10^(randUniform(log10(0.1), log10(1000)));
    loss = kfoldMSE(X, y, foldId, K, scale, box);
    if loss < bestLoss
        bestLoss = loss;
        bestScale = scale;
        bestBox = box;
    end
end
end

function u = randUniform(a, b)
u = a + (b - a) * rand();
end

function mse = kfoldMSE(X, y, foldId, K, scale, box)
errs = zeros(K, 1);
for k = 1:K
    testMask = (foldId == k);
    trainMask = ~testMask;
    m = trainLSSVR(X(trainMask, :), y(trainMask, :), scale, box, 0.1);
    yhat = predictCompat(m, X(testMask, :));
    e = yhat - y(testMask, :);
    errs(k) = mean(e.^2);
end
mse = mean(errs);
end

function model = trainLSSVR(X, y, scale, box, epsilon)
validateattributes(scale, {'double'}, {'scalar','finite','>',0});
validateattributes(box, {'double'}, {'scalar','finite','>',0});

n = size(X, 1);
K = rbfKernel(X, X, scale);
lambda = 1 / box;

A = [0, ones(1, n); ones(n, 1), K + lambda * eye(n)];
rhs = [0; y];
sol = A \ rhs;

b = sol(1);
alpha = sol(2:end);

model = struct();
model.ModelType = 'CompatLSSVR';
model.KernelFunction = 'gaussian';
model.KernelParameters = struct('Scale', scale);
model.BoxConstraints = box;
model.Epsilon = epsilon;
model.X = X;
model.Alpha = alpha;
model.Bias = b;
end

function K = rbfKernel(A, B, scale)
AA = sum(A.^2, 2);
BB = sum(B.^2, 2).';
D2 = AA + BB - 2*(A*B.');
D2(D2 < 0) = 0;
K = exp(-D2 ./ (2 * scale^2));
end

