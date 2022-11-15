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
%   SymbolAllocation  - Symbols allocated to the PUSCH transmission.
%   Modulation        - Modulation scheme.
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
        outputPath = {['testPUSCHProcessor', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Modulation {pi/2-BPSK, QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};

        %Symbols allocated to the PUSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol {0, ..., 13} and the length 
        %   {1, ..., 14} of the PUSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14]}

        %Probability of a Resource element to contain a placeholder.
        targetCodeRate = {0.1, 0.5, 0.8}

        %Number of HARQ-ACK bits multiplexed with the message.
%         nofHarqAck = {0, 1, 2, 10}
        nofHarqAck = {0}

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
            fprintf(fileID, 'struct fix_reference_channel_slot {\n');
            
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
        function testvectorGenerationCases(testCase, Modulation, SymbolAllocation, targetCodeRate, nofHarqAck, nofCsiPart1, nofCsiPart2)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme. Other parameters (e.g., the RNTI)
        %   are generated randomly.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID
            testID = testCase.generateTestID;

            % Generate carrier configuration.
            NCellID = randi([0, 1007]);
            carrier = srsConfigureCarrier(NCellID);
            carrier.NSlot = randi([0, carrier.SlotsPerFrame]);

            PrbStart = randi([0, carrier.NSizeGrid - 1]);
            NumPrb = randi([1, carrier.NSizeGrid - PrbStart]);

            % Generate PUSCH configuration.
            RNTI = randi([1, 65535]);
            NID = randi([0, 1023]);
            pusch = srsConfigurePUSCH(Modulation, SymbolAllocation, RNTI, NID);
            pusch.PRBSet = PrbStart + (0:NumPrb - 1);
            pusch.DMRS.DMRSAdditionalPosition = randi([0, 3]);
            pusch.DMRS.NIDNSCID = randi([0, 65535]);
            pusch.DMRS.NSCID = randi([0, 1]);

            % Generate PUSCH resource grid indices.
            [puschResourceIndices, puschInfo] = nrPUSCHIndices(carrier, ...
                pusch);

            % Generate PUSCH DM-RS resource grid indices.
            puschDmrsIndices = nrPUSCHDMRSIndices(carrier, pusch);

            % Select a valid TBS.
            tbs = nrTBS(pusch.Modulation, pusch.NumLayers, ...
                length(pusch.PRBSet), puschInfo.NREPerPRB, targetCodeRate);

            % Generate UL-SCH information.
            ulschInfo = nrULSCHInfo(pusch, targetCodeRate, tbs, ...
                nofHarqAck, nofCsiPart1, nofCsiPart2);

            % Generate random data.
            schData = randi([0, 1], tbs, 1);
            harqAck = randi([0, 1], nofHarqAck, 1);
            csiPart1 = randi([0, 1], nofCsiPart1, 1);
            csiPart2 = randi([0, 1], nofCsiPart2, 1);

            % Encode data.
            encUL = nrULSCH;
            encUL.TargetCodeRate = targetCodeRate;
            rv = 0;
            setTransportBlock(encUL, schData);
            EncSchData = encUL(Modulation, pusch.NumLayers, ...
                ulschInfo.GULSCH, rv);
            EncHarqAck = nrUCIEncode(harqAck, ulschInfo.GACK, pusch.Modulation);
            EncCsiPart1 = nrUCIEncode(csiPart1, ulschInfo.GCSI1, pusch.Modulation);
            EncCsiPart2 = nrUCIEncode(csiPart2, ulschInfo.GCSI2, pusch.Modulation);

            % Multiplex data and UCI.
            codeword = nrULSCHMultiplex(pusch, targetCodeRate, tbs, ...
                EncSchData, EncHarqAck, EncCsiPart1, EncCsiPart2);

            % Create resource grid.
            grid = nrResourceGrid(carrier);

            % Modulate data.
            grid(puschResourceIndices) = nrPUSCH(carrier, pusch, codeword);

            % Insert DM-RS.
            betaDmrs = 10 ^ (3 / 20);
            grid(puschDmrsIndices) = nrPUSCHDMRS(carrier, pusch) * betaDmrs;

            % Generate channel estimates. As a phase rotation in frequency
            % domain.
            gridDims = size(grid);
            ce = transpose(ones(gridDims(2), 1) * exp(1i * linspace(0, 2 * pi, gridDims(1))));

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-(snrdB + 3) / 20);

            % Emulate channel.
            rxGrid = ce .* grid + noiseStdDev * (randn(gridDims) + 1i * randn(gridDims));

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

            % Convert cyclic prefix to string
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

            pduDescription = {...
                slotConfig, ...                               % slot
                pusch.RNTI, ...                               % rnti
                carrier.NSizeGrid, ...                        % bwp_size_rb
                carrier.NStartGrid, ...                       % bwp_start_rb
                cyclicPrefixStr, ...                          % cp
                modString, ...                                % modulation
                targetCodeRate, ...                           % target_code_rate
                {codewordDescription}, ...                    % codeword
                {}, ...                                       % uci
                pusch.NID, ...                                % n_id
                pusch.NumAntennaPorts, ...                    % nof_tx_layers
                portsString, ...                              % rx_ports
                dmrsSymbolMask, ...                           % dmrs_symb_pos
                dmrsTypeString, ...                           % dmrs_config_type
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
