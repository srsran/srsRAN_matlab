%srsPUCCHProcessorFormat2Unittest Unit tests for PUCCH Format 2 processor function.
%   This class implements unit tests for the PUCCH Format 2 processor function using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHProcessorFormat2Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHProcessorFormat2Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_processor_format2').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHProcessorFormat2Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHProcessorFormat2Unittest Properties (TestParameter):
%
%   SymbolAllocation - PUCCH Format 2 time allocation as array containing
%                      the start symbol index and the number of symbols.
%   nofHarqAck       - Number of bits of the HARQ-ACK payload.
%   nofSR            - Number of bits of the SR payload.
%   nofCSIPart1      - Number of bits of the CSI Part 1 payload.
%   nofCSIPart2      - Number of bits of the CSI Part 2 payload.
%   maxCodeRate      - Maximum code rate.
%
%   srsPUCCHProcessorFormat2Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat2Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

%   Copyright 2021-2024 Software Radio Systems Limited
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

classdef srsPUCCHProcessorFormat2Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format2'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format2' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat2', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (Constant, Hidden)
        %Number of Rx antenna ports.
        NumRxPorts = 4;
    end

    properties (Hidden)
        %Carrier configuration object.
        Carrier
        %PUCCH Format 2 configuration object.
        PUCCH
    end

    properties (TestParameter)

        %Symbols allocated to the PUCCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PUCCH transmission.
        SymbolAllocation = {[0, 1], [12, 2]};

        %Number of bits of the HARQ-ACK payload (1...7).
        nofHarqAck = {3, 7};

        %Number of bits of the SR payload (0...4).
        nofSR = {0, 1};

        %Number of bits of the CSI Part 1 payload.
        nofCSIPart1 = {0, 4, 6};

        %Number of bits of the CSI Part 2 payload.
        nofCSIPart2 = {0};

        %Maximum code rate, from TS38.311 Section 6.3.2, PUCCH-config
        %   information element (0.08, 0.15, 0.25, 0.35, 0.45, 0.6, 0.8).
        maxCodeRate = {0.08, 0.15, 0.25, 0.35, 0.45, 0.6};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  unsigned                               grid_nof_prb;\n');
            fprintf(fileID, '  unsigned                               grid_nof_symbols;\n');
            fprintf(fileID, '  pucch_processor::format2_configuration config;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                               context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    harq_ack;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    sr;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    csi_part_1;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    csi_part_2;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Access = private)
        function setupsimulation(testCase, SymbolAllocation, ...
                nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2, maxCodeRate)
        % Sets secondary simulation variables and MATLAB NR configuration objects.

            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsConfigurePUCCH

            % Generate random cell ID.
            NCellID = randi([0, 1007]);

            % Generate a random NID.
            NID = randi([0, 1023]);

            % Generate a random NID0 for DM-RS scrambling.
            NID0 = randi([0, 65535]);

            % Generate a random RNTI.
            RNTI = randi([1, 65535]);

            % Normal cyclic prefix.
            CyclicPrefix = 'normal';

            % No frequency hopping.
            FrequencyHopping = 'neither';

            % QPSK modulation has 2 bit per symbol.
            modulationOrder = 2;

            % Number of RE within a PUCCH Format 2 RB used for control data.
            dataREFormat2 = 8;

            % UCI payload size.
            nofUCIBits = nofHarqAck + nofSR + nofCSIPart1 + nofCSIPart2;

            % CRC bits added before coding.
            nofCRCBits = 0;
            if (nofUCIBits >= 12 && nofUCIBits < 20)
                nofCRCBits = 6;
            elseif (nofUCIBits >= 20)
                nofCRCBits = 11;
            end

            % Number of bits of the code block.
            nofCodeBlockBits = nofUCIBits + nofCRCBits;

            % Number of PRB used. It is obtained by computing the number
            % of bits in a codeword if the maximum code rate is used. The
            % obtained codeword length is used to derive the minimum number
            % of PRB required to fit the codeword into the PUCCH Format 2
            % resource.
            PRBNum = ceil(nofCodeBlockBits / ...
                (maxCodeRate * modulationOrder * dataREFormat2 * SymbolAllocation(2)));

            % Skip test cases where the UCI codeword does not fit into the
            % PUCCH Format 2 resources.
            assumeLessThanOrEqual(testCase, PRBNum, 16, 'UCI codeword won''t fit in the PUCCH Format 2 resources.');

            % Maximum resource grid size.
            MaxGridSize = 275;

            % Resource grid starts at CRB0.
            NStartGrid = 0;

            % BWP start relative to CRB0.
            NStartBWP = randi([0, MaxGridSize - PRBNum]);

            % BWP size. PUCCH Format 2 frequency allocation must fit inside
            % the BWP.
            NSizeBWP = randi([PRBNum, MaxGridSize - NStartBWP]);

            % PUCCH PRB Start relative to the BWP.
            PRBStart = randi([0, NSizeBWP - PRBNum]);

            % Fit resource grid size to the BWP.
            NSizeGrid = NStartBWP + NSizeBWP;

            % PRB set assigned to PUCCH Format 2 within the BWP.
            % Each element within the PRB set indicates the location of a
            % Resource Block relative to the BWP starting PRB.
            PRBSet = PRBStart : (PRBStart + PRBNum - 1);

            % Configure the carrier according to the test parameters.
            testCase.Carrier = srsConfigureCarrier(NCellID, NSizeGrid, ...
                NStartGrid, CyclicPrefix);

            % Configure the PUCCH Format 2
            testCase.PUCCH = srsConfigurePUCCH(2, NStartBWP, NSizeBWP, SymbolAllocation, ...
                 PRBSet, FrequencyHopping, NID, NID0, RNTI);
        end % of function setupsimulation(testCase, SymbolAllocation, ...

    end % methods (Access = private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, ...
                nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2, maxCodeRate)
        %testvectorGenerationCases Generates a test vector for the given
        %   Symbol allocation, HARQ-ACK, SR, CSI Part 1 and CSI Part 2 payload
        %   sizes in number of bits, and the maximum code rate. The Cell ID,
        %   NID, NID0 and RNTI are randomly generated. The number of allocated
        %   PRBs is determined based on the UCI payload size and maximum code
        %   rate.

            import srsLib.phy.upper.channel_modulation.srsDemodulator
            import srsLib.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            testCase.setupsimulation(SymbolAllocation, nofHarqAck, nofSR, nofCSIPart1, ...
                nofCSIPart2, maxCodeRate);

            % Define some aliases.
            carrier = testCase.Carrier;
            pucch = testCase.PUCCH;
            numRxPorts = testCase.NumRxPorts;

            [grid, payloads, pucchDataIndices, pucchDmrsIndices] = createTxGrid(carrier, pucch, ...
                nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2);

            UCIPayload = payloads.UCIPayload;
            harqAckPayload = payloads.harqAckPayload;
            SRPayload = payloads.SRPayload;
            CSI1Payload = payloads.CSI1Payload;
            CSI2Payload = payloads.CSI2Payload;

            % Init received signals.
            rxGrid = nrResourceGrid(carrier, numRxPorts, "OutputDataType", "single");
            dataChEsts = complex(nan(length(pucchDataIndices), numRxPorts));
            rxSymbols = complex(nan(length(pucchDataIndices), numRxPorts));

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-snrdB / 20);
            noiseVar = noiseStdDev.^2;

            gridDims = size(grid);

            % Iterate each receive port.
            for iRxPort = 1:numRxPorts
                % Create some noise samples.
                normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

                % Generate channel estimates as a phase rotation in the
                % frequency domain.
                estimates = exp(1i * linspace(0, 2 * pi, gridDims(1))') * ones(1, gridDims(2));

                % Create noisy modulated symbols.
                rxGrid(:, :, iRxPort) = estimates .* grid + (noiseStdDev * normNoise);

                % Extract PUCCH symbols from the received grid.
                rxSymbols(:, iRxPort) = rxGrid(pucchDataIndices);

                % Extract perfect channel estimates corresponding to the PUCCH.
                dataChEsts(:, iRxPort) = estimates(pucchDataIndices);
            end
            % Equalize channel symbols.
            [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, dataChEsts, 'ZF', noiseVar, 1);

            % Convert equalized symbols into softbits.
            schSoftBits = srsDemodulator(eqSymbols(:), 'QPSK', eqNoiseVars(:));

            % Scrambling sequence for PUCCH.
            [scSequence, ~] = nrPUCCHPRBS(pucch.NID, pucch.RNTI, length(schSoftBits));

            % Encode the scrambling sequence into the sign, so it can be
            % used with soft bits.
            scSequence = -(scSequence * 2) + 1;

            % Apply descrambling.
            schSoftBits = schSoftBits .* scSequence;

            % Decode UCI message to check for errors.
            nofUCIBits = nofHarqAck + nofSR + nofCSIPart1 + nofCSIPart2;
            rxUCIPayload = nrUCIDecode(schSoftBits, nofUCIBits);

            assert(isequal(rxUCIPayload, UCIPayload), ...
                'srsran_matlab:srsPUCCHProcessorFormat2Unittest', ...
                'Decoded UCI payload has errors');

            % Extract the elements of interest from the grid.
            nofRePort = length(pucchDataIndices) + length(pucchDmrsIndices);
            rxGridSymbols = complex(nan(1, numRxPorts * nofRePort));
            rxGridIndexes = complex(nan(numRxPorts * nofRePort, 3));
            onePortindexes = [nrPUCCHIndices(carrier, pucch, 'IndexStyle','subscript', 'IndexBase','0based'); ...
                    nrPUCCHDMRSIndices(carrier, pucch, 'IndexStyle','subscript', 'IndexBase','0based')];
            for iRxPort = 0:(numRxPorts - 1)
                offset = iRxPort * nofRePort;
                rxGridSymbols(offset + (1:nofRePort)) = [rxGrid(pucchDataIndices); rxGrid(pucchDmrsIndices)];

                indexes = onePortindexes;
                indexes(:,3) = iRxPort;

                rxGridIndexes(offset + (1:nofRePort), :) = indexes;
            end

            % Write the entire resource grid in a file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndexes);

            % Write HARQ-ACK payload to a binary file.
            testCase.saveDataFile('_test_harq', testID, @writeUint8File, harqAckPayload);

            % Write SR payload to a binary file.
            testCase.saveDataFile('_test_sr', testID, @writeUint8File, SRPayload);

            % Write CSI Part 1 payload to a binary file.
            testCase.saveDataFile('_test_csi1', testID, @writeUint8File, CSI1Payload);

            % Write CSI Part 2 payload to a binary file.
            testCase.saveDataFile('_test_csi2', testID, @writeUint8File, CSI2Payload);

            % Reception port list.
            portsString = ['{' num2str(0:(numRxPorts-1), "%d,") '}'];

            % Slot configuration.
            slotConfig = {log2(carrier.SubcarrierSpacing/15), carrier.NSlot};

            % Convert cyclic prefix to string.
            cyclicPrefixStr = matlab2srsCyclicPrefix(carrier.CyclicPrefix);

            % Generate PUCCH Format 2 configuration.
            pucchF2Config = {...
                'nullopt', ...           % context
                slotConfig, ...          % slot
                cyclicPrefixStr, ...     % cp
                portsString, ...         % rx_ports
                pucch.NSizeBWP, ...      % bwp_size_rb
                pucch.NStartBWP, ...     % bwp_start_rb
                pucch.PRBSet(1), ...     % starting_prb
                {}, ...                  % second_hop_prb
                numel(pucch.PRBSet), ... % nof_prb
                SymbolAllocation(1), ... % start_symbol_index
                SymbolAllocation(2), ... % nof_symbols
                pucch.RNTI, ...          % rnti
                pucch.NID, ...           % n_id
                pucch.NID0, ...          % n_id_0
                nofHarqAck, ...          % nof_harq_ack
                nofSR, ...               % nof_sr
                nofCSIPart1, ...         % nof_csi_part1
                nofCSIPart2, ...         % nof_csi_part2
                };

            % Generate test case context.
            testCaseContext = { ...
                carrier.NSizeGrid, ...      % grid_nof_prb
                carrier.SymbolsPerSlot, ... % grid_nof_symbols
                pucchF2Config, ...          % config
                };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_harq', '_test_sr', '_test_csi1', '_test_csi2');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(testCase, SymbolAllocation, nofHarqAck, nofSR, nofCSIPart1, ...
                nofCSIPart2, maxCodeRate)
        %mexTest  Tests the mex wrapper of the srsRAN PUCCH processor for Format 2.
        %   mexTest(OBJ, SymbolAllocation,  nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2,
        %   maxCodeRate) runs a short simulation with a PUCCH transmission specified by
        %   the symbol allocation, the number of bits in the HARQ-ACK, SR, CSI Part 1
        %   and CSI Part 2 payloads, and the maximum code rate. The Cell ID,
        %   NID, NID0 and RNTI are randomly generated. The number of allocated
        %   PRBs is determined based on the UCI payload size and maximum code
        %   rate.

            testCase.setupsimulation(SymbolAllocation, nofHarqAck, nofSR, nofCSIPart1, ...
                nofCSIPart2, maxCodeRate);

            % Define some aliases.
            carrier = testCase.Carrier;
            pucch = testCase.PUCCH;
            numRxPorts = testCase.NumRxPorts;

            [grid, payloads] = createTxGrid(carrier, pucch, ...
                nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2);

            harqAckPayload = payloads.harqAckPayload;
            SRPayload = payloads.SRPayload;
            CSI1Payload = payloads.CSI1Payload;
            CSI2Payload = payloads.CSI2Payload;

            % Init received signals.
            rxGrid = nrResourceGrid(carrier, numRxPorts, "OutputDataType", "single");

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-snrdB / 20);

            gridDims = size(grid);

            % Iterate each receive port.
            for iRxPort = 1:numRxPorts
                % Create some noise samples.
                normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

                % Generate channel estimates as a phase rotation in the
                % frequency domain.
                estimates = exp(1i * linspace(0, 2 * pi, gridDims(1))') * ones(1, gridDims(2));

                % Create noisy modulated symbols.
                rxGrid(:, :, iRxPort) = estimates .* grid + (noiseStdDev * normNoise);
            end

            pucchProcessor = srsMEX.phy.srsPUCCHProcessor();

            message = pucchProcessor(rxGrid, pucch, carrier, 'NumHARQAck', nofHarqAck, ...
                'NumSR', nofSR, 'NumCSIPart1', nofCSIPart1, 'NumCSIPart2', nofCSIPart2);

            assertTrue(testCase, message.isValid, 'The PUCCH Processor should return a valid message.');
            assertEqual(testCase, message.HARQAckPayload, int8(harqAckPayload), ...
                'The HARQ payload doesn''t match.');
            assertEqual(testCase, message.SRPayload, int8(SRPayload), ...
                'The SR payload doesn''t match.');
            assertEqual(testCase, message.CSI1Payload, int8(CSI1Payload), ...
                'The CSI1 payload doesn''t match.');
            assertEqual(testCase, message.CSI2Payload, int8(CSI2Payload), ...
                'The CSI2 payload doesn''t match.');
        end % of function mexTest(testCase, SymbolAllocation, nofHarqAck, nofSR, nofCSIPart1, ...
    end % of methods (Test, TestTags = {'testmex'}}
end % of classdef srsPUCCHProcessorFormat2Unittest

%Generates a PUCCH Format 2 resource grid (Tx side). Also returns the transmitted
%   payloads, and the indices of data and DM-RS.
function [TxGrid, payloads, pucchDataIndices, pucchDmrsIndices] = createTxGrid(carrier, pucch, ...
        nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2)

    % Get the PUCCH control data indices.
    [pucchDataIndices, info] = nrPUCCHIndices(carrier, pucch);

    % Derive the actual UCI codeword length from the radio
    % resources. This is used for rate matching.
    CodeWordLength = info.G;

    % QPSK modulation has 2 bit per symbol.
    modulationOrder = 2;
    assert(length(pucchDataIndices) * modulationOrder == CodeWordLength, ...
        'srsran_matlab:srsPUCCHProcessorFormat2Unittest', ...
        'UCI codeword length and number of PUCCH F2 RE are not consistent');

    % Generate UCI payload.
    harqAckPayload = randi([0, 1], nofHarqAck, 1);
    SRPayload = randi([0, 1], nofSR, 1);
    CSI1Payload = randi([0, 1], nofCSIPart1, 1);
    CSI2Payload = randi([0, 1], nofCSIPart2, 1);

    % For now, UCI multiplexing, applicable to UCI payloads contaning
    % CSI reports of two parts, is not considered. Therefore, all
    % UCI fields are appended into a single UCI segment.
    UCIPayload = [harqAckPayload; SRPayload; CSI1Payload; CSI2Payload];

    % Encode UCI payload.
    uciCW = nrUCIEncode(UCIPayload, CodeWordLength);

    % Create resource grid.
    TxGrid = nrResourceGrid(carrier, "OutputDataType", "single");

    % Modulate PUCCH Format 2.
    TxGrid(pucchDataIndices) = nrPUCCH2(uciCW, pucch.NID, pucch.RNTI);

    % Get the DM-RS indices.
    pucchDmrsIndices = nrPUCCHDMRSIndices(carrier, pucch);

    % Generate and map the DM-RS sequence.
    TxGrid(pucchDmrsIndices) = nrPUCCHDMRS(carrier, pucch, "OutputDataType", "single");

    payloads = struct('UCIPayload', UCIPayload, 'harqAckPayload', harqAckPayload, ...
        'SRPayload', SRPayload, 'CSI1Payload', CSI1Payload, 'CSI2Payload', CSI2Payload);
end
