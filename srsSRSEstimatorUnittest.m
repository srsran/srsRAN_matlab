%srsSRSEstimatorUnittest Unit tests for SRS processor functions.
%   This class implements unit tests for the SRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsSRSEstimatorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsSRSEstimatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'srs_estimator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsSRSEstimatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsSRSEstimatorUnittest Properties (TestParameter):
%
%   Numerology    - Defines the subcarrier spacing (0, 1, 2, 3, 4).
%   NumSRSSymbols - Number of OFDM symbols for SRS.
%   NumSRSPorts   - Number of transmit antenna ports.
%   NumRxPorts    - Number of receive antenna ports.
%   KTC           - Comb size.
%
%   srsSRSEstimatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsSRSEstimatorUnittest Methods (Access = protected):
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

classdef srsSRSEstimatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'srs_estimator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors/srs'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'srs_estimator' tests will be erased).
        outputPath = {['testSRS', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)

        %Numerology, it determines the subcarrier spacing.
        Numerology = {0 1}
        
        %Number of SRS symbols.
        NumSRSSymbols = {1 2 4}
        
        %Number of SRS transmit ports.
        NumSRSPorts = {2 4}

        %Number of SRS receive ports.
        NumRxPorts = {1 2 4}

        %Comb size, 2 or 4.
        KTC = {2 4}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/srs/srs_estimator_configuration.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/srs/srs_estimator_result.h"\n');
            fprintf(fileID, '#include "srsran/ran/phy_time_unit.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_context {\n');
            fprintf(fileID, '  srs_estimator_configuration config;\n');
            fprintf(fileID, '  srs_estimator_result        result;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  test_context                                            context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> rx_grid;\n');
            fprintf(fileID, '};\n');
        end

    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, Numerology, NumSRSPorts, NumSRSSymbols, NumRxPorts, KTC)
        %testvectorGenerationCases Generates a test vector for the given 
        %configuration 
        %   NCellID, NSlot and PRB occupation are randomly generated.

            import srsTest.helpers.cellarray2str
            import srsTest.helpers.writeResourceGridEntryFile
            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsSRSValidateConfig
            
            % Current fixed parameter values.
            NSizeGrid = 270;
            NStartGrid = 0;
            
            switch(Numerology)
                case 0
                    NSlot = randi([0, 9]);                    
                case 1
                    NSlot = randi([0, 19]);
                case 2 
                    NSlot = randi([0, 39]);
                case 3
                    NSlot = randi([0, 79]);
                case 4
                    NSlot = randi([0, 159]);
                otherwise
                    return;
            end                  

            SubcarrierSpacing = 15 * (2 .^ Numerology);

            % Use a random NCellID, NFrame.
            NCellID = randi([0, 1007]);
            NFrame = randi([0, 1023]);
            CyclicPrefix = 'normal';
            
            % Configure the carrier according to the test parameters.
            carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing,...
                NSizeGrid, NStartGrid, NSlot, NFrame, CyclicPrefix);

            % Generate random SRS parameters.
            SymbolStart = randi([0, 14 - NumSRSSymbols]);
            NSRSID = randi([0, 1023]);

            srs = struct();
            while ~srsSRSValidateConfig(carrier, srs) 
                % Generate random SRS parameters that could be invalid.
                FrequencyStart = randi([0, 10]);
                CSRS = randi([0, 63]);
                BSRS = randi([0, 3]);
                KBarTC = randi([0, KTC - 1]);
                BHop = randi([BSRS, 3]);
                CyclicShift = randi([0, 11]);
                NRRC = randi([0, 67]);
                
                % Create the SRS configuration according to the test parameters.
                srs = nrSRSConfig('NumSRSPorts', NumSRSPorts,...
                    'SymbolStart', SymbolStart,...
                    'NumSRSSymbols', NumSRSSymbols,...
                    'FrequencyStart', FrequencyStart,...
                    'CSRS', CSRS,...
                    'BSRS', BSRS,...
                    'BHop', BHop,...
                    'KTC', KTC,...
                    'KBarTC', KBarTC,...
                    'NSRSID', NSRSID,...
                    'CyclicShift', CyclicShift,...
                    'NRRC', NRRC);
            end

            % Generate a unique test ID.
            TestID = testCase.generateTestID;
            
            %Generate uplink SRS resource element indices.
            symbolIndices = nrSRSIndices(carrier, srs, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            %Generate uplink SRS symbols.
            txSymbols = nrSRS(carrier, srs);

            % Create transmit resource grid.
            txGrid = nrResourceGrid(carrier, NumSRSPorts);

            % Create transmit grid RE indices.
            NumSubcarriers = size(txGrid, 1);
            NumOfdmSymbols = size(txGrid, 2);
            txSymbolIndices = sub2ind([NumSubcarriers, NumOfdmSymbols, NumSRSPorts],...
                symbolIndices(:, 1) + 1, symbolIndices(:, 2) + 1, symbolIndices(:, 3) + 1);

            % Write RE in the resource grid.
            txGrid(txSymbolIndices) = txSymbols;

            % Create receive resource grid.
            rxGrid = nrResourceGrid(carrier, NumRxPorts);

            % Create propagation channel matrix.
            H = complex(nan(NumRxPorts, NumSRSPorts));
            for Nr = 1:NumRxPorts
                for Nt = 1:NumSRSPorts
                    H(Nr, Nt) = exp(2i * pi * rand());
                    rxGrid(:, :, Nr) = rxGrid(:, :, Nr) + H(Nr, Nt) * txGrid(:, :, Nt);
                end
            end

            % Maximum time aligment that we expect in seconds.
            MaxTimeAligment = 16 / (2048 * 1000 * carrier.SubcarrierSpacing);

            % Select random time aligment.
            TimeAligment = (2 * rand() - 1) * MaxTimeAligment;

            % Create time aligment frequency shift.
            FreqResponse = exp(-2i * pi * (0:NumSubcarriers - 1).' * TimeAligment * 1000 * carrier.SubcarrierSpacing);

            % Apply frequency response in all the received grid.
            rxGrid = rxGrid .* repmat(FreqResponse, 1, NumOfdmSymbols, NumRxPorts);

            % Prepare receive symbols indices. Combine all transmit ports.
            symbolIndices(:, 3) = 0;
            symbolIndices = unique(symbolIndices, 'rows');
            NumRxRe = size(symbolIndices, 1);
            rxSymbolSubscripts = zeros(NumRxRe, 3);
            for Nr = 0:NumRxPorts-1
                % Combine all indices to same receive port.
                symbolIndices(:, 3) = Nr;
                % Write coordinates with the receive port.
                rxSymbolSubscripts(NumRxRe * Nr + (1:NumRxRe), :) = symbolIndices;
            end

            % Convert subscripts to indices.
            rxSymbolIndices = sub2ind([NumSubcarriers, NumOfdmSymbols, NumRxPorts],...
                rxSymbolSubscripts(:, 1) + 1, rxSymbolSubscripts(:, 2) + 1, rxSymbolSubscripts(:, 3) + 1);

            % Extract RE used for SRS from the resoyrce grid.
            rxSymbols = rxGrid(rxSymbolIndices);

            % Write the generated SRS sequence into a binary file.
            testCase.saveDataFile('_test_input', TestID,...
                @writeResourceGridEntryFile, rxSymbols, rxSymbolSubscripts);

            % Generate a 'slot_point' configuration string.
            slotPointConfig = cellarray2str({Numerology, NFrame,...
                floor(NSlot / carrier.SlotsPerSubframe),...
                rem(NSlot, carrier.SlotsPerSubframe)}, true);             

            hoppingConfigStr = 'srs_resource_configuration::group_or_sequence_hopping_enum::neither';

            periodicityConfig = 'nullopt';
            if srs.ResourceType == 'periodic'
                periodicityConfig = '{}';
            end

            NumSRSPortsStr = sprintf('srs_resource_configuration::one_two_four_enum(%d)', NumSRSPorts);
            NumSRSSymbolsStr = sprintf('srs_resource_configuration::one_two_four_enum(%d)', NumSRSSymbols);
            CombSizeStr = sprintf('srs_resource_configuration::comb_size_enum(%d)', KTC);

            portsConfig = num2cell(0:NumRxPorts-1);

            channelCell = {...
                {H(:)},...      % coefficients
                NumRxPorts,...  % nof_rx_ports
                NumSRSPorts,... % nof_tx_ports
                };

            tAlignStr = sprintf('%.9f', TimeAligment);

            srsResourceCell = {...
                NumSRSPortsStr,...    % nof_antenna_ports
                NumSRSSymbolsStr,...  % nof_symbols
                SymbolStart,...       % start_symbol
                CSRS,...              % configuration_index
                NSRSID,...            % sequence_id
                BSRS,...              % bandwidth_index
                CombSizeStr,...       % comb_size
                KBarTC,...            % comb_offset
                CyclicShift,...       % cyclic_shift
                NRRC,...              % freq_position
                FrequencyStart,...    % freq_shift
                BHop,...              % freq_hopping
                hoppingConfigStr,...  % hopping
                periodicityConfig,... % periodicity
                };

            configCell = {...
                slotPointConfig,... % slot
                srsResourceCell,... % resource
                portsConfig,...     % ports
                };

            resultCell = { ...
                channelCell,... % channel_matrix
                0,...           % noise_variance
                tAlignStr,...   % time_align
                };

            testContext = {...
                configCell,... % config
                resultCell,... % result
                };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(TestID,...
                testContext, true, '_test_input');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsSRSUnittest




