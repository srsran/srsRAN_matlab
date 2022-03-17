%RUNTESTVECTOR:
%  Function generating unittest testvectors to validate the different PHY functions of SRS GNB.
%
%  Call details:
%    RUNTESTVECTOR(CLASSNAME) receives the input parameter
%        * string CLASSNAME - name of the nrPHYblockUnittest class to be utilized

function runTestvector(className)
    import matlab.unittest.TestSuite

    % add the simulator folders to the MATLAB path
    addpath('../../src/phy', '../unittest', '../helpers', '../testvector');

    % run the testvector generation tests from the related unit test class
    unittestFilename = ['../unittest/' className '.m'];
    nrPHYtestvectorTests = TestSuite.fromFile(unittestFilename, 'Tag', 'testvector');
    testResults = nrPHYtestvectorTests.run;
end
