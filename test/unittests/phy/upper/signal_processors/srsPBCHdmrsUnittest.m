classdef srsPBCHdmrsUnittest < matlab.unittest.TestCase
%SRSPBCHDMRSUNITTEST Unit tests for PBCH DMRS processor functions
%  This class implements unit tests for the PBCH DMRS processor functions using the
%  matlab.unittest framework. The simplest use consists in creating an object with
%    testCase = SRSPBCHDMRSUNITTEST
%  and then running all the tests with
%    testResults = testCase.run
%
%  SRSPBCHDMRSUNITTEST Properties (TestParameter)
%    SSBindex - SSB index, possible values = [0, ..., 7]
%    Lmax     - maximum number of SSBs within a SSB set, possible values = [4, 8, 64]
%    NCellID  - PHY-layer cell ID, possible values = [0, ..., 1007]
%    nHF      - half-frame indicator, possible values = [0, 1]
%
%  SRSPBCHDMRSUNITTEST Methods:
%    The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%      * testvectorGenerationCases - generates testvectors for all possible combinations of SSBindex,
%                                    Lmax and nHF, while using a random NCellID for each test
%
%    The following methods are available for the SRS PHY validation tests (TestTags = {'srsPHYvalidation'}):
%      * srsPHYvalidationCases - validates the SRS PHY functions for all possible combinations of SSBindex,
%                                Lmax, nHF and NCellID
%
%  See also MATLAB.UNITTEST.

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        randomizeTestvector = num2cell(randi([1, 1008], 1, 54));
        NCellID = num2cell(0:1:1007);
        SSBindex = {0, 1, 2, 3, 4, 6, 16, 32, 48};
        Lmax = {4, 8, 64};
        nHF = {0, 1};
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, SSBindex, Lmax, nHF)
            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_output*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID and cw for each test
            randomizedTestCase = testCase.randomizeTestvector{testID+1};
            NCellID = testCase.NCellID{randomizedTestCase};

            % check if the current SSBindex value is possible with the current Lmax
            if Lmax > SSBindex
                % current fixed parameter values as required by the C code (e.g., Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8 are equivalent in this stage)
                numPorts = 1;
                SSBfirstSubcarrier = 0;
                SSBfirstSymbol = 0;
                SSBamplitude = 1;
                SSBports = zeros(numPorts, 1);
                SSBportsStr = array2str(SSBports);

                % call the PBCH DMRS symbol processor Matlab functions
                [DMRSsymbols, symbolIndices] = srsPBCHdmrs(NCellID, SSBindex, Lmax, nHF);

                % write each complex symbol into a binary file, and the associated indices to another
                testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, 'writeResourceGridEntryFile', DMRSsymbols, symbolIndices);

                % generate the test case entry
                testCaseString = testImpl.testCaseToString('{%d, %d, %d, %d, %d, %d, %.1f, {%s}}', baseFilename, testID, 0, NCellID, SSBindex, ...
                                                           Lmax, SSBfirstSubcarrier, SSBfirstSymbol, nHF, SSBamplitude, SSBportsStr);

                % add the test to the file header
                testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
            end
        end
    end

%     methods (Test, TestTags = {'srs_phy_validation'})
%
%         function srsPHYvalidationCases(testCase, NCellID, SSBindex, Lmax, nHF)
%             % call the Matlab PHY function
%             [matDMRSsymbols, matSymbolIndices] = srsPBCHdmrs(NCellID, SSBindex, Lmax, nHF);
%
%             % call the SRS PHY function
%             % TBD: [srsDMRSsymbols, srsSymbolIndices] = srsPBCHdmrsPHYtest(NCellID, SSBindex, Lmax, nHF);
%
%             % compare the results
%             % TBD: testCase.verifyEqual(matDMRSsymbols, srsDMRSsymbols);
%             % TBD: testCase.verifyEqual(matSymbolIndices, srsSymbolIndices);
%         end
%     end


end
