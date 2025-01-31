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
%   Numerology           - Subcarrier numerology (0, 1).
%   NumRxPorts           - Number of Rx antenna ports (2, 4).
%   SymbolAllocation     - PUCCH Format 1 time allocation as array
%                          containing the start symbol index and the number
%                          of symbols.
%   FrequencyHopping     - Frequency hopping type ('neither', 'intraSlot').
%   TxMode               - PUCCH transmission mode ('ACK', 'SR').
%   UEDensity            - UE density ('low', 'medium').
%
%   srsPUCCHProcessorFormat1Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat1Unittest Methods (Test, TestTags = {'testmex'}):
%
%   mexTest  - Tests the MEX-based implementation of the PUCCH Format 1 processor.
%
%   srsPUCCHProcessorFormat1Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrPUCCHDMRS, nrPUCCHDecode, nrPUCCH1Config.

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

classdef srsPUCCHProcessorFormat1Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format1'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pucch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format1' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat1', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier numerology (0, 1).
        Numerology = {0, 1}

        %Number of Rx antenna ports (2, 4).
        NumRxPorts = {2, 4}

        %PUCCH symbol allocation.
        %   The symbol allocation is described by a two-element row array with,
        %   in order, the first allocated symbol and the number of allocated
        %   symbols.
        SymbolAllocation = {[0, 14], [1, 13], [5, 5], [10, 4]}

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'}

        %PUCCH transmission mode ('ACK', 'SR').
        %   A PUCCH transmission can carry either HARQ-ACK bits (one or two) or a positive SR
        %   (and a zero-valued bit is transmitted).
        TxMode = {'ACK', 'SR'}

        %UE density ('low', 'medium').
        %   Determines the number of multiplexed PUCCH transmissions sharing resources:
        %   - 'low'     -> a single PUCCH transmission;
        %   - 'medium'  -> three equispaced initial cyclic shifts for each valid
        %                  time domain orthogonal cover code.
        UEDensity = {'low', 'medium'}
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct pucch_mux_data {\n');
            fprintf(fileID, '  unsigned             initial_cyclic_shift;\n');
            fprintf(fileID, '  unsigned             time_domain_occ;\n');
            fprintf(fileID, '  float                detection_metric;\n');
            fprintf(fileID, '  float                rsrp;\n');
            fprintf(fileID, '  unsigned             nof_harq_ack;\n');
            fprintf(fileID, '  std::vector<uint8_t> payload;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  std::string                            tx_mode;\n');
            fprintf(fileID, '  pucch_processor::format1_configuration common_config;\n');
            fprintf(fileID, '  float                                  epre;\n');
            fprintf(fileID, '  float                                  est_noise;\n');
            fprintf(fileID, '  std::vector<pucch_mux_data>            payloads;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, Numerology, SymbolAllocation, FrequencyHopping, NumRxPorts, TxMode, UEDensity)
        %testvectorGenerationCases Generates a test vector for the given numerology, symbol allocation,
        %   frequency hopping, number of antenna ports, transmission mode and UE density. The remaining
        %   parameters are set randomly.

            import srsLib.phy.upper.channel_processors.pucch.srsPUCCH1Detector
            import srsTest.helpers.approxbf16
            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            [rxGrid, pucchListIn, pucchListOut, configuration] = generateSimData(Numerology, SymbolAllocation, ...
                FrequencyHopping, NumRxPorts, TxMode, UEDensity);

            carrier = configuration.Carrier;
            pucchCommon = configuration.PUCCH;
            [results, epre, noiseVar] = srsPUCCH1Detector(carrier, pucchCommon, approxbf16(rxGrid), pucchListIn);
            assert(isfinite(epre))
            assert(isfinite(noiseVar))

            % Check the results are as expected.
            assertLength(testCase, results, length(pucchListIn), 'The lengths number of configured and processed PUCCH transmissions do not match.');

            nMuxPUCCHs = length(pucchListOut);
            nFalseAlarms = 0;
            for iPUCCH = 1:nMuxPUCCHs
                expectedPUCCH = pucchListOut(iPUCCH);
                actualPUCCH = results(iPUCCH);

                indexstr = [num2str(iPUCCH) ' of ' num2str(nMuxPUCCHs)];

                % ICS and OCCI between multiplexList and result list should coincide.
                assertEqual(testCase, actualPUCCH.InitialCyclicShift, expectedPUCCH.InitialCyclicShift, 'Results out of order');
                assertEqual(testCase, actualPUCCH.OCCI, expectedPUCCH.OCCI, 'Results out of order');

                if isempty(expectedPUCCH.Payload)
                    % UE is DTX-ing, PUCCH should be invalid.
                    nFalseAlarms = nFalseAlarms + actualPUCCH.isValid;
                else
                    switch TxMode
                    case 'ACK'
                        % Assert validity.
                        verifyTrue(testCase, actualPUCCH.isValid, ['PUCCH #', indexstr, ' is invalid in ACK mode.']);
                        % Assert the number of ACK bits.
                        assertLength(testCase, actualPUCCH.Bits, length(expectedPUCCH.Payload), ...
                        ['PUCCH #', indexstr, ' has the wrong number of bits.']);
                        % Check the ACK content.
                        verifyEqual(testCase, actualPUCCH.Bits, expectedPUCCH.Payload, ...
                        ['Detection error in PUCCH #', indexstr, '.']);
                    case 'SR'
                        % Assert validity.
                        verifyTrue(testCase, actualPUCCH.isValid, ['PUCCH #', indexstr, ' is invalid in SR mode.']);
                        % Assert the number of ACK bits.
                        assertLength(testCase, actualPUCCH.Bits, 0, ...
                        ['PUCCH #', indexstr, ' has the wrong number of bits.']);
                    end
                end
            end

            assertLessThanOrEqual(testCase, nFalseAlarms, 1, "Too may false alarms.");
            pucchDataIndices = configuration.PUCCHDataIndices;
            pucchDmrsIndices = configuration.PUCCHDMRSIndices;
            nSizeBWP = configuration.PUCCH.NSizeBWP;
            nStartBWP = configuration.PUCCH.NStartBWP;

            cyclicPrefix = carrier.CyclicPrefix;

            % Extract the allocated resource elements from the grid.
            nofPUCCHREPort = length(pucchDataIndices) + length(pucchDmrsIndices);
            nofTotalREPort = numel(rxGrid(:, :, 1));
            rxGridSymbols = complex(nan(1, NumRxPorts * nofPUCCHREPort));
            rxGridIndices = complex(nan(NumRxPorts * nofPUCCHREPort, 3));

            onePortindices = [nrPUCCHIndices(carrier, pucchCommon, 'IndexStyle','subscript', 'IndexBase','0based'); ...
                    nrPUCCHDMRSIndices(carrier, pucchCommon, 'IndexStyle','subscript', 'IndexBase','0based')];

            for iRxPort = 0:(NumRxPorts - 1)
                offsetIn = iRxPort * nofTotalREPort;
                offsetOut = iRxPort * nofPUCCHREPort;
                rxGridSymbols(offsetOut + (1:nofPUCCHREPort)) = [rxGrid(pucchDataIndices + offsetIn); rxGrid(pucchDmrsIndices + offsetIn)];

                indices = onePortindices;
                indices(:,3) = iRxPort;

                rxGridIndices(offsetOut + (1:nofPUCCHREPort), :) = indices;
            end

            % Write each complex symbol, along with its associated index,
            % into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndices);

            % Generate a 'slot_point' configuration.
            slotPointConfig = {...
                Numerology, ...                                             % numerology
                carrier.NFrame * carrier.SlotsPerFrame + carrier.NSlot, ... % system slot number
                };

            % Generate a 'cyclic_prefix' configuration.
            cyclicPrefixConfig = matlab2srsCyclicPrefix(cyclicPrefix);

            secondHopConfig = {};
            if strcmp(FrequencyHopping, 'intraSlot')
                secondHopConfig = {pucchCommon.SecondHopStartPRB};
            end

            % Reception port list.
            portsString = ['{' num2str(0:(NumRxPorts-1), "%d,") '}'];

            % Generate PUCCH common configuration.
            pucchConfigCommon = {...
                'std::nullopt', ...                  % context
                slotPointConfig, ...                 % slot
                nSizeBWP, ...                        % bwp_size_rb
                nStartBWP, ...                       % bwp_start_rb
                cyclicPrefixConfig, ...              % cp
                pucchCommon.PRBSet, ...              % starting_prb
                secondHopConfig, ...                 % second_hop_prb
                carrier.NCellID, ...                 % n_id
                0, ...                               % nof_harq_ack (unused, see multiplexed list)
                portsString, ...                     % ports
                0, ...                               % initial_cyclic_shift (unused, see multiplexed list)
                pucchCommon.SymbolAllocation(2), ... % nof_symbols
                pucchCommon.SymbolAllocation(1), ... % start_symbol_index
                0, ...                               % time_domain_occ (unused, see multiplexed list)
                };

            % Multiplexed PUCCH payloads
            pucchMuxInfo = cell(nMuxPUCCHs, 1);
            for iPUCCH = 1:nMuxPUCCHs
                helpPUCCH = pucchListOut(iPUCCH);
                nACKbits = pucchListIn(iPUCCH).NumBits;
                assert(isfinite(results(iPUCCH).RSRP))
                pucchMuxInfo{iPUCCH} = { helpPUCCH.InitialCyclicShift, helpPUCCH.OCCI, ...
                    results(iPUCCH).DetectionMetric, results(iPUCCH).RSRP, nACKbits, num2cell(helpPUCCH.Payload) };
            end

            pucchEntry = {['"', TxMode, '"'], pucchConfigCommon, epre, noiseVar, pucchMuxInfo};

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, ...
                pucchEntry, false, '_test_input_symbols');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(testCase, Numerology, SymbolAllocation, FrequencyHopping, NumRxPorts, TxMode, UEDensity)
        %mexTest Tests the mex wrapper of the srsRAN PUCCH processor for Format 1.
        %   mexTest(testCase, numerology, intraSlotFreqHopping, SymbolAllocation, ackSize)
        %   runs a short simulation with a PUCCH transmission specified by the given
        %   numerology, symbol allocation, frequency hopping, number of antenna ports, transmission mode and UE density.
        %   The remaining parameters are set randomly.

            import srsMEX.phy.srsPUCCHProcessor

            % Generate simulation data: two multiplexed PUCCHs with different cyclic shifts.
            [rxGrid, ackList, configuration] = generateSimData(numerology, SymbolAllocation, ...
                FrequencyHopping, NumRxPorts, TxMode, UEDensity);

            srspucch = srsPUCCHProcessor;

            uci1 = srspucch(configuration.carrier, configuration.pucchList(1), rxGrid, NumHARQAck=ackSize);
            uci2 = srspucch(configuration.carrier, configuration.pucchList(2), rxGrid, NumHARQAck=ackSize);

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

            % ACKs should be correct.
            assertEqual(testCase, uci1.HARQAckPayload, int8(ackList(:, 1)), 'The ACK bits of the first PUCCH are corrupted.');
            assertEqual(testCase, uci2.HARQAckPayload, int8(ackList(:, 2)), 'The ACK bits of the second PUCCH are corrupted.');
        end
    end % of methods (Test, TestTags = {'testmex'})

