%srsPUCCHProcessorFormat0Unittest Unit tests for PUCCH Format 0 processor function.
%   This class implements unit tests for the PUCCH Format 0 processor function using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHProcessorFormat0Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHProcessorFormat0Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHProcessorFormat0Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHProcessorFormat0Unittest Properties (TestParameter):
%
%   numerology       - Subcarrier numerology (0, 1).
%   allocation       - Structure containing the number of symbols and if it
%                      uses intra-slot frequency hopping.
%   payload          - Structure containing the number of ACK bits and a logical
%                      flag indicating whether the PUCCH carries SR information
%                      or not.
%
%   srsPUCCHProcessorFormat0Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat0Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrPUCCHDMRS.

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

classdef srsPUCCHProcessorFormat0Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format0'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format0' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat0', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Subcarrier numerology (0, 1).
        numerology = {0, 1}

        %Valid combinations of number of OFDM symbols and intra-slot
        %frequency hopping.
        allocation = {...
            struct('numSymbols', 1, 'freqHopping', false), ...
            struct('numSymbols', 2, 'freqHopping', false), ...
            struct('numSymbols', 2, 'freqHopping', true), ...
            }

        %Valid combinations of payload.
        payload = { ...
            struct('nofHarqAck', 0, 'sr', true), ...
            struct('nofHarqAck', 1, 'sr', true), ...
            struct('nofHarqAck', 2, 'sr', true), ...
            struct('nofHarqAck', 1, 'sr', false), ...
            struct('nofHarqAck', 2, 'sr', false), ...
            }

        %Number of receive ports.
        NumRxPorts = {1, 2, 4}
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include <optional>\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct pucch_entry {\n');
            fprintf(fileID, '  pucch_processor::format0_configuration config;\n');
            fprintf(fileID, '  std::vector<uint8_t>                   ack_bits;\n');
            fprintf(fileID, '  std::optional<uint8_t>                 sr;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  pucch_entry                                             entry;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, allocation, payload, NumRxPorts)
        %testvectorGenerationCases Generates a test vector for the given
        %   numerology, allocation, payload and number of receive ports,
        %   while using a random NCellID, random NSlot, random symbol and
        %   PRB length.

            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            [rxGrid, pucchDataIndices, payloadData, pucch, carrier] = generateSimData(numerology, allocation, payload, NumRxPorts);

            % Extract the elements of interest from the grid.
            nofRePort = length(pucchDataIndices);
            rxGridSymbols = complex(nan(1, NumRxPorts * nofRePort));
            rxGridIndices = complex(nan(NumRxPorts * nofRePort, 3));
            onePortIndices = nrPUCCHIndices(carrier, pucch, 'IndexStyle', 'subscript', 'IndexBase', '0based');
            for iRxPort = 0:(NumRxPorts - 1)
                offset = iRxPort * nofRePort;
                rxGridSymbols(offset + (1:nofRePort)) = rxGrid(pucchDataIndices);

                indices = onePortIndices;
                indices(:, 3) = iRxPort;

                rxGridIndices(offset + (1:nofRePort), :) = indices;
            end

            % Write each complex symbol, along with its associated index,
            % into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndices);

            % Generate a 'slot_point' configuration.
            slotPointConfig = {...
                numerology, ...                                             % numerology
                carrier.NFrame * carrier.SlotsPerFrame + carrier.NSlot, ... % system slot number
                };

            secondHopConfig = {};
            if allocation.freqHopping
                secondHopConfig = {pucch.SecondHopStartPRB};
            end

            % Reception port list.
            portsString = ['{' num2str(0:(NumRxPorts - 1), "%d,") '}'];

            cyclicPrefixString = ['cyclic_prefix::' upper(carrier.CyclicPrefix)];

            % Generate PUCCH common configuration.
            pucchConfig = {...
                'std::nullopt', ...             % context
                slotPointConfig, ...            % slot
                cyclicPrefixString, ...         % cp
                pucch.NSizeBWP, ...             % bwp_size_rb
                pucch.NStartBWP, ...            % bwp_start_rb
                pucch.PRBSet, ...               % starting_prb
                secondHopConfig, ...            % second_hop_prb
                pucch.SymbolAllocation(1), ...  % start_symbol_index
                pucch.SymbolAllocation(2), ...  % nof_symbols
                pucch.InitialCyclicShift, ...   % initial_cyclic_shift
                pucch.HoppingID, ...            % n_id
                payload.nofHarqAck, ...         % nof_harq_ack
                payload.sr, ...                 % sr_opportunity
                portsString, ...                % ports
                };

            % Generate test case cell.
            testCaseCell = {...
                pucchConfig, ...                % config
                num2cell(payloadData.ACK), ...  % ack_bits
                num2cell(payloadData.SR), ...   % sr
                };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, ...
                testCaseCell, true, '_test_input_symbols');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHProcessorFormat0Unittest

