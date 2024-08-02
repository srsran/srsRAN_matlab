%srsPUCCHDetectorFormat1Unittest Unit test for PUCCH Format1 detector.
%   This class implements unit tests for the PUCCH Format1 detector using the
%   matlab.unittest framework. The simplest use consists in creating an object
%   with
%       testCase = srsPUCCHDetectorFormat1Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHDetectorFormat1Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_detector').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_processors').
%
%   srsPUCCHDetectorFormat1Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHDetectorFormat1Unittest Properties (TestParameter):
%
%   numerology       - Numerology index (0, 1).
%   NumRxPorts       - Number of Rx antenna ports (1, 2, 4).
%   SymbolAllocation - PUCCH symbol allocation.
%   FrequencyHopping - Frequency hopping type ('neither', 'intraSlot').
%   ackSize          - Number of HARQ-ACK bits (0, 1, 2).
%   srSize           - Number of SR bits (0, 1).
%
%   srsPUCCHDetectorFormat1Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given numerology,
%                               number of Rx antenna ports, symbol allocation,
%                               frequency hopping, number of ACK and SR bits.
%
%   srsPUCCHDetectorFormat1Unittest Methods (TestTags = {'testmex'}):
%
%   mexTest  - Tests the MEX-based implementation of the PUCCH detector for Format 1.
%
%   srsPUCCHDetectorFormat1Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrPUCCH1, nrPUCCH.

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

