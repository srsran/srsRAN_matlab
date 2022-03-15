classdef nr_pbch_symbol_modulator_unittest < matlab.unittest.TestCase
% PBCH_SYMBOL_MODULATOR_UTEST Unit tests for PBCH symbol modulator functions
%   This class implements unit tests for the PBCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%     testCase = PBCH_SYMBOL_MODULATOR_UTEST
%   and then running all the tests with
%     testResults = testCase.run
%
%   NR_PBCH_SYMBOL_MODULATOR_UNITTEST Properties (TestParameter)
%     SSB_index   - SSB index, possible values = [0,..,7]
%     SSB_Lmax    - maximum number of SSBs within a SSB set, possible values = [4, 8, 64]
%     NCellID     - PHY-layer cell ID, possible values = [0,..,1007]
%     cw          - BCH codeword, possible values = randi([0 1],864,1)
%
%   NR_PBCH_SYMBOL_MODULATOR_UNITTEST Methods:
%     The following methods are available for all test types:
%       * initialize - adds the required folders to the Matlab path and initializes the random seed
%
%     The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%       * initialize_testvector       - creates the header file and initializes it
%       * testvector_generation_cases - generates testvectors for all possible combinations of SSB_index
%                                       and SSB_Lmax, while using a random NCellID and cw for each test
%       * close_testvector            - closes the header file as required
%
%     The following methods are available for the SRS PHY validation tests (TestTags = {'srs_phy_validation'}):
%       * x                       - TBD
%       * srsphy_validation_cases - validates the SRS PHY functions for all possible combinations of SSB_index,
%                                   SSB_Lmax and NCellID, while using a random cw for each test
%       * y                       - TBD
%
%   See also MATLAB.UNITTEST.

    properties (TestParameter) % we are really interestEd
        randomize_testvector = num2cell(randi([1,1008],1,24));
        NCellID = num2cell(0:1:1007);
        cw = num2cell(randi([0 1],864,1008));
        SSB_index = num2cell(0:1:7);
        SSB_Lmax = {4,8,64}
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % setup the random seed
            seed = 1234;
            rng(seed);

            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end;
    end

    methods (Test, TestTags = {'testvector'})
        function initialize_testvector(testCase)
            % delete previous testvectors (if any)
            file = dir ('pbch_modulator_test*');
            filenames = {file.name};
            if length(filenames) > 0
                delete(filenames{:});
            end;

            % write the file header
            testvector_header_file_id = fopen('pbch_modulator_test_data.h', 'w');
            fprintf(testvector_header_file_id, '#ifndef SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_PBCH_MODULATOR_TEST_DATA_H_\n');
            fprintf(testvector_header_file_id, '#define SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_PBCH_MODULATOR_TEST_DATA_H_\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id, '// This file was generated using the following MATLAB scripts:\n');
            fprintf(testvector_header_file_id, '//   + "nr_pbch_symbol_modulator_unittest.m"\n');
            fprintf(testvector_header_file_id, '//   + "nr_pbch_modulation_symbols_testvector_generate.m"\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id, '#include "../../resource_grid_test_doubles.h"\n');
            fprintf(testvector_header_file_id, '#include "srsgnb/phy/upper/channel_processors/pbch_modulator.h"\n');
            fprintf(testvector_header_file_id, '#include "srsgnb/adt/complex.h"\n');
            fprintf(testvector_header_file_id, '#include <array>\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id, 'namespace srsgnb {\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id, 'struct test_case_t {\n');
            fprintf(testvector_header_file_id, '  pbch_modulator::config_t                   args;\n');
            fprintf(testvector_header_file_id, '  std::string                                data_filename;\n');
            fprintf(testvector_header_file_id, '  std::string                                symbols_filename;\n');
            fprintf(testvector_header_file_id, '  std::string                                symbol_indices_filename;\n');
            fprintf(testvector_header_file_id, '};\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id, 'static const std::vector<test_case_t> pbch_modulator_test_data = {\n');
            fclose(testvector_header_file_id);
        end

        function testvector_generation_cases(testCase, SSB_index, SSB_Lmax)
            % generate a unique test ID
            file = dir ('pbch_modulator_test_data*');
            filenames = {file.name};
            testID = length(filenames)-1; % at least 'pbch_modulator_test_data.h' will be present

            % use a unique NCellID and cw for each test
            randomized_test_case = testCase.randomize_testvector{testID+1};
            NCellID = testCase.NCellID{randomized_test_case};
            cw=zeros(864,1);
            for index = 1: 864
                cw(index) = testCase.cw{index,randomized_test_case};
            end;

            % add a new testvector to the unit test outputs
            output_string = nr_pbch_modulation_symbols_testvector_add(NCellID,cw,SSB_index,SSB_Lmax,testID);

            % add the test to the file header
            testvector_header_file_id = fopen('pbch_modulator_test_data.h', 'a+');
            fprintf(testvector_header_file_id, '%s', output_string);
            fclose(testvector_header_file_id);
        end

        function close_testvector(testCase)
            % write the remaining .h file contents
            testvector_header_file_id = fopen('pbch_modulator_test_data.h', 'a+');
            fprintf(testvector_header_file_id, '};\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id, '} // srsgnb\n');
            fprintf(testvector_header_file_id, '\n');
            fprintf(testvector_header_file_id,'#endif // SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_PBCH_MODULATOR_TEST_DATA_H_\n');
            fclose(testvector_header_file_id);
        end
    end

%     methods (Test, TestTags = {'srs_phy_validation'})
% 
%         function srsphy_validation_cases(testCase, NCellID, SSB_index, SSB_Lmax)
%             % use a cw for each test
%             cw=zeros(864,1);
%             for index = 1: 864
%                 cw(index) = testCase.cw{index,NCellID+1};
%             end;
% 
%             % call the Matlab PHY function
%             [mat_modulated_symbols,mat_symbol_indices] = nr_pbch_modulation_symbols_generate(cw,NCellID,SSB_index,SSB_Lmax);
% 
%             % call the SRS PHY function
%             % TBD: [srs_modulated_symbols, srs_symbol_indices] = nr_pbch_modulation_symbols_srs_phy_test(cw,NCellID,SSB_index,SSB_Lmax);
% 
%             % compare the results
%             % TBD: testCase.verifyEqual(mat_modulated_symbols, srs_modulated_symbols);
%             % TBD: testCase.verifyEqual(mat_symbol_indices, srs_symbol_indices);
%         end
%     end


end
