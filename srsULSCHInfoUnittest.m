%srsULSCHInfoUnittest Unit tests for UL-SCH information functions.
%   This class implements unit tests for the UL-SCH information
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with 
%      testCase = srsULSCHInfoUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsULSCHInfoUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ulsch_info').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'ran/pusch').
%
%   srsULSCHInfoUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsULSCHInfoUnittest Properties (TestParameter):
%
%   NumLayers             - Number of transmission layers.
%   NumPRB                - Transmission bandwidth in PRB.
%   DMRSConfigurationType - DM-RS configuration type.
%   Modulation            - Modulation.
%   targetCodeRate        - Transmission target code rate.
%   nofHarqAckBits        - Number of HARQ-ACK bits to multiplex.
%   nofCsiPart1Bits       - Number of CSI-Part1 bits to multiplex.
%   nofCsiPart2Bits       - Number of CSI-Part2 bits to multiplex.
%
%   srsULSCHInfoUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsULSCHInfoUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrULSCHInfo.
classdef srsULSCHInfoUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ulsch_info'

        %Type of the tested block.
        srsBlockType = 'ran/pusch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ulsch_info' tests will be erased).
        outputPath = {['testULSCHInfo', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Number of transmission layers.
        NumLayers = {1, 2, 4}

        %Number of PRBs.
        NumPRB = {1, 2, 52}

        % DM-RS Configuration type {1, 2}.
        DMRSConfigurationType = {1, 2};

        %Modulation {QPSK, 16QAM, 64QAM, 256QAM}.
        Modulation = {'QPSK', '16QAM', '64QAM', '256QAM'};

        %Target code rate.
        targetCodeRate = {0.5};

        %Number of HARQ-ACK bits.
        nofHarqAckBits = {0, 1, 2, 4}

        %Number of CSI-Part1 bits.
        nofCsiPart1Bits = {0}

        %Number of CSI-Part2 bits.
        nofCsiPart2Bits = {0}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "srsgnb/ran/pusch/ulsch_info.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  ulsch_configuration config;\n');
            fprintf(fileID, '  ulsch_information   info;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, NumLayers, NumPRB, ...
                DMRSConfigurationType, Modulation, targetCodeRate, ...
                nofHarqAckBits, nofCsiPart1Bits, nofCsiPart2Bits)
        %testvectorGenerationCases Generates a test vectors given the
        %   combinations of NumLayers, NumPRB, DMRSConfigurationType,
        %   Modulation, targetCodeRate, nofHarqAckBits, nofCsiPart1Bits and
        %   nofCsiPart2Bits.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.upper.signal_processors.srsPUSCHdmrs
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.symbolAllocationMask2string

            % Configure carrier.
            carrier = srsConfigureCarrier;

            % Prepare PRB set.
            PRBSet = 0:(NumPRB-1);

            % Configure PUSCH.
            pusch = srsConfigurePUSCH(NumLayers, Modulation, PRBSet);
            pusch.DMRS.DMRSConfigurationType = DMRSConfigurationType;
            pusch.DMRS.DMRSAdditionalPosition = 3;

            [~, puschInfo] = nrPUSCHIndices(carrier, pusch);

            numPRB = length(pusch.PRBSet);

            tbs = nrTBS(pusch.Modulation, ...
                pusch.NumLayers, ...
                numPRB, ...
                puschInfo.NREPerPRB, ...
                targetCodeRate);

            ulschInfo = nrULSCHInfo(pusch, targetCodeRate, tbs, ...
                nofHarqAckBits, nofCsiPart1Bits, nofCsiPart2Bits);

            % Generate modulation cheme type string.
            switch pusch.Modulation
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

            % Generate DM-RS symbol mask
            dmrsSymbolMask = symbolAllocationMask2string(puschDMRSIndices);

            % Generate DM-RS type string.
            dmrsTypeString = sprintf('dmrs_config_type::type%d', pusch.DMRS.DMRSConfigurationType);

            % Generate base graph type string.
            baseGraphString = ['ldpc_base_graph_type::BG', num2str(ulschInfo.BGN)];

            ulschConfiguration = {...
                tbs, ...                                % tbs
                modString, ...                          % modulation
                targetCodeRate, ...                     % target_Code_rate
                nofHarqAckBits, ...                     % nof_harq_ack_bits
                nofCsiPart1Bits, ...                    % nof_csi_part1_bits
                nofCsiPart2Bits, ...                    % nof_csi_part2_bits
                pusch.UCIScaling, ...                   % alpha_scaling
                pusch.BetaOffsetACK, ...                % harq_ack_beta_offset
                pusch.BetaOffsetCSI1, ...               % harq_csi_part1_offset
                pusch.BetaOffsetCSI2, ...               % harq_csi_part2_offset
                numPRB, ...                             % nof_rb
                pusch.SymbolAllocation(1), ...          % start_symbol_index
                pusch.SymbolAllocation(2), ...          % nof_symbols
                dmrsTypeString, ...                     % dmrs_type
                dmrsSymbolMask, ...                     % dmrs_symbol_mask
                pusch.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                pusch.NumLayers, ...                    % nof_layers
                };

            schInformation = {...
                ulschInfo.L, ...     % tb_crc_size
                baseGraphString, ... % base_graph
                ulschInfo.C, ...     % nof_cb
                ulschInfo.F, ...     % nof_filler_bits_per_cb
                ulschInfo.Zc, ...    % lifting_size
                ulschInfo.K, ...     % nof_bits_per_cb
                };

            ulschInformation = {...
                schInformation, ...    % sch
                ulschInfo.GULSCH, ...  % nof_ul_sch_bits
                ulschInfo.GACK, ...    % nof_harq_ack_bits
                ulschInfo.GACKRvd, ... % nof_harq_ack_bits
                ulschInfo.GCSI1, ...   % nof_csi_part1_bits
                ulschInfo.GCSI2, ...   % nof_csi_part2_bits
                ulschInfo.QdACK, ...   % nof_harq_ack_re
                ulschInfo.QdCSI1, ...  % nof_csi_part1_re
                ulschInfo.QdCSI2, ...  % nof_csi_part2_re
                };
                       
            testCaseCell = {...
                ulschConfiguration, ... % config
                ulschInformation, ...   % info
                };

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                sprintf("%s,\n", cellarray2str(testCaseCell, true)));

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHProcessorUnittest
