classdef nrPBCHsymbolModulatorUnittest < matlab.unittest.TestCase
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

    properties
        outputPath = '../../../../testvector_outputs';
        baseFilename = 'pbch_modulator';
        testImpl;
    end

    properties (TestParameter) % we are really interestEd
        randomizeTestvector = num2cell(randi([1, 1008], 1, 24));
        NCellID = num2cell(0:1:1007);
        cw = num2cell(randi([0 1], 864, 1008));
        SSBindex = num2cell(0:1:7);
        Lmax = {4, 8, 64};
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % create test vector implementation object
            testCase.testImpl = testvector;

            % setup the random seed
            seed = 1234;
            rng(seed);

            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function initializeTestvector(testCase)
            % create folder and remove old testvectors (if needed)
            testCase.testImpl.createOutputFolder(testCase.baseFilename, testCase.outputPath);

            % create the header file with the initial contents
            testCase.testImpl.createChannelProcessorsHeaderFile(testCase.baseFilename, testCase.outputPath, mfilename);
        end

        function testvectorGenerationCases(testCase, SSBindex)
            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', testCase.outputPath, testCase.baseFilename);
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
            SSBportsStr = convertArrayToString(SSBports);

            % write the BCH cw to a binary file
            testCase.testImpl.saveDataFile(testCase.baseFilename, '_test_input', testID, testCase.outputPath, 'writeUint8File', cw);

            % call the PBCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = nrPBCHmodulationSymbolsGenerate(cw, NCellID, SSBindex, Lmax);

            % write each complex symbol into a binary file, and the associated indices to another
            testCase.testImpl.saveDataFile(testCase.baseFilename, '_test_output', testID, testCase.outputPath, 'writeResourceGridEntryFile', modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = testCase.testImpl.testCaseToString('{%d, %d, %d, %d, %.1f, {%s}}', testCase.baseFilename, testID, NCellID, SSBindex, ...
                                                                SSBfirstSubcarrier, SSBfirstSymbol, SSBamplitude, SSBportsStr);

            % add the test to the file header
            testCase.testImpl.addTestToChannelProcessorsHeaderFile(testCaseString, testCase.baseFilename, testCase.outputPath);
        end

        function closeTestvector(testCase)
            % write the remaining header file contents
            testCase.testImpl.closeChannelProcessorsHeaderFile(testCase.baseFilename, testCase.outputPath);

            % gzip generated testvector files
            testCase.testImpl.packResults(testCase.baseFilename, testCase.outputPath);
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
%             [matModulatedSymbols, matSymbolIndices] = nrPBCHmodulationSymbolsGenerate(cw, NCellID, SSBindex, Lmax);
%
%             % call the SRS PHY function
%             % TBD: [srsModulatedSymbols, srsSymbolIndices] = nr_pbch_modulation_symbols_srs_phy_test(cw, NCellID, SSBindex, Lmax);
%
%             % compare the results
%             % TBD: testCase.verifyEqual(matModulatedSymbols, srsModulatedSymbols);
%             % TBD: testCase.verifyEqual(matSymbolIndices, srsSymbolIndices);
%         end
%     end


end
