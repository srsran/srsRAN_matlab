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
%    cw       - BCH codeword, possible values = randi([0 1], 864, 1)
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
        outputPath = '../testvector_outputs';
        baseFilename = 'pbch_modulator_test';
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
            testCaseName = class(testCase);
            testVectName = [testCaseName(1:end - length('Unittest')) 'TestvectorImpl'];
            constructor = str2func(testVectName);
            testCase.testImpl = constructor();

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
            % delete previous testvectors (if any)
            if isfolder(sprintf('%s', testCase.outputPath))
              rmdir(sprintf('%s', testCase.outputPath), 's');
            end

            % create an output directory
            mkdir(sprintf('%s', testCase.outputPath));

            % write the file header
            headerFilename = sprintf('%s/%s_data.h', testCase.outputPath, testCase.baseFilename);
            testvectorHeaderFileID = fopen(headerFilename, 'w');
            fprintf(testvectorHeaderFileID, '#ifndef SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_PBCH_MODULATOR_TEST_DATA_H\n');
            fprintf(testvectorHeaderFileID, '#define SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_PBCH_MODULATOR_TEST_DATA_H\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '// This file was generated using the following MATLAB scripts:\n');
            fprintf(testvectorHeaderFileID, '//   + "nr_pbch_symbol_modulator_unittest.m"\n');
            fprintf(testvectorHeaderFileID, '//   + "nr_pbch_modulation_symbols_testvector_generate.m"\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '#include "../../resource_grid_test_doubles.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/complex.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/phy/upper/channel_processors/pbch_modulator.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(testvectorHeaderFileID, '#include <array>\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'namespace srsgnb {\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'struct test_case_t {\n');
            fprintf(testvectorHeaderFileID, '  pbch_modulator::config_t                                config;\n');
            fprintf(testvectorHeaderFileID, '  file_vector<uint8_t>                                    data;\n');
            fprintf(testvectorHeaderFileID, '  file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'static const std::vector<test_case_t> pbch_modulator_test_data = {\n');
            fclose(testvectorHeaderFileID);
        end

        function testvectorGenerationCases(testCase, SSBindex)
            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_input*', testCase.outputPath, testCase.baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID and cw for each test
            randomizedTestCase = testCase.randomizeTestvector{testID+1};
            cellID = testCase.NCellID{randomizedTestCase};
            codeWord = zeros(864, 1);
            for index = 1: 864
                codeWord(index) = testCase.cw{index,randomizedTestCase};
            end

            % Lmax is currently fixed (Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8 are equivalent in this stage)
            SSBLmax = 8;

            % add a new testvector to the unit test outputs
            outputString = testCase.testImpl.addTestCase(testID, cellID, codeWord, SSBindex, SSBLmax, sprintf('%s', testCase.outputPath));

            % add the test to the file header
            headerFilename = sprintf('%s/%s_data.h', testCase.outputPath, testCase.baseFilename);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '%s', outputString);
            fclose(testvectorHeaderFileID);
        end

        function closeTestvector(testCase)
            % write the remaining .h file contents
            headerFilename = sprintf('%s/%s_data.h', testCase.outputPath, testCase.baseFilename);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '} // srsgnb\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID,'#endif // SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_PBCH_MODULATOR_TEST_DATA_H\n');
            fclose(testvectorHeaderFileID);

            % gzip generated testvector files
            testCase.testImpl.packResults(headerFilename, testCase.baseFilename, testCase.outputPath);
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
