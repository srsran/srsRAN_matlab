%srsPUSCHProcessorUnittest Unit tests for PUSCH processor functions.
%   This class implements unit tests for the PUSCH symbol processor
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with 
%      testCase = srsPUSCHProcessorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUSCHProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUSCHProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHProcessorUnittest Properties (TestParameter):
%
%   BWPConfig        - BWP configuration to use.
%   Modulation       - Modulation scheme.
%   SymbolAllocation - PUSCH start symbol index and number of symbols.
%   targetCodeRate   - UL-SCH rate matching Target code rate.
%   nofHarqAck       - Number of HARQ-ACK feedback bits multiplexed.
%   nofCsiPart1      - Number of CSI-Part1 report bits multiplexed.
%   nofCsiPart2      - Number of CSI-Part2 report bits multiplexed.
%
%   srsPUSCHProcessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUSCHProcessorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPUSCHProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pusch_deProcessor' tests will be erased).
        outputPath = {['testPUSCHProcessor', ...
            char(datetime('now', 'Format', 'yyyyMMddHH''T''hhmmss'))]}
    end

    properties (TestParameter)
        %BWP configuration.
        %   The bandwidth part is described by a two-element array with the starting
        %   PRB and the total number of PRBs (1...14).
        %   Example: [0, 25].
        BWPConfig = {[0, 25], [0, 52], [0, 106]}

        %Modulation {pi/2-BPSK, QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'}

        %Symbols allocated to the PUSCH transmission.
        %   The symbol allocation is described by a two-element array with the starting
        %   symbol (0...13) and the length (1...14) of the PUSCH transmission.
        %   Example: [0, 14].
        SymbolAllocation = {[0, 14]}

        %Target code rate.
        targetCodeRate = {0.1, 0.5, 0.8}

        %Number of HARQ-ACK bits multiplexed with the message.
        nofHarqAck = {0, 1, 10}

        %Number of CSI-Part1 bits multiplexed with the message.
        nofCsiPart1 = {0};

        %Number of CSI-Part2 bits multiplexed with the message.
        nofCsiPart2= {0};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pusch_processor.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_estimation.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            
            fprintf(fileID, 'struct test_case_context {\n');
            fprintf(fileID, '  unsigned               rg_nof_rb;\n');
            fprintf(fileID, '  unsigned               rg_nof_symb;\n');
            fprintf(fileID, '  pusch_processor::pdu_t config;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  test_case_context    context;\n');
            fprintf(fileID, '  file_vector<cf_t>    grid;\n');
            fprintf(fileID, '  file_vector<uint8_t> sch_data;\n');
            fprintf(fileID, '  file_vector<uint8_t> harq_ack;\n');
            fprintf(fileID, '  file_vector<uint8_t> csi_part1;\n');
            fprintf(fileID, '  file_vector<uint8_t> csi_part2;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (TestClassSetup)
        function classSetup(testCase)
            orig = rng;
            testCase.addTeardown(@rng,orig)
            rng('default');
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, BWPConfig, Modulation, SymbolAllocation, targetCodeRate, nofHarqAck, nofCsiPart1, nofCsiPart2)
        %testvectorGenerationCases Generates test vectors with permutations
        %   of the BWP configuration, modulation, symbol allocation, target
        %   code rate, number of HARQ-ACK, CSI-Part1 and CSI-Part2
        %   information bits. Other parameters such as physical cell
        %   identifier, slot number, RNTI, scrambling identifiers,
        %   frequency allocation and DM-RS additional positions are
        %   selected randomly.
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeComplexFloatFile

            % Minimum number of PRB is one if two or less UCI bits are 
            % multiplexed. Otherwise, 10 PRB.
            MinNumPrb = 1;
            if nofHarqAck + nofCsiPart1 + nofCsiPart2 > 2
                MinNumPrb = 10;
            end

            % Select carrier configuration.
            NCellID = randi([0, 1007]);
            NSizeGrid = BWPConfig(2);
            NStartGrid = BWPConfig(1);

            % Generate carrier configuration.
            carrier = srsConfigureCarrier(NCellID, NSizeGrid, NStartGrid);

            % Random parameters.
            NSlot = randi([0, carrier.SlotsPerFrame]);
            RNTI = randi([1, 65535]);
            NID = randi([0, 1023]);
            PrbStart = randi([0, NSizeGrid - MinNumPrb]);
            NumPrb = randi([MinNumPrb, NSizeGrid - PrbStart]);
            DMRSAdditionalPosition = randi([0, 3]);
            NIDNSCID = randi([0, 65535]);
            NSCID = randi([0, 1]);

            % Fix parameters.
            rv = 0;

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate PUSCH configuration.
            pusch = srsConfigurePUSCH(Modulation, SymbolAllocation, RNTI, NID);

            % Set parameters.
            carrier.NSlot = NSlot;
            pusch.PRBSet = PrbStart + (0:NumPrb - 1);
            pusch.DMRS.DMRSAdditionalPosition = DMRSAdditionalPosition;
            pusch.DMRS.NIDNSCID = NIDNSCID;
            pusch.DMRS.NSCID = NSCID;

            % Generate PUSCH resource grid indices.
            [puschResourceIndices, puschInfo] = nrPUSCHIndices(carrier, pusch);

            % Generate PUSCH DM-RS resource grid indices.
            puschDmrsIndices = nrPUSCHDMRSIndices(carrier, pusch);

            % Select a valid TBS.
            tbs = nrTBS(pusch.Modulation, pusch.NumLayers, length(pusch.PRBSet), puschInfo.NREPerPRB, targetCodeRate);

            % Generate UL-SCH information.
            ulschInfo = nrULSCHInfo(pusch, targetCodeRate, tbs, nofHarqAck, nofCsiPart1, nofCsiPart2);

            % Generate random data.
            schData = randi([0, 1], tbs, 1);
            harqAck = randi([0, 1], nofHarqAck, 1);
            csiPart1 = randi([0, 1], nofCsiPart1, 1);
            csiPart2 = randi([0, 1], nofCsiPart2, 1);

            % Encode data.
            encUL = nrULSCH;
            encUL.TargetCodeRate = targetCodeRate;
            setTransportBlock(encUL, schData);
            EncSchData = encUL(Modulation, pusch.NumLayers, ...
                ulschInfo.GULSCH, rv);
            EncHarqAck = nrUCIEncode(harqAck, ulschInfo.GACK, Modulation);
            EncCsiPart1 = nrUCIEncode(csiPart1, ulschInfo.GCSI1, Modulation);
            EncCsiPart2 = nrUCIEncode(csiPart2, ulschInfo.GCSI2, Modulation);

            % Multiplex data and UCI.
            codeword = nrULSCHMultiplex(pusch, targetCodeRate, tbs, ...
                EncSchData, EncHarqAck, EncCsiPart1, EncCsiPart2);

            % Create resource grid.
            grid = nrResourceGrid(carrier);

            % Modulate data.
            grid(puschResourceIndices) = nrPUSCH(carrier, pusch, codeword);

            % Insert DM-RS.
            betaDMRS = 10 ^ (3 / 20);
            grid(puschDmrsIndices) = nrPUSCHDMRS(carrier, pusch) * betaDMRS;

            % Generate channel estimates. As a phase rotation in frequency
            % domain.
            gridDims = size(grid);
            ce = transpose(ones(gridDims(2), 1) * exp(1i * linspace(0, 2 * pi, gridDims(1))));

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-snrdB / 20);

            % Emulate channel.
            rxGrid = ce .* grid + noiseStdDev * (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

            % Write the entire resource grid in a file.
            testCase.saveDataFile('_test_input_grid', testID, ...
                @writeComplexFloatFile, rxGrid);

            % Write the SCH data.
            testCase.saveDataFile('_test_output_tb', testID, ...
                @writeUint8File, bitPack(schData));

            % Write the HARQ-ACK data.
            testCase.saveDataFile('_test_output_harq', testID, ...
                @writeUint8File, harqAck);

            % Write the CSI-Part1 data.
            testCase.saveDataFile('_test_output_csi1', testID, ...
                @writeUint8File, csiPart1);

            % Write the CSI-Part2 data.
            testCase.saveDataFile('_test_output_csi2', testID, ...
                @writeUint8File, csiPart2);

            % Convert cyclic prefix to string.
            cyclicPrefixStr = ['cyclic_prefix::', upper(carrier.CyclicPrefix)];


            if iscell(pusch.Modulation)
                error('Unsupported');
            else
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
            end

            % Slot configuration.
            slotConfig = {log2(carrier.SubcarrierSpacing/15), carrier.NSlot};

            % Generate DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(...
                nrPUSCHDMRSIndices(carrier, pusch, 'IndexStyle', ...
                'subscript', 'IndexBase', '0based'));

            % Reception port list.
            portsString = '{0}';

            % Generate Resource Block allocation string.
            RBAllocationString = rbAllocationIndexes2String(pusch.PRBSet);

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', pusch.DMRS.DMRSConfigurationType);
            baseGraphString = ['ldpc_base_graph_type::BG', num2str(ulschInfo.BGN)];
            codewordDescription = {...
                rv, ...              % rv
                baseGraphString, ... % ldpc_base_graph
                'true', ...          % new_data
                };

            uciDescription = {...
                nofHarqAck, ...           % nof_harq_ack
                nofCsiPart1, ...          % nof_csi_part1
                nofCsiPart2, ...          % nof_csi_part2
                pusch.UCIScaling, ...     % alpha_scaling
                pusch.BetaOffsetACK, ...  % beta_offset_harq_ack
                pusch.BetaOffsetCSI1, ... % beta_offset_csi_part1
                pusch.BetaOffsetCSI2, ... % beta_offset_csi_part2
                };

            pduDescription = {...
                slotConfig, ...                               % slot
                pusch.RNTI, ...                               % rnti
                carrier.NSizeGrid, ...                        % bwp_size_rb
                carrier.NStartGrid, ...                       % bwp_start_rb
                cyclicPrefixStr, ...                          % cp
                modString, ...                                % modulation
                targetCodeRate, ...                           % target_code_rate
                {codewordDescription}, ...                    % codeword
                uciDescription, ...                           % uci
                pusch.NID, ...                                % n_id
                pusch.NumAntennaPorts, ...                    % nof_tx_layers
                portsString, ...                              % rx_ports
                dmrsSymbolMask, ...                           % dmrs_symbol_mask
                dmrsTypeString, ...                           % dmrs
                pusch.DMRS.NIDNSCID, ...                      % scrambling_id
                pusch.DMRS.NSCID, ...                         % n_scid
                pusch.DMRS.NumCDMGroupsWithoutData, ...       % nof_cdm_groups_without_data
                RBAllocationString, ...                       % freq_alloc
                pusch.SymbolAllocation(1), ...                % start_symbol_index
                pusch.SymbolAllocation(2), ...                % nof_symbols
                'ldpc::MAX_CODEBLOCK_SIZE / 8', ...           % tbs_lbrm_bytes
                };

            contextDescription = {...
                carrier.NSizeGrid, ...      % rg_nof_rb
                carrier.SymbolsPerSlot, ... % rg_nof_symbols
                pduDescription, ...         % config
                };

            % Generate PUSCH transmission entry
            testCaseString = testCase.testCaseToString(testID, ...
                contextDescription, true, '_test_input_grid', ...
                '_test_output_tb', '_test_output_harq', ...
                '_test_output_csi1', '_test_output_csi2');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHProcessorUnittest
