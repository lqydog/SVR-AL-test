classdef TestNormalization < matlab.unittest.TestCase
    %TESTNORMALIZATION Unit tests for normalization utilities.

    methods (Test)
        function testMinMax01(testCase)
            lb = [-1, 0];
            ub = [ 1, 4];
            X = [lb; ub; 0, 2];
            X01 = applyMinMax01(X, lb, ub);
            testCase.verifyEqual(X01(1, :), [0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(X01(2, :), [1, 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(X01(3, :), [0.5, 0.5], 'AbsTol', 1e-12);
        end

        function testFitNormModelFields(testCase)
            lb = [0, 0];
            ub = [1, 2];
            X = [0.1 0.2; 0.9 1.8; 0.5 1.0];
            nm = fitNormModel(X, lb, ub);
            testCase.verifyTrue(all(isfield(nm, {'lb','ub','mu','sigma'})));
            testCase.verifySize(nm.mu, [1 2]);
            testCase.verifySize(nm.sigma, [1 2]);
            testCase.verifyTrue(all(isfinite(nm.mu)));
            testCase.verifyTrue(all(isfinite(nm.sigma)));
            testCase.verifyTrue(all(nm.sigma > 0));
        end

        function testApplyNormShapes(testCase)
            lb = [0, 0];
            ub = [1, 1];
            X = rand(5, 2);
            nm = fitNormModel(X, lb, ub);
            Z1 = applyNormForSvrTrain(X, nm);
            Z2 = applyNormForSvrPredict(X, nm);
            testCase.verifySize(Z1, [5 2]);
            testCase.verifySize(Z2, [5 2]);
        end
    end
end

