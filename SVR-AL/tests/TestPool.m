classdef TestPool < matlab.unittest.TestCase
    %TESTPOOL Unit tests for pool generation.

    methods (Test)
        function testBuildPoolTruncInvLhs(testCase)
            problem = make2dNormalProblem();
            [Xpool, meta] = buildPoolTruncInvLhs(problem.dists, 0.001, 500);
            testCase.verifySize(Xpool, [500 2]);
            testCase.verifyTrue(all(isfinite(Xpool), 'all'));
            testCase.verifyTrue(all(isfield(meta, {'lb','ub','pmin','pmax'})));
            testCase.verifyTrue(all(Xpool(:, 1) >= meta.lb(1) - 1e-12));
            testCase.verifyTrue(all(Xpool(:, 1) <= meta.ub(1) + 1e-12));
            testCase.verifyTrue(all(Xpool(:, 2) >= meta.lb(2) - 1e-12));
            testCase.verifyTrue(all(Xpool(:, 2) <= meta.ub(2) + 1e-12));
        end
    end
end

