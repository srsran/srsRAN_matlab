%RUNTESTVECTOR Main SRSGNB test interface.
%   RUNTESTVECTOR('unittests', SRSPHYBLOCK, PATHINREPO, UNITTESTCLASSNAME)
%   generates test vectors for the SRSPHYBLOCK block of the SRSGNB software.
%   PATHINREPO specifies the path of the SRSGNB block with respect to the
%   repository root folder. UNITTESTCASSNAME specifies the MATLAB unit test
%   class that runs the simulation.
%
%   RUNTESTVECTOR('srsPHYvalidation', SRSPHYBLOCK, PATHINREPO, UNITTESTCLASSNAME)
%   tests SRSPHYBLOCK by running a mex version of it.
%
%   Example
%      runTestvector('unittests','pbch_modulator', 'phy/upper/channel_processors', 'srsPBCHmodulatorUnittest')

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
    testImpl = TestVector(pathInRepo);

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
