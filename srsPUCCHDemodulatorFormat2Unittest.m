%srsPUCCHDemodulatorFormat2Unittest Unit tests for PUCCH Format 2 symbol demodulator functions.
%   This class implements unit tests for the PUCCH Format 2 symbol demodulator functions using
%   the matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUCCHDemodulatorFormat2Unittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUCCHDemodulatorFormat2Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_demodulator_format2').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHDemodulatorFormat2Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHDemodulatorFormat2Unittest Properties (TestParameter):
%
%   SymbolAllocation  - Symbols allocated to the PUCCH transmission.
%
%   PRBNum - Number of contiguous PRB allocated to PUCCH Format 2.
%
%   srsPUCCHDemodulatorFormat2Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHDemodulatorFormat2Unittest Methods (Access = protected):
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

classdef srsPUCCHDemodulatorFormat2Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_demodulator_format2'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pucch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_demodulator_format2' tests will be erased).
        outputPath = {['testPUCCHDemodulatorFormat2', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)

        %Symbols allocated to the PUCCH transmission.
        %
        %   The symbol allocation is by a structure with two fields:
        %   - a two-element array with the starting symbol (0...13) and the length (1...14)
        %     of the PUCCH transmission. Example: [13, 1], and
        %   - a logical flag for intra-slot frequency hopping.
        SymbolAllocation = { ...
            struct('Allocation', [0, 1], 'FrequencyHopping', false), ...
            struct('Allocation', [6, 2], 'FrequencyHopping', false), ...
            struct('Allocation', [12, 2], 'FrequencyHopping', false), ...
            struct('Allocation', [6, 2], 'FrequencyHopping', true), ...
            struct('Allocation', [12, 2], 'FrequencyHopping', true), ...
            };

        %Number of contiguous PRB allocated to PUCCH Format 2 (1...16).
        PRBNum = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pucch/pucch_demodulator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  unsigned                                 grid_nof_prb;\n');
            fprintf(fileID, '  unsigned                                 grid_nof_symbols;\n');
            fprintf(fileID, '  float                                    noise_var;\n');
            fprintf(fileID, '  pucch_demodulator::format2_configuration config;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                               context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '  file_vector<cf_t>                                       estimates;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       uci_codeword;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, PRBNum)
        %testvectorGenerationCases Generates a test vector for the given
        % Fixed Reference Channel.

            import srsLib.phy.upper.channel_modulation.srsDemodulator
            import srsLib.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate random cell ID.
            nCellID = randi([0, 1007]);

            % Generate a random NID.
            NID = randi([0, 1023]);

            % Generate a random RNTI.
            RNTI = randi([1, 65535]);

            % Maximum resource grid size.
            MaxGridSize = 275;

            % Resource grid starts at CRB0.
            nStartGrid = 0;

            % BWP start relative to CRB0.
            nStartBWP = randi([0, MaxGridSize - PRBNum - 1]);

            % BWP size.
            % PUCCH Format 2 frequency allocation must fit inside the BWP.
            nSizeBWP = randi([PRBNum, MaxGridSize - nStartBWP]);

            % PUCCH PRB Start relative to the BWP.
            PRBStart = randi([0, nSizeBWP - PRBNum]);

            % Fit resource grid size to the BWP.
            nSizeGrid = nStartBWP + nSizeBWP;

            % PRB set assigned to PUCCH Format 2 within the BWP.
            % Each element within the PRB set indicates the location of a
            % Resource Block relative to the BWP starting PRB.
            PRBSet = PRBStart : PRBStart + PRBNum - 1;

            % Normal cyclic prefix.
            cyclicPrefix = 'normal';

            % Configure the carrier according to the test parameters.
            carrier = nrCarrierConfig( ...
                NCellID=nCellID, ...
                NSizeGrid=nSizeGrid, ...
                NStartGrid=nStartGrid, ...
                CyclicPrefix=cyclicPrefix ...
                );

            % Resource grid dimensions.
            nofGridSubcs = nSizeGrid * 12;
            nofGridSymbols = carrier.SymbolsPerSlot;

            % No frequency hopping.
            if SymbolAllocation.FrequencyHopping
                frequencyHopping = 'intraSlot';
                secondPRBStart = randi([0, nSizeBWP - PRBNum]);
            else
                frequencyHopping = 'neither';
                secondPRBStart = 1;
            end

            % Configure the PUCCH.
            pucch = nrPUCCH2Config( ...
                NStartBWP=nStartBWP, ...
                NSizeBWP=nSizeBWP, ...
                SymbolAllocation=SymbolAllocation.Allocation, ...
                PRBSet=PRBSet, ...
                FrequencyHopping=frequencyHopping, ...
                SecondHopStartPRB=secondPRBStart, ...
                NID=NID, ...
                RNTI=RNTI ...
                );

            % Number of PUCCH Subcarriers.
            nofPUCCHSubcs = PRBNum * 12;

            % Number of PUCC Subcarriers used for DM-RS.
            % DM-RS is mapped to subcarriers 1, 4, 7, 10 of each PRB.
            nofPUCCHDMRSSubcs = 4 * PRBNum;

            nofPUCCHDataSubcs = nofPUCCHSubcs - nofPUCCHDMRSSubcs;

            % Number of PUCCH data RE in a single slot.
            nofPUCCHDataRE = nofPUCCHDataSubcs * SymbolAllocation.Allocation(2);

            % Number of bits that can be mapped to the available radio
            % resources.
            [dataSymbolIndices, info] = nrPUCCHIndices(carrier, pucch, IndexStyle='subscript', IndexBase='0based');
            uciCWLength = info.G;

            % Generate a random UCI codeword that fills the available PUCCH resources.
            uciCW = randi([0, 1], uciCWLength, 1);

            % Modulate PUCCH Format 2.
            modulatedSymbols = nrPUCCH(carrier, pucch, uciCW, OutputDataType='single');


            if (length(dataSymbolIndices) ~= nofPUCCHDataRE)
                error("Inconsistent UCI Codeword and PUCCH index list lengths");
            end

            % Create some noise samples with different variances.
            normNoise = (randn(nofPUCCHDataRE, 1) + 1i * randn(nofPUCCHDataRE, 1)) / sqrt(2);
            noiseStd = 0.1 + 0.9 * rand();
            noiseVar = noiseStd.^2;

            % Create random channel estimates with a single Rx port and Tx layer.
            % Create a full resource grid of estimates.
            estimates = (0.1 + 0.9 * rand(nofGridSubcs, nofGridSymbols)) + 1i * (0.1 + 0.9 * rand(nofGridSubcs, nofGridSymbols));
            estimates = estimates / sqrt(2);

            % Extract channel estimation coefficients corresponding to
            % PUCCH control data RE.
            dataChEsts = estimates(sub2ind(size(estimates), dataSymbolIndices(:, 1) + 1, dataSymbolIndices(:, 2) + 1));

            % Create noisy modulated symbols.
            channelSymbols = dataChEsts .* modulatedSymbols + (noiseStd * normNoise);

            % Equalize channel symbols.
            [eqSymbols, eqNoiseVars] = srsChannelEqualizer(channelSymbols, dataChEsts, 'ZF', noiseVar, 1);

            % Write each complex symbol and their associated indices into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, channelSymbols, dataSymbolIndices);

            % Write channel estimates to a binary file.
            testCase.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, estimates(:));

            % Convert equalized symbols into softbits.
            schSoftBits = srsDemodulator(eqSymbols(:), 'QPSK', eqNoiseVars(:));

            % Scrambling sequence for PUCCH.
            [scSequence, ~] = nrPUCCHPRBS(NID, RNTI, length(schSoftBits));

            % Encode the scrambling sequence into the sign, so it can be
            % used with soft bits.
            scSequence = -(scSequence * 2) + 1;

            % Apply descrambling.
            schSoftBits = schSoftBits .* scSequence;

            % Write soft bits to a binary file.
            testCase.saveDataFile('_test_output_sch_soft_bits', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = '{0}';

            % First PRB within the resource grid allocated to PUCCH.
            firstPRB = nStartBWP + PRBStart;
            % First PRB within the resource grid allocated to PUCCH for the second hop, if any.
            if SymbolAllocation.FrequencyHopping
                secondHopPRB = nStartBWP + secondPRBStart;
            else
                secondHopPRB = {};
            end

            pucchF2Config = {...
                portsString, ...                    % rx_ports
                firstPRB, ...                       % first_prb
                secondHopPRB, ...                   % second_hop_prb
                PRBNum, ...                         % nof_prb
                SymbolAllocation.Allocation(1), ... % start_symbol_index
                SymbolAllocation.Allocation(2), ... % nof_symbols
                RNTI, ...                           % rnti
                NID, ...                            % n_id
                };

            testCaseContext = { ...
                nSizeGrid, ...      % grid_nof_prb
                nofGridSymbols, ... % grid_nof_symbols
                noiseVar, ...       % noise_var
                pucchF2Config, ...  % config
                };

            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_input_estimates', '_test_output_sch_soft_bits');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHDemodulatorFormat2Unittest
