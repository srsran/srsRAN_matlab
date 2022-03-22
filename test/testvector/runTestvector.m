%RUNTESTVECTOR:
%  Function generating unittest testvectors to validate the different PHY functions of SRS GNB.
%
%  Call details:
%    RUNTESTVECTOR(TESTTYPE, SRSPHYBLOCK, PATHINREPO, UNITTESTCLASSNAME) receives the input parameter
%        * string TESTTYPE          - specifies the type of test to be done, currently supported values
%                                     are 'testvector' and 'srsPHYvalidation'
%        * string SRSPHYBLOCK       - name of the (C) SRS gNB PHY block under test
%        * string PATHINREPO        - path to the (C) SRS gNB PHY block under test with respect to the
%                                     repository root folder
%        * string UNITTESTCLASSNAME - name of the (Matlab) PHYblockUnittest class to be utilized

function runTestvector(testType, srsPHYblock, pathInRepo, unittestClassName)
    import matlab.unittest.TestSuite
    import matlab.unittest.parameters.Parameter

    % remove last '/' if it is added to the path string
    if strcmp(pathInRepo(end), '/')
        pathInRepo = pathInRepo(1 : end -  1);
    end

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
    testImpl = testvector(pathInRepo);

    % create the output folder and remove old testvectors (if needed)
    testImpl.createOutputFolder(srsPHYblock, outputPath);

    % create the header file with the initial contents
    testImpl.createHeaderFile(srsPHYblock, outputPath, unittestClassName);

    % run the testvector generation tests from the related unit test class
    unittestFilename = [testPath '/' unittestClassName '.m'];
    extParams = Parameter.fromData('outputPath', {outputPath}, 'baseFilename', {srsPHYblock}, 'testImpl', {testImpl});
    nrPHYtestvectorTests = TestSuite.fromFile(unittestFilename, 'Tag', 'testvector', 'ExternalParameters', extParams);
    testResults = nrPHYtestvectorTests.run;

    % write the remaining header file contents
    testImpl.closeHeaderFile(srsPHYblock, outputPath);

    % gzip generated testvector files
    testImpl.packResults(srsPHYblock, outputPath);
end
