%srsPUCCHProcessorFormat3Unittest Unit tests for PUCCH Format 3 processor function.
%   This class implements unit tests for the PUCCH Format 3 processor function using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHProcessorFormat3Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHProcessorFormat3Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_processor_format3').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors/pucch').
%
%   srsPUCCHProcessorFormat3Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHProcessorFormat3Unittest Properties (TestParameter):
%
%   SymbolAllocation - PUCCH Format 3 time allocation.
%   FrequencyHopping - Frequency hopping type ('neither', 'intraSlot').
%   PRBNum           - Number of PRBs (1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16).
%   CodeRate         - Code rate (0.08, 0.15, 0.25, 0.35, 0.45, 0.6, 0.8).
%
%   srsPUCCHProcessorFormat3Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat3Unittest Methods (Access = protected):
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

classdef srsPUCCHProcessorFormat3Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format3'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pucch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format3' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat3', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (Constant, Hidden)
        %Number of Rx antenna ports.
        NumRxPorts = 4;
    end

    properties (Hidden)
        %Carrier configuration object.
        Carrier
        %PUCCH Format 3 configuration object.
        PUCCH
    end

    properties (TestParameter)

        %Relevant combinations of start symbol index {0, ..., 10} and number of symbols {4, ..., 14}. 
        SymbolAllocation = {[0, 14], [7, 7]};

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'};

        % Number of PRBs (1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16).
        PRBNum = {1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16};

        %Code rate, from TS38.331 Section 6.3.2, PUCCH-config
        %   information element (0.08, 0.15, 0.25, 0.35, 0.45, 0.6, 0.8).
        CodeRate = {0.08, 0.15, 0.25, 0.35, 0.45, 0.6, 0.8};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  unsigned                               grid_nof_prb;\n');
            fprintf(fileID, '  unsigned                               grid_nof_symbols;\n');
            fprintf(fileID, '  pucch_processor::format3_configuration config;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                               context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    uci_bits;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Access = private)
        function [nofUCIBits, pucchDataIndices, info] = setupsimulation(testCase, SymbolAllocation, ...
                FrequencyHopping, PRBNum, CodeRate)
        % Sets secondary simulation variables and MATLAB NR configuration objects.

            % Generate random cell ID.
            nCellID = randi([0, 1007]);

            % Generate a random NID.
            NID = randi([0, 1023]);

            % Generate a random RNTI.
            RNTI = randi([1, 65535]);

            % Normal cyclic prefix.
            cyclicPrefix = 'normal';

            % Modulation type ('QPSK', 'pi/2-BPSK').
            if randi([0 1]) == 1
                modulation = 'QPSK';
            else
                modulation = 'pi/2-BPSK';
            end
        
            % Additional DM-RS flag. If true, more OFDM symbols are filled with DM-RS.
            additionalDMRS = (randi([0 1]) == 1);

            % Maximum resource grid size.
            MaxGridSize = 275;

            % Resource grid starts at CRB0.
            nStartGrid = 0;

            % BWP start relative to CRB0.
            nStartBWP = randi([0, MaxGridSize - PRBNum]);

            % BWP size. PUCCH Format 3 frequency allocation must fit inside
            % the BWP.
            nSizeBWP = randi([PRBNum, MaxGridSize - nStartBWP]);

            % PUCCH PRB Start relative to the BWP.
            PRBStart = randi([0, nSizeBWP - PRBNum]);

            % Fit resource grid size to the BWP.
            nSizeGrid = nStartBWP + nSizeBWP;

            % PRB set assigned to PUCCH Format 3 within the BWP.
            % Each element within the PRB set indicates the location of a
            % Resource Block relative to the BWP starting PRB.
            PRBSet = PRBStart : (PRBStart + PRBNum - 1);

            % Frequency hopping.
            if strcmp(FrequencyHopping, 'intraSlot')
                secondPRB = randi([0, nSizeBWP - PRBNum]);
            else
                secondPRB = 1;
            end

            % Configure the carrier according to the test parameters.
            testCase.Carrier = nrCarrierConfig( ...
                NCellID=nCellID, ...
                NSizeGrid=nSizeGrid, ...
                NStartGrid=nStartGrid, ...
                CyclicPrefix=cyclicPrefix ...
                );

            % Configure the PUCCH Format 3.
            testCase.PUCCH = nrPUCCH3Config( ...
                NStartBWP=nStartBWP, ...
                NSizeBWP=nSizeBWP, ...
                SymbolAllocation=SymbolAllocation, ...
                PRBSet=PRBSet, ...
                FrequencyHopping=FrequencyHopping, ...
                SecondHopStartPRB=secondPRB, ...
                NID=NID, ...
                RNTI=RNTI, ...
                Modulation=modulation, ...
                AdditionalDMRS=additionalDMRS ...
                );

            [pucchDataIndices, info] = nrPUCCHIndices(testCase.Carrier, testCase.PUCCH);

            % Maximum number of bits of the code block.
            nofCodeBlockBits = min(floor(info.G * CodeRate), 1706);

            % If needed, remove the CRC bits from the UCI payload.
            if (nofCodeBlockBits < 12)
                nofUCIBits = nofCodeBlockBits;
            elseif (nofCodeBlockBits < 20 + 6)
                nofUCIBits = nofCodeBlockBits - 6;
            elseif (nofCodeBlockBits < 360 + 11)
                nofUCIBits = nofCodeBlockBits - 11;
            else
                % The UCI payload is split into two codeblocks when
                %   (A>=360 and E>=1088) or A>=1013
                % which means 11 more CRC bits are used.
                % Remove the extra CRC bits so that the effective code rate
                % doesn't exceed the maximum.
                nofUCIBits = nofCodeBlockBits - 2*11;
            end

            % Ensure that the UCI codeword is greater or equal to the minimum
            % number of UCI bits for PUCCH Format 3.
            assert(nofUCIBits >= 3, ...
                'srsran_matlab:srsPUCCHProcessorFormat3Unittest', ...
                ['The UCI payload size for the configuration (i.e., %d) is ' ...
                'smaller than the minimum UCI payload size for PUCCH Format 3 ' ...
                '(i.e., 3 bits)'], nofUCIBits);

        end % of function setupsimulation(testCase, SymbolAllocation, ...

    end % methods (Access = private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, ...
                FrequencyHopping, PRBNum, CodeRate)
        %testvectorGenerationCases Generates a test vector for the given
        %   Symbol allocation, frequency hopping, number of PRBs and code rate.

            import srsLib.phy.upper.channel_processors.pucch.srsPUCCH3Demodulator
            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.cellarray2str

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            [nofUCIBits, pucchDataIndices, info] = testCase.setupsimulation(...
                SymbolAllocation, FrequencyHopping, PRBNum, CodeRate);

            % Define some aliases.
            carrier = testCase.Carrier;
            pucch = testCase.PUCCH;
            numRxPorts = testCase.NumRxPorts;

            [grid, UCIPayload, pucchDmrsIndices] = createTxGrid(...
                carrier, pucch, pucchDataIndices, info, nofUCIBits);

            % Init received signals.
            rxGrid = nrResourceGrid(carrier, numRxPorts, OutputDataType='single');
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

            % Demodulate PUCCH Format 3.
            softBits = srsPUCCH3Demodulator(pucch, rxSymbols, dataChEsts, noiseVar);

            % Decode UCI message to check for errors.
            rxUCIPayload = nrUCIDecode(softBits, nofUCIBits, pucch.Modulation);

            assert(isequal(rxUCIPayload, UCIPayload), ...
                'srsran_matlab:srsPUCCHProcessorFormat3Unittest', ...
                'Decoded UCI payload has errors');

            % Extract the elements of interest from the grid.
            nofRePort = length(pucchDataIndices) + length(pucchDmrsIndices);
            rxGridSymbols = complex(nan(1, numRxPorts * nofRePort));
            rxGridIndices = nan(numRxPorts * nofRePort, 3);

            % Convert PUCCH data indices from linear to subscript.
            [subc, symb, antenna] = ind2sub(gridDims, pucchDataIndices);
            onePortDataIndices = [subc symb antenna] - 1;

            onePortIndices = [onePortDataIndices; ...
                    nrPUCCHDMRSIndices(carrier, pucch, IndexStyle='subscript', IndexBase='0based')];
            for iRxPort = 0:(numRxPorts - 1)
                offset = iRxPort * nofRePort;
                rxGridSymbols(offset + (1:nofRePort)) = [rxGrid(pucchDataIndices); rxGrid(pucchDmrsIndices)];

                indices = onePortIndices;
                indices(:, 3) = iRxPort;

                rxGridIndices(offset + (1:nofRePort), :) = indices;
            end

            % Write the entire resource grid to a file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndices);

            % Write the UCI bits to a file.
            testCase.saveDataFile('_test_uci_bits', testID, ...
                @writeUint8File, UCIPayload);

            % Reception port list.
            portsString = ['{' num2str(0:(numRxPorts-1), "%d,") '}'];

            % Slot configuration.
            slotConfig = {log2(carrier.SubcarrierSpacing/15), carrier.NSlot};

            % Convert cyclic prefix to string.
            cyclicPrefixStr = matlab2srsCyclicPrefix(carrier.CyclicPrefix);

            % Second Hop PRB.
            if strcmp(pucch.FrequencyHopping, 'intraSlot')
                secondHopPRB = pucch.SecondHopStartPRB;
            else
                secondHopPRB = {};
            end

            % Generate PUCCH Format 3 configuration.
            pucchF3Config = {...
                'std::nullopt', ...                         % context
                slotConfig, ...                             % slot
                cyclicPrefixStr, ...                        % cp
                portsString, ...                            % ports
                pucch.NSizeBWP, ...                         % bwp_size_rb
                pucch.NStartBWP, ...                        % bwp_start_rb
                pucch.PRBSet(1), ...                        % starting_prb
                secondHopPRB, ...                           % second_hop_prb
                numel(pucch.PRBSet), ...                    % nof_prb
                SymbolAllocation(1), ...                    % start_symbol_index
                SymbolAllocation(2), ...                    % nof_symbols
                pucch.RNTI, ...                             % rnti
                carrier.NCellID, ....                       % n_id_hopping
                pucch.NID, ...                              % n_id_scrambling
                nofUCIBits, ...                             % nof_harq_ack
                0, ...                                      % nof_sr
                0, ...                                      % nof_csi_part1
                0, ...                                      % nof_csi_part2
                pucch.AdditionalDMRS, ...                   % additional_dmrs
                strcmp(pucch.Modulation, 'pi/2-BPSK'), ...  % pi2_bpsk
                };

            % Generate test case context.
            testCaseContext = { ...
                carrier.NSizeGrid, ...      % grid_nof_prb
                carrier.SymbolsPerSlot, ... % grid_nof_symbols
                pucchF3Config, ...          % config
                };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_uci_bits');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(testCase, SymbolAllocation, FrequencyHopping, ...
                PRBNum, CodeRate)
        %mexTest  Tests the mex wrapper of the srsRAN PUCCH processor for Format 3.
        %   mexTest(OBJ, symbolAllocation, frequencyHopping, modulation,
        %   additionalDMRS, nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2,
        %   maxCodeRate) runs a short simulation with a PUCCH transmission specified by
        %   the symbol allocation, the number of bits in the HARQ-ACK, SR, CSI Part 1
        %   and CSI Part 2 payloads, and the maximum code rate. The Cell ID,
        %   NID and RNTI are randomly generated.

            [nofUCIBits, pucchDataIndices, info] = ...
                testCase.setupsimulation(SymbolAllocation, FrequencyHopping, ...
                PRBNum, CodeRate);

            % Define some aliases.
            carrier = testCase.Carrier;
            pucch = testCase.PUCCH;
            numRxPorts = testCase.NumRxPorts;

            [grid, UCIPayload] = createTxGrid(carrier, pucch, ...
                pucchDataIndices, info, nofUCIBits);

            % Init received signals.
            rxGrid = nrResourceGrid(carrier, numRxPorts, OutputDataType='single');

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

            message = pucchProcessor(carrier, pucch, rxGrid, NumHARQAck=nofUCIBits, ...
                NumSR=0, NumCSIPart1=0, NumCSIPart2=0);

            assertTrue(testCase, message.isValid, 'The PUCCH Processor should return a valid message.');
            assertEqual(testCase, message.HARQAckPayload, int8(UCIPayload), ...
                'The HARQ payload doesn''t match.');
            assertEqual(testCase, message.SRPayload, zeros(0, 1, 'int8'), ...
                'The SR payload doesn''t match.');
            assertEqual(testCase, message.CSI1Payload, zeros(0, 1, 'int8'), ...
                'The CSI1 payload doesn''t match.');
            assertEqual(testCase, message.CSI2Payload, zeros(0, 1, 'int8'), ...
                'The CSI2 payload doesn''t match.');
        end % of function mexTest(testCase, SymbolAllocation, ...
    end % of methods (Test, TestTags = {'testmex'}}
end % of classdef srsPUCCHProcessorFormat3Unittest

%Generates a PUCCH Format 3 resource grid (Tx side). Also returns the transmitted
%   payload, and the indices of DM-RS.
function [TxGrid, UCIPayload, pucchDmrsIndices] = ...
    createTxGrid(carrier, pucch, pucchDataIndices, info, nofUCIBits)

    % Derive the actual UCI codeword length from the radio
    % resources. This is used for rate matching.
    CodeWordLength = info.G;

    % QPSK modulation has 2 bit per symbol.
    if strcmp(pucch.Modulation, 'QPSK')
        modulationOrder = 2;
    else
        modulationOrder = 1;
    end
    assert(length(pucchDataIndices) * modulationOrder == CodeWordLength, ...
        'srsran_matlab:srsPUCCHProcessorFormat3Unittest', ...
        'UCI codeword length and number of PUCCH F3 RE are not consistent');

    % Generate UCI payload.
    % For now, UCI multiplexing, applicable to UCI payloads contaning
    % CSI reports of two parts, is not considered. Therefore, all
    % UCI fields are appended into a single UCI segment.
    UCIPayload = randi([0, 1], nofUCIBits, 1);

    % Encode UCI payload.
    uciCW = nrUCIEncode(UCIPayload, CodeWordLength, pucch.Modulation);

    % Create resource grid.
    TxGrid = nrResourceGrid(carrier, OutputDataType='single');

    % Modulate PUCCH Format 3.
    TxGrid(pucchDataIndices) = nrPUCCH(carrier, pucch, uciCW);

    % Get the DM-RS indices.
    pucchDmrsIndices = nrPUCCHDMRSIndices(carrier, pucch);

    % Generate and map the DM-RS sequence.
    TxGrid(pucchDmrsIndices) = nrPUCCHDMRS(carrier, pucch, OutputDataType='single');

end
