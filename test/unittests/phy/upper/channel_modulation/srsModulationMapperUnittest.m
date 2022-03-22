classdef srsModulationMapperUnittest < matlab.unittest.TestCase
%SRSMODULATIONMAPPERUNITTEST Unit tests for the modulation mapper functions
%  This class implements unit tests for the modulation mapper functions using the
%  matlab.unittest framework. The simplest use consists in creating an object with
%    testCase = SRSMODULATIONMAPPERUNITTEST
%  and then running all the tests with
%    testResults = testCase.run
%
%  SRSMODULATIONMAPPERUNITTEST Properties (TestParameter)
%    modScheme - modulation scheme = [BPSK, QPSK, QAM16, QAM64, QAM256]
%    nSymbols  - number of modulated output symbols = [257, 997]
%
%  SRSMODULATIONMAPPERUNITTEST Methods:
%    The following methods are available for all test types:
%      * initialize - adds the required folders to the Matlab path and initializes the random seed
%
%    The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%      * testvectorGenerationCases - generates testvectors for all possible combinations of SSBindex
%                                    and Lmax, while using a random NCellID and cw for each test
%
%    The following methods are available for the SRS PHY validation tests (TestTags = {'srsPHYvalidation'}):
%      * x                     - TBD
%      * srsPHYvalidationCases - validates the SRS PHY functions for all possible combinations of SSBindex,
%                                Lmax and NCellID, while using a random cw for each test
%      * y                     - TBD
%
%  See also MATLAB.UNITTEST.
    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        nSymbols = {257, 997};
        modScheme = {{1, 'BPSK'}, {2, 'QPSK'}, {4, '16QAM', 'QAM16'}, {6, '64QAM', 'QAM64'}, {8, '256QAM', 'QAM256'}};
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, nSymbols, modScheme)
            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);
            % generate random test input as a bit sequence
            codeword = randi([0 1], nSymbols * modScheme{1}, 1);

            % write the codeword to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, 'writeUint8File', codeword);

            % call the symbol modulation Matlab functions
            [modulatedSymbols] = srsModulator(codeword, modScheme{2});

            % write complex symbols into a binary file
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, 'writeComplexFloatFile', modulatedSymbols);

            % generate the test case entry
            modSchemeString = modScheme{length(modScheme)};

            testCaseString = testImpl.testCaseToString('%d, modulation_scheme::%s', baseFilename, testID, 1, nSymbols, modSchemeString);

            % add the test to the file header
            testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
        end
    end
end
