classdef TestStopCriteria < matlab.unittest.TestCase
    %TESTSTOPCRITERIA Unit tests for Pf-based stopping.

    methods (Test)
        function testStopOnNmax(testCase)
            opts = struct('Nmax', 10, 'eta', 1e-2, 'Kconsec', 2);
            [stopFlag, consec] = stopCriteria([0.1; 0.11], 10, opts, 0);
            testCase.verifyTrue(stopFlag);
            testCase.verifyEqual(consec, 0);
        end

        function testStopOnConvergence(testCase)
            opts = struct('Nmax', 100, 'eta', 1e-2, 'Kconsec', 2);
            pf = [0.1; 0.1005];
            [stop1, c1] = stopCriteria(pf, 20, opts, 0);
            testCase.verifyFalse(stop1);
            testCase.verifyEqual(c1, 1);

            pf(end+1, 1) = 0.1007; %#ok<AGROW>
            [stop2, c2] = stopCriteria(pf, 21, opts, c1);
            testCase.verifyTrue(stop2);
            testCase.verifyEqual(c2, 2);
        end
    end
end

