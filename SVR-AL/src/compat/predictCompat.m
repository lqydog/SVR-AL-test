function yhat = predictCompat(model, X)
%PREDICTCOMPAT Predict regression output (compat layer).
%
% If Statistics and Machine Learning Toolbox is available, calls predict(model,X).
% Otherwise supports models returned by fitrsvmCompat (CompatLSSVR).

validateattributes(X, {'numeric'}, {'2d','finite'});

if exist('predict', 'file') == 2
    yhat = predict(model, X);
    return;
end

if isstruct(model) && isfield(model, 'ModelType') && strcmp(model.ModelType, 'CompatLSSVR')
    scale = model.KernelParameters.Scale;
    K = rbfKernel(X, model.X, scale);
    yhat = model.Bias + K * model.Alpha;
    return;
end

error("predictCompat:UnsupportedModel", "Unsupported model type for prediction.");
end

function K = rbfKernel(A, B, scale)
AA = sum(A.^2, 2);
BB = sum(B.^2, 2).';
D2 = AA + BB - 2*(A*B.');
D2(D2 < 0) = 0;
K = exp(-D2 ./ (2 * scale^2));
end