classdef srsPUCCHDetectorFormat1Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_detector'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_detector' tests will be erased).
        outputPath = {['testPUCCHdetector', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Numerology index (0, 1).
        %   Allows to compute the subcarrier spacing in kilohertz as 15 * 2^numerology.
        %   Note: Higher numerologies are currently not considered.
        numerology = {0, 1}

        %Number of Rx antenna ports (1, 2, 4).
        NumRxPorts = {1, 2, 4}

        %PUCCH symbol allocation.
        %   The symbol allocation is described by a two-element row array with,
        %   in order, the first allocated symbol and the number of allocated
        %   symbols.
        SymbolAllocation = {[0, 14], [1, 13], [5, 5], [10, 4]}

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'}

        %Number of HARQ-ACK bits (0, 1, 2).
        ackSize = {0, 1, 2}

        %Number of SR bits (0, 1).
        %   Note: No SR bit is sent if ackSize > 0. Also, no PUCCH is sent if ackSize == 0
        %   and the SR is negative (i.e., the SR bit is set to 0).
        srSize = {0, 1}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.

            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch_detector.h"\n');
            fprintf(fileID, '#include "srsran/ran/cyclic_prefix.h"\n');
            fprintf(fileID, '#include "srsran/ran/pucch/pucch_mapping.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'pucch_detector::format1_configuration                    cfg       = {};\n');
            fprintf(fileID, 'float                                                    noise_var = 0;\n');
            fprintf(fileID, 'std::vector<uint8_t>                                     sr_bit;\n');
            fprintf(fileID, 'std::vector<uint8_t>                                     ack_bits;\n');
            fprintf(fileID, 'file_vector<resource_grid_reader_spy::expected_entry_t>  received_symbols;\n');
            fprintf(fileID, 'file_vector<resource_grid_reader_spy::expected_entry_t>  ch_estimates;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, numerology, NumRxPorts, SymbolAllocation, ...
                FrequencyHopping, ackSize, srSize)
        %testvectorGenerationCases generates a test vector for the given numerology,
        %   number of Rx antenna ports, symbol allocation, frequency hopping, number of
        %   ACK and SR bits.

            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.matlab2srsPUCCHGroupHopping
            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID.
            testID = obj.generateTestID('_test_received_symbols');

            [rxSymbols, ack, sr, channelCoefs, configuration] = ...
                generateSimData(numerology, NumRxPorts, SymbolAllocation, FrequencyHopping, ...
                ackSize, srSize);

            nREs = size(configuration.Indices, 1);
            indices = nan(NumRxPorts * nREs, 3);
            for iPort = 0:(NumRxPorts - 1)
                ix = iPort * nREs + (1:nREs);
                indices(ix, 1:2) = configuration.Indices(:, 1:2);
                indices(ix, 3) = iPort;
            end

            obj.saveDataFile('_test_received_symbols', testID, ...
                @writeResourceGridEntryFile, rxSymbols(:), indices);

            obj.saveDataFile('_test_ch_estimates', testID, ...
                @writeResourceGridEntryFile, channelCoefs(:), indices);

            cyclicPrefixConfig = matlab2srsCyclicPrefix(configuration.CyclicPrefix);
            groupHoppingConfig = matlab2srsPUCCHGroupHopping(configuration.GroupHopping);

            if NumRxPorts == 1
                ports = {0};
            else
                ports = 0:(NumRxPorts - 1);
            end

            betaPUCCH = 1;
            pucch = configuration.PUCCH;

            % Generate PUCCH Format 1 configuration.
            pucchF1Config = {...
                {numerology, configuration.NSlot},   ... % slot
                cyclicPrefixConfig,                  ... % cp
                configuration.PRBSet,                ... % starting_prb
                configuration.SecondHopConfig,       ... % second_hop_prb
                pucch.SymbolAllocation(1),           ... % start_symbol_index
                pucch.SymbolAllocation(2),           ... % nof_symbols
                groupHoppingConfig,                  ... % group_hopping
                ports,                               ... % ports
                betaPUCCH,                           ... % beta_pucch
                pucch.OCCI,                          ... % time_domain_occ
                pucch.InitialCyclicShift,            ... % initial_cyclic_shift
                configuration.NCellID,               ... % n_id
                ackSize,                             ... % nof_harq_ack
                };

            % Generate the test case entry.
            testCaseString = obj.testCaseToString(testID, {pucchF1Config, ...
                configuration.NoiseVar, num2cell(sr), num2cell(ack)}, ...
                false, '_test_received_symbols', '_test_ch_estimates');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases(...)
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, numerology, NumRxPorts, SymbolAllocation, FrequencyHopping, ackSize, srSize)
        %mexTest Tests the mex wrapper of the srsRAN PUCCH detector for Format 1.
        %   mexTest(testCase, numerology, SymbolAllocation, FrequencyHopping, ackSize, srSize)
        %   runs a short simulation with a PUCCH transmission specified by the given
        %   numerology, symbol allocation, frequency hopping, number of ACK and SR bits.

            import srsMEX.phy.srsPUCCHDetector

            [rxSymbols, ack, sr, channelCoefs, configuration] = ...
                generateSimData(numerology, NumRxPorts, SymbolAllocation, FrequencyHopping, ...
                ackSize, srSize);

            % Create a PUCCH Format 1 detector.
            srspucch = srsPUCCHDetector;

            carrier = configuration.Carrier;

            % Copy the received signal into a resource grid.
            rxGrid = nrResourceGrid(carrier, NumRxPorts);

            nREs = size(configuration.Indices, 1);
            indices = nan(NumRxPorts * nREs, 1);
            indices(1:nREs) = sub2ind(size(rxGrid), configuration.Indices(:, 1) + 1, ...
                configuration.Indices(:, 2) + 1, ones(nREs, 1));
            for iPort = 2:NumRxPorts
                ix = (1:nREs) + (iPort - 1) * nREs;
                indices(ix) = sub2ind(size(rxGrid), configuration.Indices(:, 1) + 1, ...
                    configuration.Indices(:, 2) + 1, ones(nREs, 1) * iPort);
            end

            rxGrid(indices) = rxSymbols;

            % Copy the estimated channel coefficients into a resource grid.
            chGrid = nrResourceGrid(carrier, NumRxPorts);
            chGrid(indices) = channelCoefs;

            % Run the detector.
            uci = srspucch(carrier, configuration.PUCCH, ackSize, rxGrid, chGrid, configuration.NoiseVar * ones(NumRxPorts, 1));

            if (ackSize == 0)
                if (srSize == 0)
                    assertFalse(obj, uci.isValid, 'An empty PUCCH occasion should return an ''invalid'' UCI.');
                    return;
                end
                if (sr == 1)
                    assertTrue(obj, uci.isValid, 'A positive SR-only PUCCH should return a ''valid'' UCI.');
                    return;
                end
                assertFalse(obj, uci.isValid, 'A negative SR-only PUCCH should return an ''invalid'' UCI.');
                return;
            end

            assertTrue(obj, uci.isValid, 'An ACK-carrying PUCCH should return a ''valid'' UCI.');

            assertLength(obj, uci.HARQAckPayload, ackSize, 'Wrong number of ACK bits.');
            assertEqual(obj, uci.HARQAckPayload, int8(ack), 'HARQ-ACK bits do not match.');

        end % of function mexTest(obj, numerology, SymbolAllocation, ...
    end % of methods (Test, TestTags = {'testmex'})

end % of srsPUCCHDetectorFormat1Unittest < srsTest.srsBlockUnittest

%Generates simulation data (modulated symbols, ACK and SR values, channel coefficients and configuration objects).
function [rxSymbols, ack, sr, channelCoefs, configuration] = generateSimData(numerology, ...
        nPorts, symbolAllocation, frequencyHopping, ackSize, srSize)

    import srsLib.phy.helpers.srsConfigureCarrier
    import srsLib.phy.upper.channel_processors.srsPUCCH1

    % Generate random cell ID and slot number.
    NCellID = randi([0, 1007]);

    if numerology == 0
        NSlot = randi([0, 9]);
    else
        NSlot = randi([0, 19]);
    end

    % Fix BWP size and start as well as the frame number, since they
    % are irrelevant for the test.
    NSizeBWP = 51;
    NStartBWP = 1;
    NSizeGrid = NSizeBWP + NStartBWP;
    NStartGrid = 0;
    NFrame = 0;

    % Cyclic prefix can only be normal in the supported numerologies.
    CyclicPrefix = 'normal';

    % Configure the carrier according to the test parameters.
    SubcarrierSpacing = 15 * (2 .^ numerology);
    carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, NSizeGrid, ...
        NStartGrid, NSlot, NFrame, CyclicPrefix);

    % PRB assigned to PUCCH Format 1 within the BWP.
    PRBSet  = randi([0, NSizeBWP - 1]);

    if strcmp(frequencyHopping, 'intraSlot')
        % When intraslot frequency hopping is enabled, the OCCI value must be less
        % than one fourth of the number of OFDM symbols allocated for the PUCCH.
        maxOCCindex = max([floor(symbolAllocation(2) / 4) - 1, 0]);
        secondHopStartPRB = randi([1, NSizeBWP - 1]);
        secondHopConfig = {secondHopStartPRB};
    else
        % When intraslot frequency hopping is disabled, the OCCI value must be less
        % than one half of the number of OFDM symbols allocated for the PUCCH.
        maxOCCindex = max([floor(symbolAllocation(2) / 2) - 1, 0]);
        secondHopStartPRB = 0;
        secondHopConfig = {};
    end % of if strcmp(frequencyHopping, 'intraSlot')

    occi = randi([0, maxOCCindex]);

    % We don't test group hopping or sequence hopping.
    groupHopping = 'neither';

    % The initial cyclic shift can be set randomly.
    possibleShifts = 0:3:9;
    initialCyclicShift = possibleShifts(randi([1, 4]));

    % Configure the PUCCH.
    pucch = nrPUCCH1Config( ...
        SymbolAllocation=symbolAllocation, ...
        PRBSet=PRBSet, ...
        FrequencyHopping=frequencyHopping, ...
        GroupHopping=groupHopping, ...
        SecondHopStartPRB=secondHopStartPRB, ...
        InitialCyclicShift=initialCyclicShift, ...
        OCCI=occi ...
        );

    ack = randi([0, 1], ackSize, 1);
    sr = randi([0, 1], srSize, 1);

    % Generate PUCCH Format 1 symbols.
    [symbols, indices] = srsPUCCH1(carrier, pucch, ack, sr);

    if isempty(symbols)
        symbols = complex(zeros(size(indices, 1), 1));
    end

    nSymbols = length(symbols);

    rxSymbols = complex(nan(nSymbols, nPorts));
    channelCoefs = complex(nan(nSymbols, nPorts));

    for iPort = 1:nPorts
        channelTmp = randn(length(symbols), 2) * [1; 1j] / sqrt(2);
        % Ensure no channel is very small.
        channelTmpAbs = abs(channelTmp);
        mask = (channelTmpAbs < 0.1);
        channelTmp(mask) = channelTmp(mask) ./ channelTmpAbs(mask) * 0.1;

        % AWGN.
        snrdB = 20;
        noiseVar = 10^(-snrdB / 10);
        noiseSymbols = randn(length(symbols), 2) * [1; 1j] * sqrt(noiseVar / 2);

        channelCoefs(:, iPort) = channelTmp;
        rxSymbols(:, iPort) = symbols .* channelTmp + noiseSymbols;
    end

    configuration = struct();
    configuration.Indices = indices;
    configuration.CyclicPrefix = CyclicPrefix;
    configuration.GroupHopping = groupHopping;
    configuration.NSlot = NSlot;
    configuration.PRBSet = PRBSet;
    configuration.SecondHopConfig = secondHopConfig;
    configuration.PUCCH = pucch;
    configuration.Carrier = carrier;
    configuration.NCellID = NCellID;
    configuration.NoiseVar = noiseVar;
end
