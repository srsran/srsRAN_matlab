%srsPUCCHDemodulatorFormat3Unittest Unit tests for PUCCH Format 3 symbol demodulator functions.
%   This class implements unit tests for the PUCCH Format 3 symbol demodulator functions using
%   the matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUCCHDemodulatorFormat3Unittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUCCHDemodulatorFormat3Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_demodulator_format3').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors/pucch').
%
%   srsPUCCHDemodulatorFormat3Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHDemodulatorFormat3Unittest Properties (TestParameter):
%
%   SymbolAllocation  - Symbols allocated to the PUCCH transmission.
%   PRBNum            - Number of contiguous PRB allocated to PUCCH Format 3.
%   FrequencyHopping  - Frequency hopping type ('neither', 'intraSlot').
%   AdditionalDMRS    - Additional DM-RS flag.
%   Modulation        - Modulation type ('QPSK', 'pi/2-BPSK').
%
%   srsPUCCHDemodulatorFormat3Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHDemodulatorFormat3Unittest Methods (Access = protected):
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

classdef srsPUCCHDemodulatorFormat3Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_demodulator_format3'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pucch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_demodulator_format3' tests will be erased).
        outputPath = {['testPUCCHDemodulatorFormat3', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)

        %PUCCH symbol allocation.
        %   The symbol allocation is described by a two-element row array with,
        %   in order, the first allocated symbol and the number of allocated
        %   symbols.
        SymbolAllocation = {[0, 14], [1, 13], [5, 5], [10, 4]};

        %Number of contiguous PRB allocated to PUCCH Format 3.
        PRBNum = {1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 16};

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'};

        %Additional DM-RS flag. If true, more OFDM symbols are filled with DM-RS.
        AdditionalDMRS = {true, false};

        %Modulation type ('QPSK', 'pi/2-BPSK').
        Modulation = {'QPSK', 'pi/2-BPSK'};
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
            fprintf(fileID, '  pucch_demodulator::format3_configuration config;\n');
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
        function testvectorGenerationCases(testCase, SymbolAllocation, PRBNum, FrequencyHopping, AdditionalDMRS, Modulation)
        %testvectorGenerationCases Generates a test vector for the given
        % symbol allocation, number of PRB, frequency hopping, additional
        % DM-RS and modulation parameters.

            import srsLib.phy.upper.channel_processors.pucch.srsPUCCH3Demodulator
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
            % PUCCH Format 3 frequency allocation must fit inside the BWP.
            nSizeBWP = randi([PRBNum, MaxGridSize - nStartBWP]);

            % PUCCH PRB Start relative to the BWP.
            PRBStart = randi([0, nSizeBWP - PRBNum]);

            % Fit resource grid size to the BWP.
            nSizeGrid = nStartBWP + nSizeBWP;

            % PRB set assigned to PUCCH Format 3 within the BWP.
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
            if strcmp(FrequencyHopping, 'intraSlot')
                secondPRBStart = randi([0, nSizeBWP - PRBNum]);
            else
                secondPRBStart = 1;
            end

            % Configure the PUCCH.
            pucch = nrPUCCH3Config( ...
                NStartBWP=nStartBWP, ...
                NSizeBWP=nSizeBWP, ...
                Modulation=Modulation, ...
                SymbolAllocation=SymbolAllocation, ...
                PRBSet=PRBSet, ...
                FrequencyHopping=FrequencyHopping, ...
                SecondHopStartPRB=secondPRBStart, ...
                NID=NID, ...
                RNTI=RNTI, ...
                AdditionalDMRS=AdditionalDMRS ...
                );

            % Number of bits that can be mapped to the available radio
            % resources.
            [dataSymbolIndices, info] = nrPUCCHIndices(carrier, pucch, IndexStyle='subscript', IndexBase='0based');
            uciCWLength = info.G;
            nofPUCCHDataRE = info.Gd;

            % Generate a random UCI codeword that fills the available PUCCH resources.
            uciCW = randi([0, 1], uciCWLength, 1);

            % Modulate PUCCH Format 3.
            modulatedSymbols = nrPUCCH(carrier, pucch, uciCW, OutputDataType='single');

            if (length(dataSymbolIndices) ~= nofPUCCHDataRE)
                error("Inconsistent UCI Codeword and PUCCH index list lengths");
            end

            % Create some noise samples with different variances. Round standard
            % deviation to reduce double to float error in the soft-demodulator.
            normNoise = (randn(nofPUCCHDataRE, 1) + 1i * randn(nofPUCCHDataRE, 1)) / sqrt(2);
            noiseStd = round(0.1 + 0.9 * rand(), 1);
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

            % Write each complex symbol and their associated indices into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, channelSymbols, dataSymbolIndices);

            % Write channel estimates to a binary file.
            testCase.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, estimates(:));

            % Demodulate PUCCH Format 3.
            softBits = srsPUCCH3Demodulator(pucch, channelSymbols, dataChEsts, noiseVar);

            % Write soft bits to a binary file.
            testCase.saveDataFile('_test_output_sch_soft_bits', testID, @writeInt8File, softBits);

            % Reception port list.
            portsString = '{0}';

            % First PRB within the resource grid allocated to PUCCH.
            firstPRB = nStartBWP + PRBStart;
            % First PRB within the resource grid allocated to PUCCH for the second hop, if any.
            if strcmp(FrequencyHopping, 'intraSlot')
                secondHopPRB = nStartBWP + secondPRBStart;
            else
                secondHopPRB = {};
            end

            pucchF3Config = {...
                portsString, ...                % rx_ports
                firstPRB, ...                   % first_prb
                secondHopPRB, ...               % second_hop_prb
                PRBNum, ...                     % nof_prb
                SymbolAllocation(1), ...        % start_symbol_index
                SymbolAllocation(2), ...        % nof_symbols
                RNTI, ...                       % rnti
                NID, ...                        % n_id
                AdditionalDMRS, ...             % additional_dmrs
                strcmp(Modulation, 'pi/2-BPSK') % pi2_bpsk
                };

            testCaseContext = { ...
                nSizeGrid, ...      % grid_nof_prb
                nofGridSymbols, ... % grid_nof_symbols
                noiseVar, ...       % noise_var
                pucchF3Config, ...  % config
                };

            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_input_estimates', '_test_output_sch_soft_bits');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHDemodulatorFormat3Unittest
