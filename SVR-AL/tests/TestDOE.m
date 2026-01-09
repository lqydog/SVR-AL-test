classdef TestDOE < matlab.unittest.TestCase
    %TESTDOE Unit tests for DOE selection.

    methods (Test)
        function testKmeansDoeFromPool(testCase)
            Xpool01 = rand(200, 2);
            idx = kmeansDoeFromPool(Xpool01, 10);
            testCase.verifySize(idx, [10 1]);
            testCase.verifyEqual(numel(unique(idx)), 10);
            testCase.verifyTrue(all(idx >= 1 & idx <= size(Xpool01, 1)));
        end
    end
end

