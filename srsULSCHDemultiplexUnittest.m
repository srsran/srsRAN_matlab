%srsULSCHDemultiplexUnittest Unit tests for UL-SCH information functions.
%   This class implements unit tests for the UL-SCH information
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with 
%      testCase = srsULSCHDemultiplexUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsULSCHDemultiplexUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ulsch_demultiplex').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsULSCHDemultiplexUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsULSCHDemultiplexUnittest Properties (TestParameter):
%
%   Modulation            - Modulation.
%   nofHarqAckBits        - Number of multiplexed HARQ-ACK bits.
%   nofCsiPart1Bits       - Number of multiplexed CSI-Part1 bits.
%   nofCsiPart2Bits       - Number of multiplexed CSI-Part2 bits.
%
%   srsULSCHDemultiplexUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsULSCHDemultiplexUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrULSCHDemultiplex, nrULSCHInfo.
classdef srsULSCHDemultiplexUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ulsch_demultiplex'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ulsch_demultiplex' tests will be erased).
        outputPath = {['testULSCHDemultiplex', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Modulation {pi/2-BPSK, QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'pi/2-BPSK', '16QAM'};

        %Number of HARQ-ACK bits.
        nofHarqAckBits = {0, 1, 4}

        %Number of CSI-Part1 bits.
        nofCsiPart1Bits = {0, 4}

        %Number of CSI-Part2 bits.
        nofCsiPart2Bits = {0, 6}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/ulsch_demultiplex.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/log_likelihood_ratio.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  ulsch_demultiplex::configuration  config;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> input;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> output_ulsch;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> output_harq_ack;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> output_csi_part1;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> output_csi_part2;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, ...
                Modulation, nofHarqAckBits, ...
                nofCsiPart1Bits, nofCsiPart2Bits)
        %testvectorGenerationCases Generates a test vectors given the
        %   combinations of Modulation, nofHarqAckBits,
        %   nofCsiPart1Bits and nofCsiPart2Bits. 

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.upper.signal_processors.srsPUSCHdmrs
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeInt8File

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            % Configure carrier.
            carrier = srsConfigureCarrier;

            % Prepare PRB set.
            NumPRB = randi([1, 15]);
            PRBSet = 0:(NumPRB-1);

            % Select a target code rate between 0.1 and 0.9.
            targetCodeRate = round(0.8 * rand + 0.1, 1);

            % Configure PUSCH.
            NumLayers = randi([1, 4]);
            pusch = srsConfigurePUSCH(NumLayers, Modulation, PRBSet);
            pusch.DMRS.DMRSConfigurationType = randi([1, 2]);
            pusch.DMRS.DMRSAdditionalPosition = randi([0, 3]);
            pusch.DMRS.NumCDMGroupsWithoutData = pusch.DMRS.DMRSConfigurationType + 1;
            if NumLayers == 1 
                pusch.DMRS.NumCDMGroupsWithoutData = 1;
            end

            [~, puschInfo] = nrPUSCHIndices(carrier, pusch);

            numPRB = length(pusch.PRBSet);

            tbs = nrTBS(pusch.Modulation, ...
                pusch.NumLayers, ...
                numPRB, ...
                puschInfo.NREPerPRB, ...
                targetCodeRate);

            ulschInfo = nrULSCHInfo(pusch, targetCodeRate, tbs, ...
                nofHarqAckBits, nofCsiPart1Bits, nofCsiPart2Bits);

            % Generate random codeword with LLR.
            cw = randi([-120, 120], puschInfo.G, 1);

            % Demultiplex signal.
            [schData, harqAck, csiPart1, csiPart2] = ...
                nrULSCHDemultiplex(pusch, targetCodeRate, tbs, ...
                nofHarqAckBits, nofCsiPart1Bits, nofCsiPart2Bits, cw);

            % Save codeword.
            testCase.saveDataFile('_test_input', testID, @writeInt8File, cw);

            % Save SCH data.
            testCase.saveDataFile('_test_data', testID, @writeInt8File, schData);

            % Save HARQ-ACK.
            testCase.saveDataFile('_test_harq', testID, @writeInt8File, harqAck);

            % Save CSI-Part1.
            testCase.saveDataFile('_test_csi1', testID, @writeInt8File, csiPart1);

            % Save CSI-Part2.
            testCase.saveDataFile('_test_csi2', testID, @writeInt8File, csiPart2);

            % Generate modulation cheme type string.
            switch pusch.Modulation
                case 'pi/2-BPSK'
                    modString = 'modulation_scheme::PI_2_BPSK';
                case 'QPSK'
                    modString = 'modulation_scheme::QPSK';
                case '16QAM'
                    modString = 'modulation_scheme::QAM16';
                case '64QAM'
                    modString = 'modulation_scheme::QAM64';
                case '256QAM'
                    modString = 'modulation_scheme::QAM256';
            end

            % Generate DM-RS indices.
            [~, puschDMRSIndices] = srsPUSCHdmrs(carrier, pusch);

            % Generate DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(puschDMRSIndices);

            % Generate DM-RS type string.
            dmrsTypeString = sprintf('dmrs_type::TYPE%d', pusch.DMRS.DMRSConfigurationType);

            % Prepare configuration in a cell.
            configuration = {...
                modString, ...                          % modulation
                pusch.NumLayers, ...                    % nof_layers
                numPRB, ...                             % nof_prb
                pusch.SymbolAllocation(1), ...          % start_symbol_index
                pusch.SymbolAllocation(2), ...          % nof_symbols
                ulschInfo.GACKRvd, ...                  % nof_harq_ack_rvd
                dmrsTypeString, ...                     % dmrs_type
                dmrsSymbolMask, ...                     % dmrs_symbol_mask
                pusch.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                };

            testCaseString = testCase.testCaseToString(testID, ...
                configuration, true, '_test_input', '_test_data', ...
                '_test_harq', '_test_csi1', '_test_csi2');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHProcessorUnittest
