%srsPUSCHDemodulatorUnittest Unit tests for PUSCH symbol demodulator functions.
%   This class implements unit tests for the PUSCH symbol demodulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUSCHDemodulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUSCHDemodulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_demodulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors/pusch').
%
%   srsPUSCHDemodulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHDemodulatorUnittest Properties (TestParameter):
%
%   DMRSConfigurationType - PUSCH DM-RS configuration type.
%   Modulation            - PUSCH Modulation scheme.
%   NumRxPorts            - Number of receive antenna ports for PUSCH.
%
%   srsPUSCHDemodulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUSCHDemodulatorUnittest Methods (TestTags = {'testmex'}):
%
%   mexTest  - Tests the MEX-based implementation of the PUSCH demodulator.
%
%   srsPUSCHDemodulatorUnittest Methods (Access = protected):
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

classdef srsPUSCHDemodulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_demodulator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pusch'

        %Valid number of RB that accept transform precoding.
        ValidNumPRB = [...
              1,   2,   3,   4,   5,   6,   8,   9,  10,  12,  15,  16, ...
             18,  20,  24,  25];
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pusch_dedemodulator' tests will be erased).
        outputPath = {['testPUSCHDemodulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %DM-RS Configuration types {1, 2}.
        DMRSConfigurationType = {1, 2};

        %Modulation {pi/2-BPSK, QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};

        %Channel dimensions.
        %   The first entry is the number of receive antenna ports, the
        %   second entry is the number of transmit layers.
        ChannelSize = {[1, 1], [2, 1], [2, 2], [4, 1], [4, 2]}
    end

    properties (Hidden)
        % Carrier.
        carrier
        % Physical Uplink Shared Channel.
        pusch
        % PUSCH transmission resource-element indices.
        puschTxIndices
        % PUSCH reception resource-element indices (subscript form). They
        % differ from the transmission indices in the receive port
        % dimension.
        puschRxIndices
        % Indices of PUSCH DM-RS in the frequency grid.
        puschDmrsIndices
        % Transmission resource grid.
        txGrid
        % Channel estimates.
        ce
        % Receive antenna port indices the PUSCH transmission is mapped to.
        rxPorts
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pusch/pusch_demodulator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_tensor.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'enum class ch_dims : unsigned { subcarrier = 0, symbol = 1, rx_port = 2, tx_layer = 3, nof_dims = 4 };\n\n');
            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  float noise_var;\n');
            fprintf(fileID, '  float sinr_dB;\n');
            fprintf(fileID, '  pusch_demodulator::configuration                        config;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                                            context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t>              symbols;\n');
            fprintf(fileID, '  file_tensor<static_cast<unsigned>(ch_dims::nof_dims), cf_t, ch_dims> estimates;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                                 scrambling_seq;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                                    codeword;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Access = private)
        function [reIndices, xIndices, yIndices] = getPlaceholders(~, Modulation, NumLayers, NumRe, ProbPlaceholder)
        %getPlaceholders Generates a list of the RE containing repetition
        %   placeholders and their respective soft bits indices for x and y
        %   placeholders. All indices are 0based.

            % Deduce modulation order.
            Qm = 1;
            switch Modulation
                case 'QPSK'
                    Qm = 2;
                case '16QAM'
                    Qm = 4;
                case '64QAM'
                    Qm = 6;
                case '256QAM'
                    Qm = 8;
            end

            % Early return if the modulation order is not suffcient or the
            % probability of placeholder is zero.
            if (Qm < 2) || (ProbPlaceholder == 0)
                reIndices = {};
                xIndices = [];
                yIndices = [];
                return;
            end

            % Select REs that contain placeholders.
            reIndices = 1:floor(1 / ProbPlaceholder):(NumRe - 1);

            nIndices = numel(reIndices) * NumLayers;
            xIndices = nan(nIndices * (Qm - 2), 1);
            yIndices = nan(nIndices, 1);

            % Generate placeholder bit indices.
            i = 0;
            for reIndex = reIndices
                for layer = 0:NumLayers-1
                    offset = i * (Qm - 2);
                    xIndices(offset + (1:Qm-2)) = (reIndex * NumLayers + layer) * Qm + transpose(2:Qm - 1);
                    i = i + 1;
                    yIndices(i) = (reIndex * NumLayers + layer) * Qm + 1;
                end
            end

            % If the number of indices is scalar, then convert to cell.
            if length(reIndices) < 2
                reIndices = {reIndices};
            end
        end % of function getPlaceholders(...
    end % of methods (Access = private)

    methods (Access = private)
        function setupsimulation(obj, DMRSConfigurationType, Modulation, nofRxPorts, NumLayers, TransformPrecoding)
        % Sets secondary simulation variables.

            % Select a random number of PRB.
            numPRB = obj.ValidNumPRB(randi([1, length(obj.ValidNumPRB)]));

            % Configure carrier.
            nCellID = randi([0, 1007]);
            nSizeGrid = numPRB;
            obj.carrier = nrCarrierConfig(NCellID=nCellID, NSizeGrid=nSizeGrid);

            % Set symbol allocation.
            startSymbol = randi([0 2]);
            nofSymbols = randi([7 (14 - startSymbol)]);
            symbolAllocation = [startSymbol, nofSymbols];

            % Prepare PRB set.
            PRBSet = 0:(numPRB-1);
            nID = obj.carrier.NCellID;

            % Configure PUSCH.
            RNTI = randi([1, 65535]);
            obj.pusch = nrPUSCHConfig( ...
                NumLayers=NumLayers, ...
                Modulation=Modulation, ...
                PRBSet=PRBSet, ...
                SymbolAllocation=symbolAllocation, ...
                NID=nID, ...
                RNTI=RNTI ...
                );
            obj.pusch.DMRS.DMRSConfigurationType = DMRSConfigurationType;
            obj.pusch.DMRS.DMRSAdditionalPosition = randi([0, 3]);
            obj.pusch.DMRS.NumCDMGroupsWithoutData = randi([1, obj.pusch.DMRS.DMRSConfigurationType + 1]);
            obj.pusch.TransformPrecoding = TransformPrecoding;

            % Generate PUSCH data grid indices.
            [obj.puschTxIndices, puschInfo] = nrPUSCHIndices(obj.carrier, obj.pusch);

            % Generate PUSCH indices for a single Rx port in subscript
            % form.
            pusch2 = obj.pusch;
            pusch2.NumLayers = 1;
            puschPortIndices = nrPUSCHIndices(obj.carrier, pusch2, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Number of RE per port.
            nofREPort = size(puschPortIndices, 1);

            % Set the receive port indices.
            obj.rxPorts = 0 : (nofRxPorts - 1);

            % Generate the Rx resource grid indices for all receive ports.
            obj.puschRxIndices = zeros(nofREPort * nofRxPorts, 3);
            for iPort = 0 : (nofRxPorts - 1)
                % Copy the RE and OFDM symbol index coordinates.
                obj.puschRxIndices(((nofREPort * iPort) + 1) : (nofREPort * (iPort + 1)), :) = ...
                    puschPortIndices;

                % Generate the receive port index coordinates.
                obj.puschRxIndices(((nofREPort * iPort) + 1) : (nofREPort * (iPort + 1)), 3) = ...
                 obj.rxPorts(iPort + 1) * ones(nofREPort, 1);
            end

            % Generate DM-RS for PUSCH grid indices.
            obj.puschDmrsIndices = nrPUSCHDMRSIndices(obj.carrier, obj.pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Generate random encoded and rate-matched codeword.
            cw = randi([0, 1], puschInfo.G, 1);

            % Modulate PUSCH.
            txSymbols = nrPUSCH(obj.carrier, obj.pusch, cw);

            % Generate grid.
            obj.txGrid = nrResourceGrid(obj.carrier, NumLayers);

            % Put PUSCH symbols in grid.
            obj.txGrid(obj.puschTxIndices) = txSymbols;

            % OFDM information.
            ofdmInfo = nrOFDMInfo(obj.carrier.NSizeGrid, obj.carrier.SubcarrierSpacing);

            % Prepare channel.
            tdl = nrTDLChannel;
            tdl.DelayProfile = 'TDL-C';
            tdl.DelaySpread = 100e-9;
            tdl.MaximumDopplerShift = 300;
            tdl.SampleRate = ofdmInfo.SampleRate;
            tdl.NumTransmitAntennas = NumLayers;
            tdl.NumReceiveAntennas = nofRxPorts;

            T = tdl.SampleRate * 1e-3;
            tdlInfo = info(tdl);
            Nt = tdlInfo.NumTransmitAntennas;
            in = complex(randn(T,Nt),randn(T,Nt));

            [~,pathGains] = tdl(in);
            pathFilters = getPathFilters(tdl);

            % Generate channel estimates.
            obj.ce = nrPerfectChannelEstimate(obj.carrier,pathGains,pathFilters);

        end % of function setupsimulation(obj, DMRSConfigurationType, Modulation, nofRxPorts)
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, DMRSConfigurationType, Modulation, ChannelSize)
        %testvectorGenerationCases Generates a test vector for the given
        %   DMRSConfigurationType, Modulation, and ChannelSize.

            import srsLib.phy.upper.channel_modulation.srsDemodulator
            import srsLib.phy.upper.equalization.srsChannelEqualizer
            import srsLib.phy.helpers.srsModulationFromMatlab
            import srsTest.helpers.approxbf16
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeComplexFloatFile
            import srsTest.helpers.cellarray2str

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = obj.generateTestID;

            NumRxPorts = ChannelSize(1);
            NumLayers = ChannelSize(2);

            % Select randomly the use of transform precoding.
            TransformPrecoding = 0;
            if NumLayers == 1
                TransformPrecoding = randi([0,1]);
            end

            % Configure the test.
            setupsimulation(obj, DMRSConfigurationType, Modulation, NumRxPorts, NumLayers, TransformPrecoding);

            % Estimate average energy per resource element (EPRE).
            epredB = 10 * log10(mean(abs(obj.ce) .^ 2, 'all'));

            % Select an SNR between 10 and 30dB.
            snrdB = round(rand() * 20 + 10);

            % Select noise variance from the EPRE and SNR.
            noiseVar = 10 ^ ((epredB - snrdB) / 10);

            % Generate receive grid.
            rxGrid = nrResourceGrid(obj.carrier, NumRxPorts);
            for Nr = 1:NumRxPorts
                for Nt = 1:NumLayers
                    rxGrid(:, :, Nr) = rxGrid(:, :, Nr) + obj.ce(:, :, Nr, Nt) .* obj.txGrid(:, :, Nt);
                end
            end

            % Apply AWGN.
            noise = (randn(size(rxGrid)) + 1j * randn(size(rxGrid))) * sqrt(noiseVar / 2);
            rxGrid  = rxGrid + noise;

            % Extract PUSCH Rx symbols.
            rxPortIndices = obj.puschTxIndices(:, 1);
            rxSymbols = complex(zeros(size(rxPortIndices, 1), NumRxPorts));
            for iPort = 1:NumRxPorts
                iRxGrid = rxGrid(:, :, iPort);
                rxSymbols(:, iPort) = iRxGrid(rxPortIndices);
            end

            % Extract CE for PUSCH.
            cePusch = complex(zeros(size(rxPortIndices, 1), NumRxPorts, NumLayers));
            for Nr = 1:NumRxPorts
                for Nt = 1:NumLayers
                    iCePusch = obj.ce(:, :, Nr, Nt);
                    cePusch(:, Nr, Nt) = iCePusch(rxPortIndices);
                end
            end

            % Equalize.
            [eqSymbols, eqNoise] = srsChannelEqualizer(approxbf16(rxSymbols), approxbf16(cePusch), 'ZF', noiseVar, 1.0);

            % Revert transform precoding if it is present.
            if obj.pusch.TransformPrecoding
                numPRB = length(obj.pusch.PRBSet);
                eqSymbols = nrTransformDeprecode(eqSymbols, numPRB);
                eqNoise = processTransformPrecodingNoiseVariance(eqNoise, NumLayers, numPRB);
            end

            % Layer demapping.
            eqSymbols = nrLayerDemap(eqSymbols);
            eqSymbols = eqSymbols{1};
            eqNoise = nrLayerDemap(eqNoise);
            eqNoise = eqNoise{1};

            % Estimate SINR from the equalizer noise esimation.
            estimatedSinrdB = -10 * log10(mean(eqNoise));

            % Soft demapping.
            softBits = srsDemodulator(eqSymbols, obj.pusch.Modulation, eqNoise);

            % Reverse Scrambling.
            schSoftBits = nrPUSCHDescramble(softBits, obj.pusch.NID, obj.pusch.RNTI);

            % Generate scrambling sequence.
            scramblingSeq = nrPUSCHScramble(zeros(size(schSoftBits)), obj.pusch.NID, obj.pusch.RNTI);

            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(obj.puschDmrsIndices);

            % Write each complex symbol and their associated indices into a binary file.
            obj.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxSymbols(:), obj.puschRxIndices);

            % Write channel estimates to a binary file.
            obj.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, obj.ce(:));

            % Write soft bits before descrambling to a binary file.
            obj.saveDataFile('_test_output_scrambling_seq', testID, @writeUint8File, scramblingSeq);

            % Write soft bits to a binary file.
            obj.saveDataFile('_test_output', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = cellarray2str(num2cell(obj.rxPorts), true);

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = zeros(obj.carrier.NSizeGrid, 1);
            rbAllocationMask(obj.pusch.PRBSet + 1) = 1;
            rbAllocationMask = {rbAllocationMask};

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', obj.pusch.DMRS.DMRSConfigurationType);

            % Generate a QAM modulation string.
            modString = srsModulationFromMatlab(obj.pusch.Modulation, 'full');

            puschCellConfig = {...
                obj.pusch.RNTI, ...                         % rnti
                rbAllocationMask, ...                       % rb_mask
                modString, ...                              % modulation
                obj.pusch.SymbolAllocation(1), ...          % start_symbol_index
                obj.pusch.SymbolAllocation(2), ...          % nof_symbols
                dmrsSymbolMask, ...                         % dmrs_symb_pos
                dmrsTypeString, ...                         % dmrs_config_type
                obj.pusch.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                obj.pusch.NID, ...                          % n_id
                obj.pusch.NumLayers, ...                    % nof_tx_layers
                obj.pusch.TransformPrecoding == 1, ...      % enable_transform_precoding
                portsString, ...                            % rx_ports
                };

            testCaseContext = { ...
                noiseVar, ...        % noise_var
                estimatedSinrdB, ... % sinr_dB
                puschCellConfig, ... % config
                };

            % Channel estimate dimensions.
            estimatesDims = {...
                size(obj.ce, 1), ... % subcarrier
                size(obj.ce, 2), ... % symbol
                size(obj.ce, 3), ... % receive port
                size(obj.ce, 4), ... % transmit layer
                };

            testCaseString = obj.testCaseToString(testID, ...
                testCaseContext, true, '_test_input_symbols', ...
                {'_test_input_estimates', estimatesDims}, ...
                '_test_output_scrambling_seq', '_test_output');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, DMRSConfigurationType, Modulation, ChannelSize)
        %mexTest  Tests the mex wrapper of the srsRAN PUSCH demodulator.
        %   mexTest(OBJ, DMRSCONFIGURATIONTYPE, MODULATION,
        %   NUMRXPORTS) runs a short simulation with a
        %   ULSCH transmission using DM-RS type DMRSCONFIGURATIONTYPE,
        %   symbol modulation MODULATION and the channel geometry CHANNELSIZE.
        %   Channel estimation on the PUSCH transmission is done in MATLAB and PUSCH
        %   equalization and demodulation is then performed using the mex wrapper of the
        %   srsRAN C++ component. The test is considered as passed if the
        %   recovered soft bits are coinciding with those originally transmitted.

            import srsMEX.phy.srsPUSCHDemodulator
            import srsLib.phy.upper.channel_modulation.srsDemodulator
            import srsLib.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.approxbf16

            NumRxPorts = ChannelSize(1);
            NumLayers = ChannelSize(2);

            % Select randomly the use of transform precoding.
            TransformPrecoding = 0;
            if NumLayers == 1
                TransformPrecoding = randi([0,1]);
            end

            % Configure the test.
            setupsimulation(obj, DMRSConfigurationType, Modulation, NumRxPorts, NumLayers, TransformPrecoding);

            % Generate receive grid.
            rxGrid = nrResourceGrid(obj.carrier, NumRxPorts);
            for Nr = 1:NumRxPorts
                for Nt = 1:NumLayers
                    rxGrid(:, :, Nr) = rxGrid(:, :, Nr) + obj.ce(:, :, Nr, Nt) .* obj.txGrid(:, :, Nt);
                end
            end

            % Select noise variance between 0.0001 and 0.01.
            noiseVar = rand() * 0.0099 + 0.0001;

            % Apply AWGN.
            noise = (randn(size(rxGrid)) + 1j * randn(size(rxGrid))) * sqrt(noiseVar / 2);
            rxGrid = rxGrid + noise;

            % Extract PUSCH symbols.
            rxPortIndices = obj.puschTxIndices(:, 1);
            rxSymbols = complex(zeros(size(rxPortIndices, 1), NumRxPorts));

            for iPort = 1:NumRxPorts
                iRxGrid = rxGrid(:, :, iPort);
                rxSymbols(:, iPort) = iRxGrid(rxPortIndices);
            end

            % Extract CE for PUSCH.
            cePusch = complex(zeros(size(rxPortIndices, 1), NumRxPorts, NumLayers));
            for Nr = 1:NumRxPorts
                for Nt = 1:NumLayers
                    iCePusch = obj.ce(:, :, Nr, Nt);
                    cePusch(:, Nr, Nt) = iCePusch(rxPortIndices);
                end
            end

            % Equalize.
            [eqSymbols, eqNoise] = srsChannelEqualizer(approxbf16(rxSymbols), approxbf16(cePusch), 'ZF', noiseVar, 1.0);

            % Revert transform precoding if it is present.
            if obj.pusch.TransformPrecoding
                numPRB = length(obj.pusch.PRBSet);
                eqSymbols = nrTransformDeprecode(eqSymbols, numPRB);
                eqNoise = processTransformPrecodingNoiseVariance(eqNoise, NumLayers, numPRB);
            end

            % Initialize the SRS PUSCH demodulator mex.
            PUSCHDemodulator = srsPUSCHDemodulator;

            gridSize = size(rxGrid);
            singlePortPUSCH = (obj.puschRxIndices(:, 3) == obj.puschRxIndices(1, 3));
            puschIx = sub2ind(gridSize(1:2), obj.puschRxIndices(singlePortPUSCH, 1) + 1, obj.puschRxIndices(singlePortPUSCH, 2) + 1);
            singlePortDMRS = (obj.puschDmrsIndices(:, 3) == obj.puschDmrsIndices(1, 3));
            dmrsIx = sub2ind(gridSize(1:2), obj.puschDmrsIndices(singlePortDMRS, 1) + 1, obj.puschDmrsIndices(singlePortDMRS, 2) + 1);

            % Run the PUSCH demodulator.
            schSoftBits = PUSCHDemodulator(rxGrid, obj.ce, noiseVar, obj.pusch, puschIx, ...
                dmrsIx, obj.rxPorts);

            % Verify the correct demodulation (expected, since the SNR is very high).
            % i) Layer demapping.
            eqSymbols = nrLayerDemap(eqSymbols);
            eqSymbols = eqSymbols{1};
            eqNoise = nrLayerDemap(eqNoise);
            eqNoise = eqNoise{1};
            % ii) Soft demapping.
            softBits = srsDemodulator(eqSymbols, obj.pusch.Modulation, eqNoise);
            % iii) Reverse Scrambling. Attention: placeholderBitIndices are 0based.
            schSoftBitsMatlab = nrPUSCHDescramble(softBits, obj.pusch.NID, obj.pusch.RNTI);
            % iv) Compare srsRAN and MATLAB results.
            obj.assertEqual(schSoftBits, int8(schSoftBitsMatlab), 'Demodulation errors.', AbsTol = int8(1));
        end % of function mextest
    end % of methods (Test, TestTags = {'testmex'})
end % of classdef srsPUSCHDemodulatorUnittest

%Processes the resultant noise variance from the equalizer after appliying
%   transform precodding.
function eqNoise = processTransformPrecodingNoiseVariance(eqNoise, numLayers, numPRB)
    numSubC = 12 * numPRB;
    numSymbols = length(eqNoise) / numSubC;
    eqNoise = reshape(eqNoise, numSubC, numLayers * numSymbols);
    eqNoise = ones(size(eqNoise)) .* mean(eqNoise);
    eqNoise = reshape(eqNoise, numSubC * numSymbols, numLayers);
end % of processTransformPrecodingNoiseVariance