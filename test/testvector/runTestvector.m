%RUNTESTVECTOR:
%  Function generating unittest testvectors to validate the different PHY functions of SRS GNB.
%
%  Call details:
%    RUNTESTVECTOR(CLASSNAME) receives the input parameter
%        * string CLASSNAME - name of the nrPHYblockUnittest class to be utilized

function runTestvector(testType, className, pathInRepo)
    import matlab.unittest.TestSuite

    % define paths from inputs
    src_path = ['../../src/' pathInRepo];
    test_path = ['../' testType '/' pathInRepo];

    % add the simulator folders to the MATLAB path
    addpath(src_path, test_path, '../helpers', '../testvector');
    % run the testvector generation tests from the related unit test class
    unittestFilename = [test_path '/' className '.m'];
    nrPHYtestvectorTests = TestSuite.fromFile(unittestFilename, 'Tag', 'testvector');
    testResults = nrPHYtestvectorTests.run;
end
