classdef TestAcquisition < matlab.unittest.TestCase
    %TESTACQUISITION Unit tests for acquisition selection.

    methods (Test)
        function testA1Selection(testCase)
            gHat = [0.1; 0.05; 0.2];
            minDist = [0.1; 0.01; 0.3];
            poolAvail = true(3, 1);
            opts = struct('eps_d', 0);
            [idx, scoreMin, name] = selectNextPoint("A1", gHat, [], minDist, poolAvail, opts);
            testCase.verifyEqual(name, "A1");
            testCase.verifyEqual(idx, 3);
            testCase.verifyEqual(scoreMin, abs(gHat(3)) / minDist(3), 'AbsTol', 1e-12);
        end

        function testUbootSelection(testCase)
            gHat = [0.1; 0.05; 0.2];
            sigma = [0.01; 0.5; 0.1];
            minDist = [0.1; 0.1; 0.1];
            poolAvail = true(3, 1);
            opts = struct('eps_sigma', 0);
            [idx, ~, name] = selectNextPoint("Uboot", gHat, sigma, minDist, poolAvail, opts);
            testCase.verifyEqual(name, "Uboot");
            [~, idxExpected] = min(abs(gHat) ./ sigma);
            testCase.verifyEqual(idx, idxExpected);
        end
    end
end

