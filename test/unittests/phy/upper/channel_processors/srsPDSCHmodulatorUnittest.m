classdef srsPDSCHmodulatorUnittest < matlab.unittest.TestCase
%  SRSPDSCHMODULATORUNITTEST Unit tests for PDSCH modulator functions
%  This class implements unit tests for the PDSCH symbol modulator functions using the
%  matlab.unittest framework. The simplest use consists in creating an object with
%    testCase = PDSCH_MODULATOR_UTEST
%  and then running all the tests with
%    testResults = testCase.run
%
%  SRSPDSCHMODULATORUNITTEST Properties (TestParameter)
%    PDSCHindex - SSB index, possible values = [0, ..., 7]
%    Lmax     - maximum number of SSBs within a SSB set, possible values = [4, 8, 64]
%    NCellID  - PHY-layer cell ID, possible values = [0, ..., 1007]
%    cw       - BCH cw, possible values = randi([0 1], 864, 1)
%
%  NRPDSCHSYMBOLMODULATORUNITTEST Methods:
%    The following methods are available for all test types:
%      * initialize - adds the required folders to the Matlab path and initializes the random seed
%
%    The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%      * initializeTestvector      - creates the header file and initializes it
%      * testvectorGenerationCases - generates testvectors for all possible combinations of PDSCHindex
%                                    and Lmax, while using a random NCellID and cw for each test
%      * closeTestvector           - closes the header file as required
%
%    The following methods are available for the SRS PHY validation tests (TestTags = {'srsPHYvalidation'}):
%      * x                     - TBD
%      * srsPHYvalidationCases - validates the SRS PHY functions for all possible combinations of PDSCHindex,
%                                Lmax and NCellID, while using a random cw for each test
%      * y                     - TBD
%
%  See also MATLAB.UNITTEST.

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        carrier_list = {nrCarrierConfig};
        pdsch_list = {nrPDSCHConfig};
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})

       
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename)
            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);
            
            carrier = testCase.carrier_list{1};
            pdsch = testCase.pdsch_list{1};

            % Calculate number of encoded bits
            nbits = length(nrPDSCHIndices(carrier, pdsch)) * 2;
            
            % Generate codewords
            cws = randi([0,1], nbits, 1);
            

            % write the BCH cw to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, 'writeUint8File', cws);

            % call the PDSCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws);

            % write each complex symbol into a binary file, and the associated indices to another
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, 'writeResourceGridEntryFile', modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = testImpl.testCaseToString('{%d, %d, %d, %d, %.1f, {%s}}', baseFilename, testID, NCellID, PDSCHindex, ...
                                                       SSBfirstSubcarrier, SSBfirstSymbol, SSBamplitude, SSBportsStr);

            % add the test to the file header
            testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
        end
    end
 
%     methods (Test, TestTags = {'srs_phy_validation'})
%
%         function srsPHYvalidationCases(testCase, NCellID, PDSCHindex, Lmax)
%             % use a cw for each test
%             cw = zeros(864, 1);
%             for index = 1: 864
%                 cw(index) = testCase.cw{index, NCellID+1};
%             end;
%
%             % call the Matlab PHY function
%             [matModulatedSymbols, matSymbolIndices] = srsPDSCHmodulator(cw, NCellID, PDSCHindex, Lmax);
%
%             % call the SRS PHY function
%             % TBD: [srsModulatedSymbols, srsSymbolIndices] = srsPDSCHmodulatorPHYtest(cw, NCellID, PDSCHindex, Lmax);
%
%             % compare the results
%             % TBD: testCase.verifyEqual(matModulatedSymbols, srsModulatedSymbols);
%             % TBD: testCase.verifyEqual(matSymbolIndices, srsSymbolIndices);
%         end
%     end


end