end % of classdef srsPUCCHProcessorFormat1Unittest

%Generates simulation data (ACKS, Rx side resource grid, configurations).
%   Set NofOCCIs to zero to use all possible OCCIs.
function [rxGrid, pucchListIn, pucchListOut, configuration] = generateSimData(Numerology, SymbolAllocation, ...
    FrequencyHopping, NumRxPorts, TxMode, UEDensity)

    % Use a unique NCellID, NSlot for each test.
    nCellID = randi([0, 1007]);

    % Use a random slot number from the allowed range.
    nSlot = randi([0, 10 * pow2(Numerology) - 1]);

    % Fixed parameter values.
    nStartBWP = 1;
    nSizeBWP = 51;
    nSizeGrid = nStartBWP + nSizeBWP;
    nStartGrid = 0;
    cyclicPrefix = 'normal';
    groupHopping = 'neither';

    % Random frame number.
    nFrame = randi([0, 1023]);

    % Random start PRB index for both hops (second hop may be unused).
    tmpPRBs  = randperm(nSizeBWP, 2) - 1;
    PRBSet = tmpPRBs(1);
    secondHopStartPRB = tmpPRBs(2);

    % Configure the carrier according to the test parameters.
    subcarrierSpacing = 15 * (2.^Numerology);
    carrier = nrCarrierConfig( ...
        NCellID=nCellID, ...
        SubcarrierSpacing=subcarrierSpacing, ...
        NSizeGrid=nSizeGrid, ...
        NStartGrid=nStartGrid, ...
        NSlot=nSlot, ...
        NFrame=nFrame, ...
        CyclicPrefix=cyclicPrefix ...
        );


    % Configure the PUCCH base according to the test parameters.
    pucchCommon = nrPUCCH1Config( ...
        SymbolAllocation=SymbolAllocation, ...
        PRBSet=PRBSet, ...
        FrequencyHopping=FrequencyHopping, ...
        GroupHopping=groupHopping, ...
        SecondHopStartPRB=secondHopStartPRB, ...
        OCCI=0, ... unused
        NStartBWP=nStartBWP, ...
        NSizeBWP=nSizeBWP, ...
        InitialCyclicShift=0 ... unused
        );

    if strcmp(FrequencyHopping, 'intraSlot')
        % When intraslot frequency hopping is enabled, the OCCI
        % value must be less than the floor of one-fourth of the
        % number of OFDM symbols allocated for the PUCCH.
        maxOCCindex = floor(SymbolAllocation(2) / 4) - 1;
    else
        % When intraslot frequency hopping is disabled, the OCCI value
        % must be less than the floor of half of the number of OFDM
        % symbols allocated for the PUCCH.
        maxOCCindex = floor(SymbolAllocation(2) / 2) - 1;
    end

    % Maximum initial cyclic shift and maximum OCC index.
    maxICS = 11;
    maxPUCCHs = (maxOCCindex + 1) * (maxICS + 1);

    % Create overlapped list of PUCCHs.
    switch UEDensity
        case 'low'
            nPUCCHs = 1;
        case 'medium'
            nPUCCHs = 3 * (maxOCCindex + 1);
    end

    pucchListIn(nPUCCHs) = struct( ...
        'InitialCyclicShift', 0, ...
        'OCCI', 0, ...
        'NumBits', []);

    pucchListOut(nPUCCHs) = struct( ...
        'InitialCyclicShift', 0, ...
        'OCCI', 0, ...
        'Payload', []);

    pucchKeys = 0:(maxPUCCHs / nPUCCHs):maxPUCCHs;
    pucchKeys = pucchKeys(randperm(nPUCCHs));

    % Create resource grid.
    gridTmp = nrResourceGrid(carrier, "OutputDataType", "single");
    grid = repmat(gridTmp, 1, 1, NumRxPorts);
    gridDims = size(grid);

    ofdmInfo = nrOFDMInfo(carrier);
    cpLengths = ofdmInfo.CyclicPrefixLengths(1:gridDims(2));
    cpLengths = cumsum(cpLengths) / ofdmInfo.Nfft;

    % Get the PUCCH control data indices, common for all PUCCH.
    pucchDataIndices = nrPUCCHIndices(carrier, pucchCommon);

    % Get the DM-RS indices.
    pucchDmrsIndices = nrPUCCHDMRSIndices(carrier, pucchCommon);

    for pucchIndex = 1:nPUCCHs
        key = pucchKeys(pucchIndex);

        % Set initialy cyclic shift and OCC index.
        ics = mod(key, maxICS + 1);
        occi = floor(key / (maxICS + 1));
        assert(occi <= maxOCCindex);
        pucchListIn(pucchIndex).InitialCyclicShift = ics;
        pucchListIn(pucchIndex).OCCI = occi;
        pucchListOut(pucchIndex).InitialCyclicShift = ics;
        pucchListOut(pucchIndex).OCCI = occi;

        pucch = pucchCommon;
        pucch.InitialCyclicShift = ics;
        pucch.OCCI = occi;

        % Random payload.
        payload = generateRandomPayload(TxMode);
        if strcmp(TxMode, 'SR')
            pucchListIn(pucchIndex).NumBits = 0;
        else
            pucchListIn(pucchIndex).NumBits = length(payload);
        end

        % If multiplexing, assume half of the UEs are DTX-ing: clear the payload
        % and continue without generating the signal.
        if ((nPUCCHs > 2) && (mod(pucchIndex, 2) == 0))
            pucchListOut(pucchIndex).Payload = [];
            continue;
        end

        pucchListOut(pucchIndex).Payload = payload;

        % Modulate PUCCH and map it.
        pucchData = nrPUCCH(carrier, pucch, payload, OutputDataType='single');
        gridTmp(pucchDataIndices) = pucchData;

        % Generate and map the DM-RS sequence.
        pucchDmrs = nrPUCCHDMRS(carrier, pucch, OutputDataType='single');
        gridTmp(pucchDmrsIndices) = pucchDmrs;

        % Common CFO for all ports.
        cfoMax = 100; % Hz
        cfo = single(exp(2i * pi * ((0:gridDims(2)-1) + cpLengths) * cfoMax ...
            * 2 * (rand - 0.5) / carrier.SubcarrierSpacing / 1000));

        % PUCCH is transmitted from one port only - we can replicate it once for
        % each receive port and apply the channel.
        for iRxPort = 1:NumRxPorts
            % Generate a random channel as a random complex coefficient with amplitude between 0.5
            % and 1.5 plus a random delay between 200 and 800 ns (recall that TDLC300 has a mean delay
            % of 200 ns and an rms delay spread of 300 ns).
            delay = 200 + rand * 600;
            channel = single((0.5 + rand) * exp(2i * pi * rand ...
                + 2i * pi * (0:gridDims(1)-1)' * delay * carrier.SubcarrierSpacing * 1e-6));

            grid(:, :, iRxPort) = grid(:, :, iRxPort) + gridTmp .* (channel * cfo);
        end
    end

    % Noise variance, normalized with respect to the average received PUCCH power.
    snrdB = 30;
    noiseStdDev = 10^(-snrdB / 20);

    normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

    rxGrid = grid + noiseStdDev * normNoise;

    configuration = struct( ...
        'PUCCH', pucchCommon, ...
        'PUCCHDataIndices', pucchDataIndices, ...
        'PUCCHDMRSIndices', pucchDmrsIndices, ...
        'Carrier', carrier);
end

function payload = generateRandomPayload(TxMode)
    if (strcmp(TxMode, 'SR'))
        payload = 0;
    else % TXMode is 'ACK'
        nBits = randi(2);
        payload = randi([0, 1], nBits, 1);
    end
end
