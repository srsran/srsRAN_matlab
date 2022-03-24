classdef srsPBCHmodulatorUnittest < matlab.unittest.TestCase
%SRSPBCHMODULATORUNITTEST Unit tests for PBCH symbol modulator functions.
%   This class implements unit tests for the PBCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = SRSPBCHMODULATORUNITTEST
%   and then running all the tests with
%      testResults = testCase.run
%
%   SRSPBCHMODULATORUNITTEST Properties (TestParameter):
%
%   SSBindex - SSB index (0, ..., 7).
%   Lmax     - Maximum number of SSBs within a SSB set (4, 8, 64).
%   NCellID  - PHY-layer cell ID (0, ..., 1007).
%   cw       - BCH codeword (864 bits).
%
%   SRSPBCHMODULATORUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible SSBindex values, while
%                               using a fixed Lmax and a random NCellID and cw for each test.
%
%   SRSPBCHMODULATORUNITTEST Methods (TestTags = {'srsPHYvalidation'}):
%
%  See also MATLAB.UNITTEST.

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        randomizeTestvector = num2cell(randi([1, 1008], 1, 24));
        NCellID = num2cell(0:1:1007);
        cw = num2cell(randi([0 1], 864, 1008));
        SSBindex = num2cell(0:1:7);
        Lmax = {4, 8, 64};
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
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, SSBindex)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible SSBindex values, while
%   using a fixed Lmax and a random NCellID and cw for each test.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID and cw for each test
            randomizedTestCase = testCase.randomizeTestvector{testID+1};
            NCellIDLoc = testCase.NCellID{randomizedTestCase};
            cwLoc = zeros(864, 1);
            for index = 1: 864
                cwLoc(index) = testCase.cw{index,randomizedTestCase};
            end

            % current fixed parameter values as required by the C code (e.g., Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8 are equivalent in this stage)
            LmaxLoc = 8;
            numPorts = 1;
            SSBfirstSubcarrier = 0;
            SSBfirstSymbol = 0;
            SSBamplitude = 1;
            SSBports = zeros(numPorts, 1);
            SSBportsStr = cellarray2str({SSBports}, true);

            % write the BCH cw to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, @writeUint8File, cwLoc);

            % call the PBCH symbol modulation MATLAB functions
            [modulatedSymbols, symbolIndices] = srsPBCHmodulator(cwLoc, NCellIDLoc, SSBindex, LmaxLoc);

            % write each complex symbol into a binary file, and the associated indices to another
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = testImpl.testCaseToString(baseFilename, testID, true, {NCellIDLoc, SSBindex, SSBfirstSubcarrier, ...
                                                       SSBfirstSymbol, SSBamplitude, SSBportsStr}, true);

            % add the test to the file header
            testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
        end
    end

%     methods (Test, TestTags = {'srs_phy_validation'})
%
%         function srsPHYvalidationCases(testCase, NCellID, SSBindex, Lmax)
%             % use a cw for each test
%             cw = zeros(864, 1);
%             for index = 1: 864
%                 cw(index) = testCase.cw{index, NCellID+1};
%             end;
%
%             % call the Matlab PHY function
%             [matModulatedSymbols, matSymbolIndices] = srsPBCHmodulator(cw, NCellID, SSBindex, Lmax);
%
%             % call the SRS PHY function
%             % TBD: [srsModulatedSymbols, srsSymbolIndices] = srsPBCHmodulatorPHYtest(cw, NCellID, SSBindex, Lmax);
%
%             % compare the results
%             % TBD: testCase.verifyEqual(matModulatedSymbols, srsModulatedSymbols);
%             % TBD: testCase.verifyEqual(matSymbolIndices, srsSymbolIndices);
%         end
%     end


end
