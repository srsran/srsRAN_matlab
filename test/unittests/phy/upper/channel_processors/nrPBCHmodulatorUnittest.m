classdef nrPBCHmodulatorUnittest < matlab.unittest.TestCase
%NRPBCHSYMBOLMODULATORUNITTEST Unit tests for PBCH symbol modulator functions
%  This class implements unit tests for the PBCH symbol modulator functions using the
%  matlab.unittest framework. The simplest use consists in creating an object with
%    testCase = PBCH_SYMBOL_MODULATOR_UTEST
%  and then running all the tests with
%    testResults = testCase.run
%
%  NRPBCHSYMBOLMODULATORUNITTEST Properties (TestParameter)
%    SSBindex - SSB index, possible values = [0, ..., 7]
%    Lmax     - maximum number of SSBs within a SSB set, possible values = [4, 8, 64]
%    NCellID  - PHY-layer cell ID, possible values = [0, ..., 1007]
%    cw       - BCH cw, possible values = randi([0 1], 864, 1)
%
%  NRPBCHSYMBOLMODULATORUNITTEST Methods:
%    The following methods are available for all test types:
%      * initialize - adds the required folders to the Matlab path and initializes the random seed
%
%    The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%      * initializeTestvector      - creates the header file and initializes it
%      * testvectorGenerationCases - generates testvectors for all possible combinations of SSBindex
%                                    and Lmax, while using a random NCellID and cw for each test
%      * closeTestvector           - closes the header file as required
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
        randomizeTestvector = num2cell(randi([1, 1008], 1, 24));
        NCellID = num2cell(0:1:1007);
        cw = num2cell(randi([0 1], 864, 1008));
        SSBindex = num2cell(0:1:7);
        Lmax = {4, 8, 64};
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, SSBindex)
            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID and cw for each test
            randomizedTestCase = testCase.randomizeTestvector{testID+1};
            NCellID = testCase.NCellID{randomizedTestCase};
            cw = zeros(864, 1);
            for index = 1: 864
                cw(index) = testCase.cw{index,randomizedTestCase};
            end

            % current fixed parameter values as required by the C code (e.g., Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8 are equivalent in this stage)
            Lmax = 8;
            numPorts = 1;
            SSBfirstSubcarrier = 0;
            SSBfirstSymbol = 0;
            SSBamplitude = 1;
            SSBports = zeros(numPorts, 1);
            SSBportsStr = array2str(SSBports, false);

            % write the BCH cw to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, 'writeUint8File', cw);

            % call the PBCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = nrPBCHmodulator(cw, NCellID, SSBindex, Lmax);

            % write each complex symbol into a binary file, and the associated indices to another
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, 'writeResourceGridEntryFile', modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = testImpl.testCaseToString('{%d, %d, %d, %d, %.1f, {%s}}', baseFilename, testID, NCellID, SSBindex, ...
                                                       SSBfirstSubcarrier, SSBfirstSymbol, SSBamplitude, SSBportsStr);

            % add the test to the file header
            testImpl.addTestToChannelProcessorsHeaderFile(testCaseString, baseFilename, outputPath);
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
%             [matModulatedSymbols, matSymbolIndices] = nrPBCHmodulator(cw, NCellID, SSBindex, Lmax);
%
%             % call the SRS PHY function
%             % TBD: [srsModulatedSymbols, srsSymbolIndices] = nrPBCHmodulatorSRSphyTest(cw, NCellID, SSBindex, Lmax);
%
%             % compare the results
%             % TBD: testCase.verifyEqual(matModulatedSymbols, srsModulatedSymbols);
%             % TBD: testCase.verifyEqual(matSymbolIndices, srsSymbolIndices);
%         end
%     end


end
