%RUNTESTVECTOR:
%  Function generating unittest testvectors to validate the different PHY functions of SRS GNB.
%
%  Call details:
%    RUNTESTVECTOR(CLASSNAME) receives the input parameter
%        * string CLASSNAME - name of the nrPHYblockUnittest class to be utilized

function runTestvector(testType, srsPHYblock, pathInRepo)
    import matlab.unittest.TestSuite
    import matlab.unittest.parameters.Parameter

    % define the input and output paths
    rootPath = extractBetween(pwd,'','test');
    srcPath = [rootPath{1} '/src/' pathInRepo];
    testPath = [rootPath{1} '/test/' testType '/' pathInRepo];
    helpersPath = [rootPath{1} '/test/helpers'];
    testvectorPath = [rootPath{1} '/test/testvector'];

    % define the absolute output paths
    outputPath = [rootPath{1} '/test/testvector_outputs'];

    % add the simulator folders to the MATLAB path
    addpath(srcPath, testPath, helpersPath, testvectorPath);

    % create a test vector implementation object
    testImpl = testvector;
    className = ['nr' translateToSimulatorNaming(srsPHYblock) 'Unittest'];

    % create the output folder and remove old testvectors (if needed)
    testImpl.createOutputFolder(srsPHYblock, outputPath);

    % create the header file with the initial contents
    testImpl.createChannelProcessorsHeaderFile(srsPHYblock, outputPath, mfilename);

    % run the testvector generation tests from the related unit test class
    unittestFilename = [testPath '/' className '.m'];
    extParams = Parameter.fromData('outputPath', {outputPath}, 'baseFilename', {srsPHYblock}, 'testImpl', {testImpl});
    nrPHYtestvectorTests = TestSuite.fromFile(unittestFilename, 'Tag', 'testvector', 'ExternalParameters', extParams);
    testResults = nrPHYtestvectorTests.run;

    % write the remaining header file contents
    testImpl.closeChannelProcessorsHeaderFile(srsPHYblock, outputPath);

    % gzip generated testvector files
    testImpl.packResults(srsPHYblock, outputPath);
end
