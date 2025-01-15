%srsPUSCHdmrsUnittest Unit tests for PUSCH DMRS processor functions.
%   This class implements unit tests for the PUSCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUSCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUSCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pusch_estimator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsPUSCHdmrsUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHdmrsUnittest Properties (TestParameter):
%
%   numerology              - Defines the subcarrier spacing (0, 1).
%   NumLayers               - Number of transmission layers (1, 2, 4, 8).
%   DMRSTypeAPosition       - Position of the first DMRS OFDM symbol (2, 3).
%   DMRSAdditionalPosition  - Maximum number of DMRS additional positions (0, 1, 2, 3).
%   DMRSLength              - Number of consecutive front-loaded DMRS OFDM symbols (1, 2).
%   DMRSConfigurationType   - DMRS configuration type (1, 2).
%   testLabel               - Test label ('dmrs_creation' or 'ch_estimation').
%
%   srsPUSCHdmrsUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUSCHdmrsUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

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

classdef srsPUSCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pusch_estimator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'

        %Valid number of RB that accept transform precoding.
        ValidNumPRB = [...
               1,   2,   3,   4,   5,   6,   8,   9,  10,  12,  15,  16,...
              18,  20,  24,  25,  27,  30,  32,  36,  40,  45,  48,  50,...
              54,  60,  64,  72,  75,  80,  81,  90,  96, 100, 108, 120,...
             125, 128, 135, 144, 150, 160, 162, 180, 192, 200, 216, 225,...
             240, 243, 250, 256, 270]
    end

    properties (Hidden)
        randomizeTestvector
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pusch_estimator' tests will be erased).
        outputPath = {['testPUSCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %Number of transmission layers (1, 2, 4).
        NumLayers = {1, 2, 4}

        %Position of the first DMRS OFDM symbol (2, 3).
        DMRSTypeAPosition = {2, 3}

        %Maximum number of DMRS additional positions (0, 1, 2, 3).
        DMRSAdditionalPosition = {0, 1, 2, 3}

        %Number of consecutive front-loaded DMRS OFDM symbols (1, 2).
        DMRSLength = {1, 2}

        %DMRS configuration type (1, 2).
        DMRSConfigurationType = {1, 2}

        %Test label ('dmrs_creation' or 'ch_estimation').
        %   'dmrs_creation' tests only check that the DM-RS pilots are generated correctly
        %   and placed in the correct location in the resource grid.
        %   'ch_estimation' also check that the channel is estimated correctly.
        testLabel = {'dmrs_creation', 'ch_estimation'}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.


            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/dmrs_pusch_estimator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'enum class test_label {dmrs_creation, ch_estimation};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  test_label                                              label;\n');
            fprintf(fileID, '  dmrs_pusch_estimator::configuration                     config;\n');
            fprintf(fileID, '  float                                                   est_noise_var;\n');
            fprintf(fileID, '  float                                                   est_rsrp;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> rx_symbols;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> ch_estimates;\n');
            fprintf(fileID, '};\n');
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, NumLayers, ...
                DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, ...
                DMRSConfigurationType, testLabel)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength,
        %   DMRSConfigurationType and testLabel. NCellID, NSlot and PRB are randomly generated.

            import srsTest.helpers.cellarray2str
            import srsLib.phy.upper.signal_processors.srsPUSCHdmrs
            import srsLib.phy.upper.signal_processors.srsChannelEstimator
            import srsLib.ran.utils.scs2cps
            import srsTest.helpers.approxbf16
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.RBallocationMask2string

            % Skip those invalid configuration cases.
            isDMRSLengthOK = (DMRSLength == 1 || DMRSAdditionalPosition < 2);
            isChEstimationOK = strcmp(testLabel, 'dmrs_creation') || (NumLayers == 1) ...
                || ((NumLayers == 2) && (DMRSConfigurationType == 1) && (DMRSLength == 1));
            if ~(isDMRSLengthOK && isChEstimationOK)
                return;
            end

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Limit the resource grid size.
            nSizeGrid = 275;

            % Use a unique NCellID, NSlot, scrambling ID and PRB allocation for each test.
            nCellID = testCase.randomizeTestvector(testID + 1) - 1;
            if numerology == 0
                nSlot = randi([0, 9]);
            else
                nSlot = randi([0, 19]);
            end
            NSCID = randi([0, 1]);

            % Select a random PRB allocation.
            NumPRB = testCase.ValidNumPRB(randi([1, numel(testCase.ValidNumPRB)]));
            PRBstart = randi([0, nSizeGrid - NumPRB]);
            PRBend = PRBstart + NumPRB - 1;

            % Current fixed parameter values (e.g., number of CDM groups without data).
            nStartGrid = 0;
            nFrame = 0;
            cyclicPrefix = 'normal';
            RNTI = 0;
            nStartBWP = 0;
            nSizeBWP = nSizeGrid;
            NIDNSCID = nCellID;
            nID = nCellID;
            NRSID = nCellID;
            modulation = '16QAM';
            mappingType = 'A';
            symbolAllocation = [1 13];
            PRBSet = PRBstart:PRBend;
            amplitude = sqrt(2);

            % Select randomly transform precoding if only one layer and 
            % configuration type 1.
            transformPrecoding = 0;
            if (NumLayers == 1) && (DMRSConfigurationType == 1)
                transformPrecoding = randi([0, 1]);
            end

            % Configure the carrier according to the test parameters.
            subcarrierSpacing = 15 * (2 .^ numerology);
            carrier = nrCarrierConfig( ...
                NCellID=nCellID, ...
                SubcarrierSpacing=subcarrierSpacing, ...
                NSizeGrid=nSizeGrid, ...
                NStartGrid=nStartGrid, ...
                NSlot=nSlot, ...
                NFrame=nFrame, ...
                CyclicPrefix=cyclicPrefix ...
                );

            % Configure the PUSCH DM-RS symbols according to the test parameters.
            DMRS = nrPUSCHDMRSConfig( ...
                DMRSConfigurationType=DMRSConfigurationType, ...
                DMRSTypeAPosition=DMRSTypeAPosition, ...
                DMRSAdditionalPosition=DMRSAdditionalPosition, ...
                DMRSLength=DMRSLength, ...
                NIDNSCID=NIDNSCID, ...
                NSCID=NSCID, ...
                NRSID=NRSID ...
                );

            % Configure the PUSCH according to the test parameters.
            pusch = nrPUSCHConfig( ...
                DMRS=DMRS, ...
                NStartBWP=nStartBWP, ...
                NSizeBWP=nSizeBWP, ...
                NID=nID, ...
                RNTI=RNTI, ...
                Modulation=modulation, ...
                NumLayers=NumLayers, ...
                MappingType=mappingType, ...
                SymbolAllocation=symbolAllocation, ...
                PRBSet=PRBSet, ...
                TransformPrecoding=transformPrecoding ...
                );

            % Call the PUSCH DM-RS symbol processor MATLAB functions.
            [DMRSsymbols, symbolIndices] = srsPUSCHdmrs(carrier, pusch);

            % If 'dmrs-creation' test, write each complex symbol and their
            % associated indices into a binary file, and an empty channel
            % coefficients file.
            if strcmp(testLabel, 'dmrs_creation')
                if NumLayers == 4
                    % In creation tests, we assume layer n is received by port n only. Therefore we need to add
                    % zeros in the REs where DM-RS from other layers would be. Note that this is not needed when
                    % NumLayers == 2 since the first two layers share DM-RS resources.
                    DMRSsymbols = [DMRSsymbols zeros(size(DMRSsymbols))];
                    symbolIndices = [symbolIndices; [symbolIndices(:, 1:2) symbolIndices([(end/2 + 1):end, 1:end/2], 3)]];
                end
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, DMRSsymbols * amplitude, symbolIndices);
                testCase.saveDataFile('_ch_estimates', testID, ...
                    @writeResourceGridEntryFile, [], uint32.empty(0,3));
                estRSRP = 0;
                estNoiseVar = 0;
                PUSCHports = 0:(NumLayers-1);
            else
                PUSCHports = 0;

                channel = createChannel(carrier, NumLayers);

                sizeRG = [nSizeGrid * 12, 14];
                symbolIndicesLinear = sub2ind([sizeRG, NumLayers], symbolIndices(:, 1) + 1, ...
                    symbolIndices(:, 2) + 1, symbolIndices(:, 3) + 1);
                symbolIndicesLinear = reshape(symbolIndicesLinear, [], NumLayers);
                receivedRG = channel(:, :, 1);
                receivedRG(symbolIndicesLinear(:, 1)) = receivedRG(symbolIndicesLinear(:, 1)) ...
                    .* DMRSsymbols(:, 1) * amplitude;
                for iLayer = 2:NumLayers
                    receivedRG(symbolIndicesLinear(:, 1)) = receivedRG(symbolIndicesLinear(:, 1)) ...
                        + channel(symbolIndicesLinear(:, iLayer)) .* DMRSsymbols(:, iLayer) * amplitude;
                end
                noiseVar = 0.1; % 10 dB
                noiseRG = (randn(sizeRG) + 1j * randn(sizeRG)) * sqrt(noiseVar / 2);
                receivedRG = receivedRG + noiseRG;

                hop = configureHop();
                % Empty second hop.
                hop2.DMRSsymbols = [];
                nOFDMSymbols = sum(hop.DMRSsymbols);
                pilots = reshape(DMRSsymbols, [], nOFDMSymbols, NumLayers);
                cfg.scs = subcarrierSpacing * 1000;
                cfg.CyclicPrefixDurations = scs2cps(subcarrierSpacing);
                receivedRG = approxbf16(receivedRG);
                [estChannel, estNoiseVar, estRSRP] = srsChannelEstimator(receivedRG, ...
                    pilots, amplitude, hop, hop2, cfg);

                % Write simulation data.
                symbolIndicesMask = (symbolIndices(:, 3) == 0);
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, receivedRG(symbolIndicesLinear(symbolIndicesMask)), symbolIndices(symbolIndicesMask, :));
                [subcarriers, syms, vals] = find(estChannel);
                testCase.saveDataFile('_ch_estimates', testID, ...
                    @writeResourceGridEntryFile, approxbf16(vals), [subcarriers - 1, mod(syms - 1, 14), floor((syms - 1) / 14)]);
            end

            % Generate a 'slot_point' configuration string.
            slotPointConfig = cellarray2str({numerology, nFrame, ...
                floor(nSlot / carrier.SlotsPerSubframe), ...
                rem(nSlot, carrier.SlotsPerSubframe)}, true);

            % DMRS type
            DmrsTypeStr = ['dmrs_type::TYPE', num2str(DMRSConfigurationType)];

            % Cyclic Prefix.
            cyclicPrefixStr = 'cyclic_prefix::NORMAL';

            % generate a symbol allocation mask string
            symbolAllocationMask = symbolAllocationMask2string(symbolIndices);

            % generate a RB allocation mask string
            rbAllocationMask = RBallocationMask2string(PRBstart, PRBend);

            if transformPrecoding == 0
                SequenceConfig = {...
                    DmrsTypeStr, ...         % type
                    NumLayers, ...           % nof_tx_layers
                    pusch.DMRS.NIDNSCID, ... % scrambling_id
                    pusch.DMRS.NSCID, ...    % n_scid
                    }; 
                SequenceDescr = ['dmrs_pusch_estimator::pseudo_random_sequence_configuration('...
                    cellarray2str(SequenceConfig, true)...
                    ')'];
            else
                SequenceConfig = {...
                    pusch.DMRS.NRSID, ... % n_rs_id
                    };
                SequenceDescr = ['dmrs_pusch_estimator::low_papr_sequence_configuration('...
                    cellarray2str(SequenceConfig, true)...
                    ')'];
            end


            % Prepare DMRS configuration cell
            dmrsConfigCell = { ...
                slotPointConfig, ...             % slot
                SequenceDescr, ...               % sequence_config
                amplitude, ...                   % scaling
                cyclicPrefixStr, ...             % c_prefix
                symbolAllocationMask, ...        % symbol_mask
                rbAllocationMask, ...            % rb_mask
                pusch.SymbolAllocation(1), ...   % first_symbol
                pusch.SymbolAllocation(2), ...   % nof_symbols
                {PUSCHports}, ...                % rx_ports
                };

            testCell = {['test_label::' testLabel], dmrsConfigCell, estNoiseVar, estRSRP};

            % generate the test case entry
            testCaseString = testCase.testCaseToString(testID, testCell, ...
                false, '_test_output', '_ch_estimates');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

            %   Nested functions
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            function hop_ = configureHop
                ofdmSymIndices = unique(symbolIndices(:, 2) + 1);
                hop_.DMRSsymbols = false(14, 1);
                hop_.DMRSsymbols(ofdmSymIndices) = true;
                hop_.DMRSREmask = false(12, 1);
                if DMRSConfigurationType == 1
                    hop_.DMRSREmask(1:2:end) = true;
                else
                    hop_.DMRSREmask([1, 2, 7, 8]) = true;
                end
                hop_.PRBstart = PRBstart;
                hop_.nPRBs = length(PRBSet);
                hop_.maskPRBs = false(nSizeGrid, 1);
                hop_.maskPRBs(PRBSet + 1) = true;
                hop_.startSymbol = symbolAllocation(1);
                hop_.nAllocatedSymbols = symbolAllocation(2);
                hop_.CHsymbols = false(14, 1);
                hop_.CHsymbols((1:symbolAllocation(2)) + symbolAllocation(1)) = true;
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHdmrsUnittest

function channel = createChannel(carrier, nLayers)
%Generates the frequency-response of single-tap channel that is consistent with
%   the simulation setup.
    nSubcarriers = carrier.NSizeGrid * 12;
    nOFDMSymbols = 14;
    % Compute maximum delay (1/4 CP length) in number of samples.
    maxDelay = floor(0.7 * 0.25 * nSubcarriers);

    channel = complex(nan(nSubcarriers, nOFDMSymbols, nLayers), nan(nSubcarriers, nOFDMSymbols, nLayers));
    for iLayer = 1:nLayers
        % Random delay and random gain.
        delay = randi(maxDelay);
        gain = randn(1, 2) * [1; 1j] / sqrt(2 * nLayers);
        channel(:, :, iLayer) = repmat(gain * exp(-2j * pi / nSubcarriers * delay ...
            * (-nSubcarriers/2:nSubcarriers/2-1).'), 1, nOFDMSymbols);
    end
end