% For the given simulation set-up, generates the received resource grid. It also
% returns the indices of the REs carrying PUCCH data, the value of payload bits,
% the PUCCH Format0 configuration and the carrier configuration.
function [rxGrid, pucchDataIndices, payloadData, pucch, carrier] = generateSimData(numerology, allocation, payload, NumRxPorts)
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
    FrequencyHopping = 'disabled';
    FrequencyHopping2 = 'neither';
    PRBSet = randi([0, NSizeBWP - 1]);
    SecondHopStartPRB = PRBSet;
    SymbolAllocation = [randi([0, 14 - allocation.numSymbols]), ...
        allocation.numSymbols];
    InitialCyclicShift = randi([0, 11]);

    % Random frame number.
    NFrame = randi([0, 1023]);

    % Randomly select SecondHopStartPRB if intra-slot frequency
    % hopping is enabled.
    if allocation.freqHopping
        SecondHopStartPRB = randi([0, NSizeBWP - 1]);
        % Set respective MATLAB parameter.
        FrequencyHopping   = 'enabled';
        FrequencyHopping2   = 'intraSlot';
    end

    % Configure the carrier according to the test parameters.
    SubcarrierSpacing = 15 * (2 .^ numerology);
    carrier = nrCarrierConfig(...
        'NCellID', NCellIDLoc, ...
        'SubcarrierSpacing', SubcarrierSpacing, ...
        'CyclicPrefix', CyclicPrefix, ...
        'NSizeGrid', NSizeGrid, ...
        'NStartGrid', NStartGrid, ...
        'NSlot', NSlotLoc, ...
        'NFrame', NFrame);

    % Configure the PUCCH according to the test parameters.
    pucch = nrPUCCH0Config( ...
        'NSizeBWP', NSizeBWP, ...
        'NStartBWP', NStartBWP, ...
        'SymbolAllocation', SymbolAllocation, ...
        'PRBSet', PRBSet, ...
        'FrequencyHopping', FrequencyHopping2, ...
        'SecondHopStartPRB', SecondHopStartPRB, ...
        'GroupHopping', GroupHopping, ...
        'HoppingID', NCellIDLoc, ...
        'InitialCyclicShift', InitialCyclicShift);

    % Generate HARQ ACK payload.
    ack = randi([0, 1], payload.nofHarqAck, 1);

    % Generate SR payload.
    sr = [];
    if payload.sr
        if payload.nofHarqAck > 0
            sr = randi([0, 1]);
        else
            sr = 1;
        end
    end

     % Get the PUCCH control data indices.
    pucchDataIndices = nrPUCCHIndices(carrier, pucch);

    % Generate data symbols.
    pucchData = nrPUCCH0(ack, sr, pucch.SymbolAllocation, ...
        carrier.CyclicPrefix, carrier.NSlot, carrier.NCellID, ...
        pucch.GroupHopping, pucch.InitialCyclicShift, ...
        FrequencyHopping, "OutputDataType", "single");

    % Create resource grid.
    txGrid = nrResourceGrid(carrier, "OutputDataType", "single");
    gridDims = size(txGrid);

    % Write PUCCH data in the resource grid.
    txGrid(pucchDataIndices) = pucchData;

    % Init received signals.
    rxGrid = nrResourceGrid(carrier, NumRxPorts, "OutputDataType", "single");
    rxSymbols = zeros(length(pucchDataIndices), NumRxPorts);

    % Generate random channel coefficients with unitary power and
    % uniform random phase.
    H = exp(2i * pi * rand(NumRxPorts, 1));

    % Noise variance.
    snrdB = 30;
    noiseStdDev = 10 ^ (-snrdB / 20);

    % Carrier Frequency offset.
    cfoHz = 400;

    % Modulate baseband signal.
    [baseband, OfdmInfo] = nrOFDMModulate(txGrid, carrier.SubcarrierSpacing, carrier.NSlot);

    % Apply carrier frequency offset in time domain.
    timeSeconds = (0:(length(baseband) - 1)) / OfdmInfo.SampleRate;
    basebandWithCfo = baseband .* exp(2i * pi * timeSeconds.' * cfoHz);

    % Demodulate baseband signal.
    gridWithCfo = nrOFDMDemodulate(carrier, basebandWithCfo);

    % Iterate each receive port.
    for iRxPort = 1:NumRxPorts
        % Create some noise samples.
        normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

        % Generate channel estimates as a phase rotation in the
        % frequency domain.
        estimates = H(iRxPort) * exp(1i * linspace(0, 2 * pi, gridDims(1))') * ones(1, gridDims(2));

        % Create noisy modulated symbols.
        rxGrid(:, :, iRxPort) = estimates .* gridWithCfo + (noiseStdDev * normNoise);

        % Extract PUCCH symbols from the received grid.
        rxSymbols(:, iRxPort) = rxGrid(pucchDataIndices);
    end

    payloadData = struct('ACK', ack, 'SR', sr);
end
