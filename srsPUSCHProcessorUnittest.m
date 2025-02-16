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
%                   (i.e., 'phy/upper/channel_processors/pusch').
%
%   srsPUSCHProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHProcessorUnittest Properties (TestParameter):
%
%   SymbolAllocation - PUSCH start symbol index and number of symbols.
%   nofHarqAck       - Number of HARQ-ACK feedback bits multiplexed.
%   nofCsiBits       - Number of CSI-Part1 and CSI-Part2 report bits multiplexed.
%   NumRxPorts       - Number of receive antenna ports for PUSCH.
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
%   See also matlab.unittest.

%   Copyright 2021-2025 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

classdef srsPUSCHProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pusch'

        %List of possible BWP sizes.
        BWPSizes = [50, 75, 100, 150, 200, 250, 270]

        %Valid number of RB that accept transform precoding.
        ValidNumPRB = [...
               1,   2,   3,   4,   5,   6,   8,   9,  10,  12,  15,  16,...
              18,  20,  24,  25,  27,  30,  32,  36,  40,  45,  48,  50,...
              54,  60,  64,  72,  75,  80,  81,  90,  96, 100, 108, 120,...
             125, 128, 135, 144, 150, 160, 162, 180, 192, 200, 216, 225,...
             240, 243, 250, 256, 270]
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pusch_processor' tests will be erased).
        outputPath = {['testPUSCHProcessor', ...
            char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Symbols allocated to the PUSCH transmission.
        %   The symbol allocation is described by a two-element array with the starting
        %   symbol (0...13) and the length (1...14) of the PUSCH transmission.
        %   Example: [0, 14].
        SymbolAllocation = {[0, 14]}

        %Number of HARQ-ACK bits multiplexed with the message.
        nofHarqAck = {0, 1, 10}

        %Number of CSI Part 1 and Part 2 bits multiplexed with the message.
        %   CSI Part 2 must be present with CSI Part 1.
        nofCsiBits = {[0, 0], [4, 0], [5, 1]};

        %Number of receive antenna ports for PUSCH.
        NumRxPorts = {1, 2, 4};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pusch/pusch_processor.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_estimation.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_context {\n');
            fprintf(fileID, '  unsigned               rg_nof_rb;\n');
            fprintf(fileID, '  unsigned               rg_nof_symb;\n');
            fprintf(fileID, '  pusch_processor::pdu_t config;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  test_case_context                                       context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    sch_data;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    harq_ack;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    csi_part1;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    csi_part2;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'using csi_part2_size = uci_part2_size_description;\n\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, ...
                nofHarqAck, nofCsiBits, NumRxPorts)
        %testvectorGenerationCases Generates test vectors with permutations
        %   of the symbol allocation, number of HARQ-ACK, CSI-Part1 and
        %   CSI-Part2 information bits, and number of receive ports. Other
        %   parameters such as physical cell identifier, BWP dimensions,
        %   slot number, RNTI, scrambling identifiers, frequency allocation
        %   and DM-RS additional positions are randomly selected.
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.bitPack
            import srsTest.helpers.mcsDescription2Cell
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Select a random cell ID.
            nCellID = randi([0, 1007]);

            % Extract the number of CSI Part 1 and 2 message bits.
            nofCsiPart1 = nofCsiBits(1);
            nofCsiPart2 = nofCsiBits(2);

            % Minimum number of PRB. It increases when UCI needs to be
            % multiplexed on the PUSCH resources.
            minNumPrb = 1 + (nofHarqAck + nofCsiPart1 + nofCsiPart2);

            % Maximum number of PRB of a 5G NR resource grid.
            maxGridBW = max(testCase.BWPSizes);

            % Randomly select BWP start and size values that satisfy the
            % size constraints. 
            BWPSize = testCase.BWPSizes(randi([1, numel(testCase.BWPSizes)]));
            BWPStart = randi([0, maxGridBW - BWPSize]);

            nSizeGrid = BWPStart + BWPSize;
            nStartGrid = 0;

            % PUSCH PRB start within the BWP.
            prbStart = randi([0, BWPSize - minNumPrb]);

            % Fix a maximum number of PRB allocated to PUSCH to limit the
            % size of the test vectors.
            maxNumPrb = BWPSize - prbStart;

            % Select a valid number of PRB allocated to PUSCH.
            validNumPrb = testCase.ValidNumPRB((testCase.ValidNumPRB >= minNumPrb) & (testCase.ValidNumPRB <= maxNumPrb));
            numPrb = validNumPrb(randi([1, numel(validNumPrb)]));

            % Random modulation.
            modulationOpts = {'QPSK', '16QAM', '64QAM', '256QAM'};
            modulation = modulationOpts{randi([1, 4])};

            % Random target code rate between 0.1 to 0.7.
            targetCodeRate = 0.6 * rand() + 0.1;

            % Generate carrier configuration.
            carrier = nrCarrierConfig( ...
                NCellID=nCellID, ...
                NSizeGrid=nSizeGrid, ...
                NStartGrid=nStartGrid ...
                );

            % Random parameters.
            nSlot = randi([0, carrier.SlotsPerFrame]);
            RNTI = randi([1, 65535]);
            nID = randi([0, 1023]);
            DMRSAdditionalPosition = randi([0, 3]);
            NIDNSCID = randi([0, 65535]);
            NSCID = randi([0, 1]);
            NRSID = randi([0, 1007]);
            DCPosition = randi(12 * [prbStart, prbStart + numPrb]) + BWPStart;
            transformPrecoding = randi([0, 1]);

            % Fix parameters.
            rv = 0;

            % Generate PUSCH configuration.
            pusch = nrPUSCHConfig( ...
                Modulation=modulation, ...
                SymbolAllocation=SymbolAllocation, ...
                RNTI=RNTI, ...
                NID=nID...
                );

            % Set parameters.
            carrier.NSlot = nSlot;
            pusch.NStartBWP = BWPStart;
            pusch.NSizeBWP = BWPSize;
            pusch.PRBSet = prbStart + (0:numPrb - 1);
            pusch.DMRS.DMRSAdditionalPosition = DMRSAdditionalPosition;
            pusch.DMRS.NIDNSCID = NIDNSCID;
            pusch.DMRS.NSCID = NSCID;
            pusch.DMRS.NRSID = NRSID;
            pusch.TransformPrecoding = transformPrecoding;

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
            encSchData = encUL(modulation, pusch.NumLayers, ...
                ulschInfo.GULSCH, rv);
            encHarqAck = nrUCIEncode(harqAck, ulschInfo.GACK, modulation);
            encCsiPart1 = nrUCIEncode(csiPart1, ulschInfo.GCSI1, modulation);
            encCsiPart2 = nrUCIEncode(csiPart2, ulschInfo.GCSI2, modulation);

            % Multiplex data and UCI.
            codeword = nrULSCHMultiplex(pusch, targetCodeRate, tbs, ...
                encSchData, encHarqAck, encCsiPart1, encCsiPart2);

            % Create resource grid.
            grid = nrResourceGrid(carrier);

            % Modulate and map data.
            grid(puschResourceIndices) = nrPUSCH(carrier, pusch, codeword);

            % Insert DM-RS.
            betaDMRS = 10 ^ (3 / 20);
            grid(puschDmrsIndices) = nrPUSCHDMRS(carrier, pusch) * betaDMRS;

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-snrdB / 20);

            % Add the number of receive ports to the receive grid
            % dimensions.
            rxGridDims = [size(grid) NumRxPorts];

            ce = complex(nan(rxGridDims));
            rxGrid = complex(nan(rxGridDims));

            for iPort = 1 : NumRxPorts
                % Add a random phase offset to each Rx port.
                startPhase = 2 * pi * rand();

                % Phase of the last subcarrier in the grid.
                endPhase = startPhase + (2 * pi);

                % Generate channel estimates as a phase rotation in frequency
                % domain.
                ce(:, :, iPort) = transpose(ones(rxGridDims(2), 1) * ...
                    exp(1i * linspace(startPhase, endPhase, rxGridDims(1))));

                % Emulate channel frequency response.
                rxGrid(:, :, iPort) = ce(:, :, iPort) .* grid;
            end

            % Add channel noise to all receive ports.
            rxGrid = rxGrid + noiseStdDev * (randn(rxGridDims) + 1i * randn(rxGridDims)) / sqrt(2 * NumRxPorts);

            % Add a symbolic DC leakage.
            rxGrid(DCPosition + 1, :) = rxGrid(DCPosition + 1, :) + 1;

            % Grid indices for a single receive port in subscript form.
            rxGridPortIndexes = [nrPUSCHIndices(carrier, pusch, 'IndexStyle','subscript', 'IndexBase','0based'); ...
                nrPUSCHDMRSIndices(carrier, pusch, 'IndexStyle','subscript', 'IndexBase','0based')];

            % Number of PUSCH Resource Elements per port, including DM-RS.
            nofREPort = size(rxGridPortIndexes, 1);

            % Generate the Rx resource grid indices for all receive ports.
            rxGridIndices = zeros(nofREPort * NumRxPorts, 3);
            for iPort = 0 : (NumRxPorts - 1)
                % Copy the subcarrier and OFDM symbol index coordinates.
                rxGridIndices(((nofREPort * iPort) + 1) : (nofREPort * (iPort + 1)), :) = ...
                    rxGridPortIndexes;

                % Generate the receive port index coordinates.
                rxGridIndices(((nofREPort * iPort) + 1) : (nofREPort * (iPort + 1)), 3) = ...
                 iPort * ones(nofREPort, 1);
            end

            % Convert the subscript indices to one-based linear form.
            rxGridLinIndices = sub2ind(rxGridDims, rxGridIndices(:, 1) + 1, ...
                rxGridIndices(:, 2) + 1, rxGridIndices(:, 3) + 1);

            % Extract the elements of interest from the grid.
            rxGridSymbols = rxGrid(rxGridLinIndices);

            % Write the entire resource grid to a file.
            testCase.saveDataFile('_test_input_grid', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndices);

            % Write the SCH data.
            testCase.saveDataFile('_test_tb', testID, ...
                @writeUint8File, bitPack(schData));

            % Write the HARQ-ACK data.
            testCase.saveDataFile('_test_harq', testID, ...
                @writeUint8File, harqAck);

            % Write the CSI-Part1 data.
            testCase.saveDataFile('_test_csi1', testID, ...
                @writeUint8File, csiPart1);

            % Write the CSI-Part2 data.
            testCase.saveDataFile('_test_csi2', testID, ...
                @writeUint8File, csiPart2);

            % Convert cyclic prefix to string.
            cyclicPrefixStr = ['cyclic_prefix::', upper(carrier.CyclicPrefix)];

            % Slot configuration.
            slotConfig = {log2(carrier.SubcarrierSpacing/15), carrier.NSlot};

            % Generate DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(...
                nrPUSCHDMRSIndices(carrier, pusch, 'IndexStyle', ...
                'subscript', 'IndexBase', '0based'));

            % Reception port list.
            portsString = cellarray2str(num2cell(0 : (NumRxPorts - 1)), true);

            % Generate Resource Block allocation string.
            RBAllocationString = rbAllocationIndexes2String(pusch.PRBSet);

            % Prepare codeblock for the limited buffer rate matcher.
            TBSLBRM = nrTBS('256QAM', 4, 273, 156, 948 / 1024) / 8;
            TBSLBRMStr = ['units::bytes(' num2str(TBSLBRM) ')'];

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', pusch.DMRS.DMRSConfigurationType);
            baseGraphString = ['ldpc_base_graph_type::BG', num2str(ulschInfo.BGN)];
            codewordDescription = {...
                rv, ...              % rv
                baseGraphString, ... % ldpc_base_graph
                'true', ...          % new_data
                };

            csiPart2Size = sprintf('csi_part2_size(%d)', nofCsiPart2);

            uciDescription = {...
                nofHarqAck, ...           % nof_harq_ack
                nofCsiPart1, ...          % nof_csi_part1
                csiPart2Size, ...         % nof_csi_part2
                pusch.UCIScaling, ...     % alpha_scaling
                pusch.BetaOffsetACK, ...  % beta_offset_harq_ack
                pusch.BetaOffsetCSI1, ... % beta_offset_csi_part1
                pusch.BetaOffsetCSI2, ... % beta_offset_csi_part2
                };

            mcsDescr = mcsDescription2Cell(pusch.Modulation, targetCodeRate);

            if transformPrecoding == 0
                DMRSConfig = {...
                    dmrsTypeString, ...                     % dmrs
                    pusch.DMRS.NIDNSCID, ...                % scrambling_id
                    pusch.DMRS.NSCID, ...                   % n_scid
                    pusch.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                    };
                DMRSDescr = ['pusch_processor::dmrs_configuration('...
                    cellarray2str(DMRSConfig, true)...
                    ')'];
            else
                DMRSConfig = {...
                    pusch.DMRS.NRSID, ... % n_rs_id
                    };
                DMRSDescr = ['pusch_processor::dmrs_transform_precoding_configuration('...
                    cellarray2str(DMRSConfig, true)...
                    ')'];
            end

            pduDescription = {...
                'std::nullopt', ...                           % context
                slotConfig, ...                               % slot
                pusch.RNTI, ...                               % rnti
                pusch.NSizeBWP, ...                           % bwp_size_rb
                pusch.NStartBWP, ...                          % bwp_start_rb
                cyclicPrefixStr, ...                          % cp
                mcsDescr, ...                                 % mcs_descr
                {codewordDescription}, ...                    % codeword
                uciDescription, ...                           % uci
                pusch.NID, ...                                % n_id
                pusch.NumAntennaPorts, ...                    % nof_tx_layers
                portsString, ...                              % rx_ports
                dmrsSymbolMask, ...                           % dmrs_symbol_mask
                DMRSDescr, ...                                % dmrs
                RBAllocationString, ...                       % freq_alloc
                pusch.SymbolAllocation(1), ...                % start_symbol_index
                pusch.SymbolAllocation(2), ...                % nof_symbols
                TBSLBRMStr, ...                               % tbs_lbrm
                DCPosition, ...                               % dc_position
                };

            contextDescription = {...
                carrier.NSizeGrid, ...      % rg_nof_rb
                carrier.SymbolsPerSlot, ... % rg_nof_symbols
                pduDescription, ...         % config
                };

            % Generate PUSCH transmission entry
            testCaseString = testCase.testCaseToString(testID, ...
                contextDescription, true, '_test_input_grid', ...
                '_test_tb', '_test_harq', ...
                '_test_csi1', '_test_csi2');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHProcessorUnittest
