%srsPUCCHProcessorFormat1Unittest Unit tests for PUCCH Format 1 processor function.
%   This class implements unit tests for the PUCCH Format 1 processor function using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHProcessorFormat1Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHProcessorFormat1Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHProcessorFormat1Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHProcessorFormat1Unittest Properties (TestParameter):
%
%   numerology           - Subcarrier numerology (0, 1).
%   intraSlotFreqHopping - Intra-slot frequency hopping. Set to true if
%                          enabled.
%   SymbolAllocation     - PUCCH Format 1 time allocation as array
%                          containing the start symbol index and the number
%                          of symbols.
%   ackSize              - Number of HARQ-ACK bits (0, 1, 2).
%   srSize               - Number of SR bits (0, 1).
%
%   srsPUCCHProcessorFormat1Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat1Unittest Methods (Test, TestTags = {'testmex'}):
%
%   mexTest  - Testes the MEX-based implementation of the PUCCH Format 1 processor.
%
%   srsPUCCHProcessorFormat1Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrPUCCHDMRS, nrPUCCHDecode, nrPUCCH1Config.

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

classdef srsPUCCHProcessorFormat1Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format1'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format1' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat1', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier numerology (0, 1).
        numerology = {0, 1}

        %Intra-slot frequency hopping usage (inter-slot hopping is not tested).
        intraSlotFreqHopping = {false, true}

        %Relevant combinations of start symbol index {0, ..., 10} and number of symbols {4, ..., 14}. 
        SymbolAllocation = {[0, 14], [1, 13], [5, 5], [10, 4]}

        %Number of HARQ-ACK bits (0, 1, 2).
        ackSize = {0, 1, 2}
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct pucch_entry {\n');
            fprintf(fileID, '  pucch_processor::format1_configuration                  config;\n');
            fprintf(fileID, '  std::vector<uint8_t>                                    ack_bits;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  std::vector<pucch_entry>                                entries;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, intraSlotFreqHopping, SymbolAllocation, ackSize)
        %testvectorGenerationCases Generates a test vector for the given numerology, format and frequency hopping,
        %  while using a random NCellID, random NSlot and random symbol and PRB length.

            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            [rxGrid, ack, ack2, configuration] = generateSimData(numerology, intraSlotFreqHopping, SymbolAllocation, ackSize);

            NumRxPorts = 1;
            if ndims(rxGrid) == 3
                NumRxPorts = size(rxGrid, 3);
            end

            pucchDataIndices = configuration.pucchDataIndices;
            pucchDmrsIndices = configuration.pucchDmrsIndices;
            carrier = configuration.carrier;
            pucch1 = configuration.pucch1;
            pucch2 = configuration.pucch2;
            NSizeBWP = configuration.NSizeBWP;
            NStartBWP = configuration.NStartBWP;

            CyclicPrefix = carrier.CyclicPrefix;

            % Extract the elements of interest from the grid.
            nofRePort = length(pucchDataIndices) + length(pucchDmrsIndices);
            rxGridSymbols = complex(nan(1, NumRxPorts * nofRePort));
            rxGridIndexes = complex(nan(NumRxPorts * nofRePort, 3));

            onePortindexes = [nrPUCCHIndices(carrier, pucch1, 'IndexStyle','subscript', 'IndexBase','0based'); ...
                    nrPUCCHDMRSIndices(carrier, pucch1, 'IndexStyle','subscript', 'IndexBase','0based')];

            for iRxPort = 0:(NumRxPorts - 1)
                offset = iRxPort * nofRePort;
                rxGridSymbols(offset + (1:nofRePort)) = [rxGrid(pucchDataIndices); rxGrid(pucchDmrsIndices)];

                indices = onePortindexes;
                indices(:,3) = iRxPort;

                rxGridIndexes(offset + (1:nofRePort), :) = indices;
            end

            % Write each complex symbol, along with its associated index,
            % into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndexes);

            % Generate a 'slot_point' configuration.
            slotPointConfig = {...
                numerology, ...                                             % numerology
                carrier.NFrame * carrier.SlotsPerFrame + carrier.NSlot, ... % system slot number
                };

            % Generate a 'cyclic_prefix' configuration.
            cyclicPrefixConfig = matlab2srsCyclicPrefix(CyclicPrefix);

            secondHopConfig = {};
            if intraSlotFreqHopping
                secondHopConfig = {pucch1.SecondHopStartPRB};
            end

            % Reception port list.
            portsString = ['{' num2str(0:(NumRxPorts-1), "%d,") '}'];

            % Generate PUCCH common configuration.
            pucchConfig1 = {...
                'nullopt', ...                  % context
                slotPointConfig, ...            % slot
                NSizeBWP, ...                   % bwp_size_rb
                NStartBWP, ...                  % bwp_start_rb
                cyclicPrefixConfig, ...         % cp
                pucch1.PRBSet, ...              % starting_prb
                secondHopConfig, ...            % second_hop_prb
                carrier.NCellID, ...            % n_id
                length(ack), ...                % nof_harq_ack
                portsString, ...                % ports
                pucch1.InitialCyclicShift, ...  % initial_cyclic_shift
                pucch1.SymbolAllocation(2), ... % nof_symbols
                pucch1.SymbolAllocation(1), ... % start_symbol_index
                pucch1.OCCI, ...                % time_domain_occ
                };

            pucchConfig2 = {...
                'nullopt', ...                  % context
                slotPointConfig, ...            % slot
                NSizeBWP, ...                   % bwp_size_rb
                NStartBWP, ...                  % bwp_start_rb
                cyclicPrefixConfig, ...         % cp
                pucch2.PRBSet, ...              % starting_prb
                secondHopConfig, ...            % second_hop_prb
                carrier.NCellID, ...            % n_id
                length(ack), ...                % nof_harq_ack
                portsString, ...                % ports
                pucch2.InitialCyclicShift, ...  % initial_cyclic_shift
                pucch2.SymbolAllocation(2), ... % nof_symbols
                pucch2.SymbolAllocation(1), ... % start_symbol_index
                pucch2.OCCI, ...                % time_domain_occ
                };

            % Generate test case cell.
            pucchEntry1 = {...
                pucchConfig1, ...  % config
                num2cell(ack), ... % ack_bits
                };

            % Generate test case cell.
            pucchEntry2 = {...
                pucchConfig2, ...   % config
                num2cell(ack2), ... % ack_bits
                };

            % Concatenate PUCCH entries.
            testCaseCell = {{pucchEntry1, pucchEntry2}};

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, ...
                testCaseCell, false, '_test_input_symbols');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(testCase, numerology, intraSlotFreqHopping, SymbolAllocation, ackSize)
        %mexTest Tests the mex wrapper of the srsRAN PUCCH processor for Format 1.
        %   mexTest(testCase, numerology, intraSlotFreqHopping, SymbolAllocation, ackSize)
        %   runs a short simulation with a PUCCH transmission specified by the given
        %   numerology, frequency hopping, symbol allocation and ACK size.

            import srsMEX.phy.srsPUCCHProcessor

            [rxGrid, ack1, ack2, configuration] = generateSimData(numerology, intraSlotFreqHopping, SymbolAllocation, ackSize);

            srspucch = srsPUCCHProcessor;

            uci1 = srspucch(rxGrid, configuration.pucch1, configuration.carrier, NumHARQAck=ackSize);
            uci2 = srspucch(rxGrid, configuration.pucch2, configuration.carrier, NumHARQAck=ackSize);

            % Messages should be valid.
            assertTrue(testCase, uci1.isValid, 'The first PUCCH is invalid.');
            assertTrue(testCase, uci2.isValid, 'The second PUCCH is invalid.');

            % SR fields should be empty.
            assertEmpty(testCase, uci1.SRPayload, 'The first PUCCH has a nonempty SR field.');
            assertEmpty(testCase, uci2.SRPayload, 'The second PUCCH has a nonempty SR field.');

            % CSI Part1 and Part2 should be empty.
            assertEmpty(testCase, uci1.CSI1Payload, 'The first PUCCH has a nonempty CSI Part 1 field.');
            assertEmpty(testCase, uci2.CSI1Payload, 'The second PUCCH has a nonempty CSI Part 1 field.');
            assertEmpty(testCase, uci1.CSI2Payload, 'The first PUCCH has a nonempty CSI Part 2 field.');
            assertEmpty(testCase, uci2.CSI2Payload, 'The second PUCCH has a nonempty CSI Part 2 field.');

            % ACKs should be of the given size.
            assertLength(testCase, uci1.HARQAckPayload, ackSize, 'The first PUCCH has the wrong number of ACK bits.');
            assertLength(testCase, uci2.HARQAckPayload, ackSize, 'The second PUCCH has the wrong number of ACK bits.');

            % Check the ACK content.
            assertEqual(testCase, uci1.HARQAckPayload, int8(ack1), 'Detection error in the first PUCCH.');
            assertEqual(testCase, uci2.HARQAckPayload, int8(ack2), 'Detection error in the second PUCCH.');

            % Alter the first PUCCH with a wrong initialy cyclic shift.
            configuration.pucch1.InitialCyclicShift = mod(configuration.pucch1.InitialCyclicShift + 1, 12);
            if (configuration.pucch1.InitialCyclicShift == configuration.pucch2.InitialCyclicShift)
                configuration.pucch1.InitialCyclicShift = mod(configuration.pucch1.InitialCyclicShift + 1, 12);
            end

            % This should result in an invalid message.
            uciWrong = srspucch(rxGrid, configuration.pucch1, configuration.carrier, NumHARQAck=ackSize);
            assertFalse(testCase, uciWrong.isValid, 'The altered PUCCH should be invalid.');
        end
    end % of methods (Test, TestTags = {'testmex'})

