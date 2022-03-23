classdef srsModulationMapperUnittest < matlab.unittest.TestCase
%SRSMODULATIONMAPPERUNITTEST Unit tests for the modulation mapper functions
%   This class implements unit tests for the modulation mapper functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = SRSMODULATIONMAPPERUNITTEST
%   and then running all the tests with
%       testResults = testCase.run
%
%   SRSMODULATIONMAPPERUNITTEST Properties (TestParameter):
%
%   modScheme - modulation scheme ('BPSK', 'QPSK', 'QAM16', 'QAM64', 'QAM256')
%   nSymbols  - number of modulated output symbols (257, 997)
%
%   SRSMODULATIONMAPPERUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible combinations
%                               of modScheme and nSymbols.
%
%   SRSMODULATIONMAPPERUNITTEST Methods (TestTags = {'srsPHYvalidation'}):
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
%INITIALIZE Adds the required folders to the MATLAB path and initializes the
%   random seed.
            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, nSymbols, modScheme)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible combinations of nSymbols
%    and modScheme.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);
            % generate random test input as a bit sequence
            codeword = randi([0 1], nSymbols * modScheme{1}, 1);

            % write the codeword to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, @writeUint8File, codeword);

            % call the symbol modulation Matlab functions
            [modulatedSymbols] = srsModulator(codeword, modScheme{2});

            % write complex symbols into a binary file
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeComplexFloatFile, modulatedSymbols);

            % generate the test case entry
            modSchemeString = modScheme{length(modScheme)};
            testCaseString = testImpl.testCaseToString('%d, modulation_scheme::%s', baseFilename, testID, true, nSymbols, modSchemeString);

            % add the test to the file header
            testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
        end
    end
end