end % of classdef srsPUCCHProcessorFormat1Unittest

%Generates simulation data (ACKS, Rx side resource grid, configurations).
function [rxGrid, ack, ack2, configuration] = generateSimData(numerology, intraSlotFreqHopping, SymbolAllocation, ackSize)
    import srsLib.phy.helpers.srsConfigureCarrier
    import srsLib.phy.helpers.srsConfigurePUCCH

    % Use a unique NCellIDLoc, NSlotLoc for each test.
    NCellIDLoc = randi([0, 1007]);

    % Use a random slot number from the allowed range.
    NSlotLoc = randi([0, 10 * pow2(numerology) - 1]);

    % Fixed parameter values.
    NStartBWP = 1;
    NSizeBWP = 51;
    NSizeGrid = NStartBWP + NSizeBWP;
    NStartGrid = 0;
    CyclicPrefix = 'normal';
    GroupHopping = 'neither';
    FrequencyHopping = 'neither';
    SecondHopStartPRB = 0;
    NumRxPorts = 4;

    % Random frame number.
    NFrame = randi([0, 1023]);

    % Random initial cyclic shift for the first PUCCH.
    InitialCyclicShift1 = randi([0, 11]);

    % Random initial cyclic shift for the second PUCCH. Make sure
    % it does not coincide with the first instance.
    InitialCyclicShift2 = InitialCyclicShift1;
    while InitialCyclicShift2 == InitialCyclicShift1
        InitialCyclicShift2 = randi([0, 11]);
    end


    % Random start PRB index and length in number of PRBs.
    PRBSet  = randi([0, NSizeBWP - 1]);

    % When intraslot frequency hopping is disabled, the OCCI value
    % must be less than the floor of half of the number of OFDM
    % symbols allocated for the PUCCH.
    if ~intraSlotFreqHopping
        OCCI = randi([0, (floor(SymbolAllocation(2) / 2) - 1)]);
    else
        % When intraslot frequency hopping is enabled, the OCCI
        % value must be less than the floor of one-fourth of the
        % number of OFDM symbols allocated for the PUCCH.
        maxOCCindex = floor(SymbolAllocation(2) / 4) - 1;
        if maxOCCindex == 0
            OCCI = 0;
        else
            OCCI = randi([0, maxOCCindex]);
        end
    end

    % Randomly select SecondHopStartPRB if intra-slot frequency
    % hopping is enabled.
    if intraSlotFreqHopping
        SecondHopStartPRB = randi([0, NSizeBWP - 1]);
        % Set respective MATLAB parameter.
        FrequencyHopping   = 'intraSlot';
    end

    % Configure the carrier according to the test parameters.
    SubcarrierSpacing = 15 * (2 .^ numerology);
    carrier = srsConfigureCarrier(NCellIDLoc, ...
        SubcarrierSpacing, NSizeGrid, NStartGrid, ...
        NSlotLoc, NFrame, CyclicPrefix);

    % Configure the PUCCH according to the test parameters.
    pucch1 = srsConfigurePUCCH(1, SymbolAllocation, PRBSet,...
        FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
        OCCI, NStartBWP, NSizeBWP);
    pucch1.InitialCyclicShift = InitialCyclicShift1;

    pucch2 = srsConfigurePUCCH(1, SymbolAllocation, PRBSet,...
        FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
        OCCI, NStartBWP, NSizeBWP);
    pucch2.InitialCyclicShift = InitialCyclicShift2;

    % Create resource grid.
    grid = nrResourceGrid(carrier, "OutputDataType", "single");
    gridDims = size(grid);

    ack = randi([0, 1], ackSize, 1);
    ack2 = randi([0, 1], ackSize, 1);
    sr = [];

    if ackSize == 0
        sr = 1;
    end

    % Get the PUCCH control data indices.
    pucchDataIndices = nrPUCCHIndices(carrier, pucch1);

    % Modulate PUCCH Format 1.
    FrequencyHopping = 'disabled';
    if strcmp(pucch1.FrequencyHopping, 'intraSlot')
        FrequencyHopping = 'enabled';
    end

    pucchData1 = nrPUCCH1(ack, sr, pucch1.SymbolAllocation, ...
        carrier.CyclicPrefix, carrier.NSlot, carrier.NCellID, ...
        pucch1.GroupHopping, pucch1.InitialCyclicShift, FrequencyHopping, ...
        pucch1.OCCI, "OutputDataType", "single");

    pucchData2 = nrPUCCH1(ack2, sr, pucch2.SymbolAllocation, ...
        carrier.CyclicPrefix, carrier.NSlot, carrier.NCellID, ...
        pucch2.GroupHopping, pucch2.InitialCyclicShift, FrequencyHopping, ...
        pucch2.OCCI, "OutputDataType", "single");

    grid(pucchDataIndices) = pucchData1 + pucchData2;

    % Get the DM-RS indices.
    pucchDmrsIndices = nrPUCCHDMRSIndices(carrier, pucch1);

    % Generate and map the DM-RS sequence.
    puschDmrs1 = nrPUCCHDMRS(carrier, pucch1, "OutputDataType", "single");
    puschDmrs2 = nrPUCCHDMRS(carrier, pucch2, "OutputDataType", "single");
    grid(pucchDmrsIndices) = puschDmrs1 + puschDmrs2;

    % Modulate baseband signal.
    [baseband, OfdmInfo] = nrOFDMModulate(grid, carrier.SubcarrierSpacing, carrier.NSlot);

    % Noise variance.
    snrdB = 30;
    noiseStdDev = 10 ^ (-snrdB / 20);

    % Carrier Frequency offset.
    cfoHz = 400;

    % Apply carrier frequency offset in time domain.
    timeSeconds = (0:(length(baseband) - 1)) / OfdmInfo.SampleRate;
    basebandWithCfo = baseband .* transpose(exp(2i * pi * timeSeconds * cfoHz));

    % Demodulate baseband signal.
    gridWithCfo = nrOFDMDemodulate(carrier, basebandWithCfo);

    % Init received signals.
    dataChEsts = zeros(length(pucchDataIndices), NumRxPorts);
    rxGrid = nrResourceGrid(carrier, NumRxPorts, "OutputDataType", "single");

    % Iterate each receive port.
    for iRxPort = 1:NumRxPorts
        % Create some noise samples.
        normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

        % Generate channel coefficients as a phase rotation in the
        % frequency domain.
        channel = exp(1i * linspace(0, 2 * pi, gridDims(1))') * ones(1, gridDims(2));

        % Create noisy modulated symbols.
        rxGrid(:, :, iRxPort) = channel .* gridWithCfo + (noiseStdDev * normNoise);

        % Perfect channel estimation: save channel coefficients.
        dataChEsts(:, iRxPort) = channel(pucchDataIndices);
    end

    configuration = struct();
    configuration.pucchDataIndices = pucchDataIndices;
    configuration.pucchDmrsIndices = pucchDmrsIndices;
    configuration.carrier = carrier;
    configuration.pucch1 = pucch1;
    configuration.pucch2 = pucch2;
    configuration.NSizeBWP = NSizeBWP;
    configuration.NStartBWP = NStartBWP;
end
