%srsChEstimatorUnittest Unit tests for the port channel estimator.
%   This class implements unit tests for the port channel estimator functions using
%   the matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsChEstimatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsChEstimatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'port_channel_estimator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsChEstimatorUnittest Properties (ClassSetupParameter):
%
%   outputPath  - Path to the folder where the test results are stored.
%
%   srsChEstimatorUnittest Properties (TestParameter):
%
%   configuration     - Description of the allocated REs and DM-RS pattern.
%   SubcarrierSpacing - Subcarrier spacing in kHz.
%   FrequencyHopping  - Frequency hopping type.
%   CarrierOffset     - Carrier frequency offset, as a fraction of the subcarrier spacing.
%
%   srsChEstimatorUnittest Methods:
%
%   characterize  - Draws the empircical MSE performance curve of the estimator.
%
%   srsChEstimatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsChEstimatorUnittest Methods (TestTags = {'testmex'}):
%
%   compareMex - Compares mex results with those from the reference estimator.
%
%   srsChEstimatorUnittest Methods (Access = protected):
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

classdef srsChEstimatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'port_channel_estimator'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/signal_processors'
    end % of properties (Constant)

    properties (Hidden, Constant)
        % Number of resource elements in a RB and OFDM symbols in a slot.
        NRE = 12
        nSymbolsSlot = 14
    end % of properties (Hidden, Constant)

    properties (Hidden, SetAccess=private)
        % Fix BWP size and start as well as the frame number, since they
        % are irrelevant for the test.
        NSizeBWP = 51
        NStartBWP = 1
        NSizeGrid = 52 % srsChEstimatorUnittest.NSizeBWP + srsChEstimatorUnittest.NStartBWP
    end % of properties (Hidden, SetAccess=private)

    properties (ClassSetupParameter)
        %Path to results folder (old 'port_channel_estimator' tests will be erased).
        outputPath = {['testChEstimator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Configuration.
        %   A configuration structure array with fields:
        %   nPRBs            - Number of allocated PRBs (0...51)
        %   symbolAllocation - A two-element array denoting the first allocated OFDM symbol (0...13)
        %                      and the number of allocated OFDM symbols (1...14).
        %   dmrsOffset       - Number of non-DM-RS REs at the beginning of the RB (0, 1).
        %   dmrsStrideSCS    - DM-RS frequency domain stride (1, 2, 3), that is the distance
        %                      between two consecutive DM-RS REs (distance of 1 being back-to-back).
        %   dmrsStrideTime   - Stride between OFDM symbols containing DM-RS (1, 2, 4, 6, 20).
        %                      Use 20 for a single DM-RS symbol.
        %   betaDMRS         - The gain of the DM-RS pilots with respect to the data
        %                      symbols in dB (0, 3).
        configuration = {...
            struct(...        % #1: PUSCH DM-RS configuration Type 1 (inspired to).
               'nPRBs', 3, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 2, ...
               'dmrsStrideTime', 4, ...
               'betaDMRS', -3 ...
               ),...
            struct(...        % #2: PUSCH DM-RS configuration Type 1 (inspired to).
               'nPRBs', 20, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 2, ...
               'dmrsStrideTime', 4, ...
               'betaDMRS', -3 ...
               ), ...
            struct(...        % #3: PUSCH DM-RS configuration Type 1 (inspired to).
               'nPRBs', 51, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 2, ...
               'dmrsStrideTime', 4, ...
               'betaDMRS', -3 ...
               ), ...
            struct(...        % #4: PUCCH Format 1 (inspired to).
               'nPRBs', 1, ...
               'symbolAllocation', [8, 4], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 1, ...
               'dmrsStrideTime', 2, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % #5: PUCCH Format 1 (inspired to).
               'nPRBs', 1, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 1, ...
               'dmrsStrideTime', 2, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % #6: PUCCH Format 2 (inspired to).
               'nPRBs', 1, ...
               'symbolAllocation', [0, 2], ...
               'dmrsOffset', 1, ...
               'dmrsStrideSCS', 3, ...
               'dmrsStrideTime', 1, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % #7: PUCCH Format 2 (inspired to).
               'nPRBs', 6, ...
               'symbolAllocation', [5, 1], ...
               'dmrsOffset', 1, ...
               'dmrsStrideSCS', 3, ...
               'dmrsStrideTime', 1, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % #8: PUCCH Format 2 (inspired to).
               'nPRBs', 16, ...
               'symbolAllocation', [5, 2], ...
               'dmrsOffset', 1, ...
               'dmrsStrideSCS', 3, ...
               'dmrsStrideTime', 1, ...
               'betaDMRS', 0 ...
               ), ...
            }

        %Subcarrier spacing in kHz.
        SubcarrierSpacing = {15, 30}

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'}

        %Carrier frequency offset, as a fraction of the subcarrier spacing.
        CarrierOffset = {0, 0.007, -0.013, 0.027}
    end % of properties (TestParameter)

    properties (Hidden)
        %OFDM symbol in which the second hop starts (if any).
        secondHop
        %Mask of OFDM symbols carrying DM-RS.
        DMRSsymbols
        %Mask of REs carrying DM-RS (relative to one PRB and one OFDM symbol).
        DMRSREmask
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/port_channel_estimator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');

        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  port_channel_estimator::configuration                   cfg;\n');
            fprintf(fileID, '  unsigned                                                grid_size_prbs = 0;\n');
            fprintf(fileID, '  float                                                   rsrp           = 0;\n');
            fprintf(fileID, '  float                                                   epre           = 0;\n');
            fprintf(fileID, '  float                                                   snr_true       = 0;\n');
            fprintf(fileID, '  float                                                   snr_est        = 0;\n');
            fprintf(fileID, '  float                                                   noise_var_est  = 0;\n');
            fprintf(fileID, '  float                                                   ta_us          = 0;\n');
            fprintf(fileID, '  float                                                   cfo_true_Hz    = 0;\n');
            fprintf(fileID, '  optional<float>                                         cfo_est_Hz     = 0;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '  file_vector<cf_t>                                       pilots;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> estimates;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, configuration, SubcarrierSpacing, ...
            FrequencyHopping, CarrierOffset)
        %testvectorGenerationCases - Generates a test vector according to the provided
        %   CONFIGURATION, SUBCARRIERSPACING, FREQUENCYHOPPING type and CARRIEROFFSET.

            import srsLib.phy.upper.signal_processors.srsChannelEstimator
            import srsLib.ran.utils.scs2cps
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeComplexFloatFile

            obj.assumeFalse(((configuration.nPRBs == obj.NSizeBWP) || (configuration.symbolAllocation(2) == 1)) ...
                && strcmp(FrequencyHopping, 'intraSlot'), ...
                'Cannot do frequency hopping if the entire BWP is allocated or if using a single OFDM symbol.');

            assert((sum(configuration.symbolAllocation) <= obj.nSymbolsSlot), ...
                'srsran_matlab:srsChEstimatorUnittest', 'Time allocation exceeds slot length.');

            % Generate a unique test ID.
            testID = obj.generateTestID;

            % Configure each hop.
            [hop1, hop2] = obj.configureHops(configuration, FrequencyHopping);

            % Build DM-RS-like pilots.
            nDMRSsymbols = sum(obj.DMRSsymbols);
            nPilots = configuration.nPRBs * sum(obj.DMRSREmask) * nDMRSsymbols;
            pilots = (2 * randi([0 1], nPilots, 2) - 1) * [1; 1j] / sqrt(2);
            pilots = reshape(pilots, [], nDMRSsymbols);

            betaDMRS = 10^(-configuration.betaDMRS / 20);

            % Place pilots on the resource grid.
            transmittedRG = obj.transmitPilots(pilots, betaDMRS, hop1, hop2);

            % For now, consider a single-tap channel (max delay is 1/4 of
            % the cyclic prefix length).
            fftSize =  obj.NSizeGrid * obj.NRE;
            channelDelay = randi([0, floor(fftSize * 0.07 * 0.25)]);
            channelCoef = exp(2j * pi * rand);
            channelTF = fft([zeros(channelDelay, 1); channelCoef; zeros(5, 1)], fftSize);
            channelTF = fftshift(channelTF);
            % We assume the channel constant over the entire slot...
            channelRG = repmat(channelTF, 1, obj.nSymbolsSlot);
            % ... but for CFO.
            cfo = CarrierOffset; % Fraction of the SCS.
            CPDurations = scs2cps(SubcarrierSpacing);

            if cfo ~= 0
                cfoVal = CPDurations * SubcarrierSpacing;
                cfoVal(2:end) = cfoVal(2:end) + 1;
                cfoVal = cumsum(cfoVal) * cfo;
                cfoVal = exp(2j * pi * cfoVal);
                channelRG = (channelRG .* cfoVal) * exp(1j * pi * ((fftSize - 1) / fftSize) * cfo);
            end

            % Compute received resource grid.
            receivedRG = channelRG .* transmittedRG;
            SNR = 20; % dB
            noiseVar = 10^(-SNR/10);
            noise = randn(size(receivedRG)) + 1j * randn(size(receivedRG));
            noise(receivedRG == 0) = 0;
            noise = noise * sqrt(noiseVar / 2);
            receivedRG = receivedRG + noise;

            EstimatorConfig.DMRSSymbolMask = obj.DMRSsymbols;
            EstimatorConfig.DMRSREmask = obj.DMRSREmask;
            EstimatorConfig.scs = SubcarrierSpacing * 1000;
            EstimatorConfig.CyclicPrefixDurations = CPDurations;
            [channelEst, noiseEst, rsrp, epre, timeAlignment, cfoEst] = srsChannelEstimator(receivedRG, ...
                pilots, betaDMRS, hop1, hop2, EstimatorConfig);

            % TODO: The ratio of the two quantities below should give a metric that allows us
            % to decide whether pilots were sent or not. However, it should be normalized
            % and it's a bit tricky.
            % detectMetricNum = detectMetricNum / nDMRSsymbols;
            % detectMetricDen = noiseEst;
            % detectionMetric = detectMetricNum / detectMetricDen;

            snrEst = rsrp / betaDMRS^2 / noiseEst;

            % A few very loose checks, just to ensure we are not completely out of place.
            if (configuration.nPRBs > 2)
                chEstIdx = (channelEst ~= 0);
                obj.assertEqual(channelEst(chEstIdx), channelRG(chEstIdx), "Wrong channel coefficients.", RelTol = 0.2);
                obj.assertEqual(noiseEst, noiseVar, "Wrong noise variance.", RelTol = 0.6);
                obj.assertEqual(snrEst, 10^(SNR/10), "Wrong SNR.", RelTol = 1.3);
                obj.assertEqual(timeAlignment, channelDelay / fftSize / SubcarrierSpacing / 1000, ...
                "Wrong time alignment.", AbsTol = 2e-7);
                if ~isempty(cfoEst)
                    obj.assertEqual(cfoEst, cfo * SubcarrierSpacing * 1000, "Wrong CFO.", AbsTol = 40, RelTol = 0.7);
                end
            end

            % Write the received resource grid.
            [scs, syms, vals] = find(receivedRG);
            obj.saveDataFile('_test_input_rg', testID, @writeResourceGridEntryFile, ...
                vals, [scs, syms, zeros(length(scs), 1)] - 1);

            % Write the estimated channel.
            [scs, syms, vals] = find(channelEst);
            obj.saveDataFile('_test_output_ch_est', testID, @writeResourceGridEntryFile, ...
                vals, [scs, syms, zeros(length(scs), 1)] - 1);

            % Write the pilots.
            obj.saveDataFile('_test_pilots', testID, @writeComplexFloatFile, pilots(:));

            dmrsPattern = {...
                obj.DMRSsymbols, ...    % symbols
                hop1.maskPRBs,   ...    % rb_mask
                hop2.maskPRBs,   ...    % rb_mask2
                obj.secondHop,   ...    % hopping_symbol_index
                obj.DMRSREmask,  ...    % re_pattern
                };

            startSymbol = configuration.symbolAllocation(1);
            nAllocatedSymbols = configuration.symbolAllocation(2);
            scsString = sprintf('subcarrier_spacing::kHz%d', SubcarrierSpacing);

            configurationOut = {...
                scsString, ...                   % scs
                'cyclic_prefix::NORMAL', ...     % cp
                startSymbol, ...                 % first_symbol
                nAllocatedSymbols, ...           % nof_symbols
                {dmrsPattern}, ...               % dmrs_patterns
                {0}, ...                         % rx_ports
                betaDMRS, ...                    % betaDMRS
                };

            if isempty(cfoEst)
                cfoEst = {};
            end

            context = {...
                configurationOut, ...
                obj.NSizeGrid, ...
                rsrp, ...
                epre, ...
                SNR, ...
                10 * log10(snrEst), ...
                noiseEst, ...
                timeAlignment * 1e6, ...
                cfo * SubcarrierSpacing * 1000, ...
                cfoEst, ...
                };

            testCaseString = obj.testCaseToString(testID, context, false, ...
                '_test_input_rg', '_test_pilots', '_test_output_ch_est');

            % Add the test to the header file.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases(...)
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function compareMex(obj, configuration, SubcarrierSpacing, FrequencyHopping, CarrierOffset)
        %compareMex - Compare mex results with those from the reference estimator for
        %   a given CONFIGURATION, SUBCARRIERSPACING, FREQUENCYHOPPING type and CARRIEROFFSET.

            import srsLib.phy.upper.signal_processors.srsChannelEstimator
            import srsLib.ran.utils.scs2cps
            import srsMEX.phy.srsMultiPortChannelEstimator

            obj.assumeFalse(((configuration.nPRBs == obj.NSizeBWP) || (configuration.symbolAllocation(2) == 1)) ...
                && strcmp(FrequencyHopping, 'intraSlot'), ...
                'Cannot do frequency hopping if the entire BWP is allocated or if using a single OFDM symbol.');

            assert((sum(configuration.symbolAllocation) <= obj.nSymbolsSlot), ...
                'srsran_matlab:srsChEstimatorUnittest', 'Time allocation exceeds slot length.');

            % Configure each hop.
            [hop1, hop2] = obj.configureHops(configuration, FrequencyHopping);

            % Build DM-RS-like pilots.
            nDMRSsymbols = sum(obj.DMRSsymbols);
            nPilots = configuration.nPRBs * sum(obj.DMRSREmask) * nDMRSsymbols;
            pilots = (2 * randi([0 1], nPilots, 2) - 1) * [1; 1j] / sqrt(2);
            pilots = reshape(pilots, [], nDMRSsymbols);

            betaDMRS = 10^(-configuration.betaDMRS / 20);

            % Place pilots on the resource grid.
            transmittedRG = obj.transmitPilots(pilots, betaDMRS, hop1, hop2);

            % For now, consider a single-tap channel (max delay is 1/4 of
            % the cyclic prefix length).
            fftSize =  obj.NSizeGrid * obj.NRE;
            channelDelay = randi([0, floor(fftSize * 0.07 * 0.25)]);
            channelCoef = exp(2j * pi * rand);
            channelTF = fft([zeros(channelDelay, 1); channelCoef; zeros(5, 1)], fftSize);
            channelTF = fftshift(channelTF);
            % We assume the channel constant over the entire slot...
            channelRG = repmat(channelTF, 1, obj.nSymbolsSlot);
            % ... but for CFO.
            cfo = CarrierOffset; % Fraction of the SCS.
            CPDurations = scs2cps(SubcarrierSpacing);

            if cfo ~= 0
                cfoVal = CPDurations * SubcarrierSpacing;
                cfoVal(2:end) = cfoVal(2:end) + 1;
                cfoVal = cumsum(cfoVal) * cfo;
                cfoVal = exp(2j * pi * cfoVal);
                channelRG = (channelRG .* cfoVal) * exp(1j * pi * ((fftSize - 1) / fftSize) * cfo);
            end

            % Compute received resource grid.
            receivedRG = channelRG .* transmittedRG;
            SNR = 20; % dB
            noiseVar = 10^(-SNR/10);
            noise = randn(size(receivedRG)) + 1j * randn(size(receivedRG));
            noise(receivedRG == 0) = 0;
            noise = noise * sqrt(noiseVar / 2);
            receivedRG = receivedRG + noise;

            EstimatorConfig.DMRSSymbolMask = obj.DMRSsymbols;
            EstimatorConfig.DMRSREmask = obj.DMRSREmask;
            EstimatorConfig.scs = 15000;
            EstimatorConfig.CyclicPrefixDurations = CPDurations;
            [channelEst, noiseEst, rsrp, epre, timeAlignment, cfoEst] = srsChannelEstimator(receivedRG, ...
                pilots, betaDMRS, hop1, hop2, EstimatorConfig);

            % Cast input for the mex estimator.
            pilotRBMask = hop1.maskPRBs * hop1.DMRSsymbols';
            if (~isempty(hop2.maskPRBs) && ~isempty(hop2.DMRSsymbols))
                pilotRBMask = pilotRBMask + hop2.maskPRBs * hop2.DMRSsymbols';
            end
            pilotMask = kron(pilotRBMask, hop1.DMRSREmask);
            pilotIndices = find(pilotMask);

            mexEstimator = srsMultiPortChannelEstimator;
            [channelEstMEX, noiseEstMEX, extra] ...
                = mexEstimator(receivedRG, configuration.symbolAllocation, pilotIndices, ...
                pilots(:), HoppingIndex = hop2.startSymbol, BetaScaling = betaDMRS); %#ok<FNDSB>

            tolerance = 0.05;
            chEstIdx = (channelEst ~= 0);
            obj.assertEqual(channelEstMEX(chEstIdx), channelEst(chEstIdx), 'Wrong channel estimates.', RelTol = tolerance);
            obj.assertEqual(noiseEstMEX, noiseEst, 'Wrong noise variance estimate.', RelTol = tolerance);
            obj.assertEqual(extra.RSRP, rsrp, 'Wrong RSRP estimate.', RelTol = tolerance);
            obj.assertEqual(extra.EPRE, epre, 'Wrong EPRE estimate.', RelTol = tolerance);
            obj.assertEqual(extra.SINR, rsrp / betaDMRS^2 / noiseEst, 'Wrong SINR estimate.', RelTol = tolerance);
            obj.assertEqual(extra.TimeAlignment, timeAlignment, 'Wrong time alignment estimate.', RelTol = tolerance);
            obj.assertEqual(extra.CFO, cfoEst, 'Wrong CFO.', RelTol = tolerance);
        end % of function testvectorGenerationCases(...)
    end % of methods (Test, TestTags = {'testmex'})

    methods % public
        function [mse, noiseEst, rsrpEst, epreEst, cfoEst, crlb] = characterize(obj, configuration, ...
                FrequencyHopping, scs, channelType, delay, doppler, cfo, snrValues, nRuns, sizeBWP)
        %characterize - Draw the empircical MSE performance curve of the estimator.
        %   MSE = characterize(OBJ, CONFIGURATION, FREQUENCYHOPPING, SCS, CHANNELTYPE, DELAY, DOPPLER, CFO, SNRVALUES, NRUNS)
        %   returns the empirical mean squared error of the channel estimation after NRUNS simulations
        %   and for all SNRVALUES. CONFIGURATION, FREQUENCYHOPPING and SCS provide the physical
        %   channel configuration and CHANNELTYPE, DELAY, DOPPLER and CFO specify the simulated channel model.
        %   Note: DELAY is the delay spread for the IEEE channel types, and the Path delay
        %   for the 'pure-delay' channel type.
        %   Note: DOPPLER is the maximum Doppler shift in hertz (effect of scattering), not to
        %   be confused with the CFO.
        %
        %   MSE = characterize(..., BWP) also changes the BWP size (expressed as a number of RBs).
        %   The default BWP size is 51.
        %
        %   [MSE, NOISEEST, RSRPEST, EPREEST, CFOEST, CRLB] = characterize(...) also returns the
        %   estimates of noise variance, RSRP, EPRE and CFO for all runs and all SNR values,
        %   as well as the CRLB for the channel estimation. The CRLB is computed assuming
        %   the entire band is available for estimation, with pilots positioned with
        %   the same pattern as the DM-RS (first column) or with pilots in all REs
        %   (second column).
        %
        %   For CONFIGURATION and FREQUENCYHOPPING, see <a href="matlab:help srsChEstimatorUnittest">the main class documantation</a>.
        %   SNRVALUES is an array of SNR values in decibel.
        %   NRUNS is an integer number of simulations.
            arguments
                obj              (1, 1) srsChEstimatorUnittest
                configuration    (1, 1) struct {mustBeConfiguration}
                FrequencyHopping (1, :) char   {mustBeMember(FrequencyHopping, {'neither', 'intraSlot'})}
                scs              (1, 1) double {mustBeMember(scs, [15, 30])}
                channelType      (1, :) char   {mustBeMember(channelType, {'pure-delay', ...
                    'TDL-A', 'TDL-B', 'TDL-C', 'TDL-D', 'TDL-E', ...
                    'TDLA30', 'TDLB100', 'TDLC300', 'TDLC60'})}
                delay            (1, 1) double {mustBeReal, mustBeNonnegative}
                doppler          (1, 1) double {mustBeReal, mustBeNonnegative}
                cfo              (1, 1) double {mustBeReal}
                snrValues               double {mustBeReal, mustBeVector}
                nRuns            (1, 1) double {mustBeNonnegative, mustBeInteger}
                sizeBWP          (1, 1) double = NaN
            end

            import srsLib.phy.upper.signal_processors.srsChannelEstimator

            if ~isempty(delay)
                validateattributes(delay, 'double', {'nonnegative'});
            end

            if ~isnan(sizeBWP)
                validateattributes(sizeBWP, 'double', {'positive', 'integer', '<=', 273});
                obj.NSizeBWP = sizeBWP;
                obj.NSizeGrid = obj.NStartBWP + obj.NSizeBWP;
            end

            % Cannot do frequency hopping if the entire BWP is allocated or if using a single OFDM symbol.
            assert(~(((configuration.nPRBs == obj.NSizeBWP) || (configuration.symbolAllocation(2) == 1)) ...
                    && strcmp(FrequencyHopping, 'intraSlot')), 'srsgnb_matlab:srsChEstimatorUnittest', ...
                    'Unfeasible configuration-frequency hopping combination.');

            assert((sum(configuration.symbolAllocation) <= obj.nSymbolsSlot), ...
                'srsgnb_matlab:srsChEstimatorUnittest', 'Time allocation exceeds slot length.');

            % Configure carrier.
            carrier = nrCarrierConfig;
            carrier.CyclicPrefix = 'Normal';
            carrier.SubcarrierSpacing = scs; % kHz
            carrier.NSlot = 0;
            carrier.NSizeGrid = obj.NSizeGrid;

            waveformInfo = nrOFDMInfo(carrier);
            channel = configureChannel(channelType, delay, doppler, waveformInfo.SampleRate, ...
                carrier.SubcarrierSpacing);

            % Configure each hop.
            [hop1, hop2] = obj.configureHops(configuration, FrequencyHopping);

            % Build DM-RS-like pilots.
            nDMRSsymbols = sum(obj.DMRSsymbols);
            nPilots = configuration.nPRBs * sum(obj.DMRSREmask) * nDMRSsymbols;
            pilots = (2 * randi([0 1], nPilots, 2) - 1) * [1; 1j] / sqrt(2);
            pilots = reshape(pilots, [], nDMRSsymbols);

            betaDMRS = 10^(-configuration.betaDMRS / 20);

            % Place pilots on the resource grid.
            transmittedRG = obj.transmitPilots(pilots, betaDMRS, hop1, hop2);

            transmittedWF = nrOFDMModulate(carrier, transmittedRG);

            nEstSCS = hop1.nPRBs * obj.NRE;
            if ~isempty(hop2.maskPRBs)
                nEstSCS = nEstSCS * 2;
            end

            mse = zeros(length(snrValues), nEstSCS);
            noiseEst = zeros(length(snrValues), nRuns);
            rsrpEst = zeros(length(snrValues), nRuns);
            epreEst = zeros(length(snrValues), nRuns);
            cfoEst = zeros(length(snrValues), nRuns);

            CPDurations = waveformInfo.CyclicPrefixLengths(1:14);
            CPDurations = CPDurations / sum(CPDurations) / scs;

            % Configure estimator.
            EstimatorConfig.DMRSSymbolMask = obj.DMRSsymbols;
            EstimatorConfig.DMRSREmask = obj.DMRSREmask;
            EstimatorConfig.nPilotsNoiseAvg = sum(obj.DMRSREmask);
            EstimatorConfig.scs = scs * 1000; % SCS in hertz
            EstimatorConfig.CyclicPrefixDurations = CPDurations;
            % EstimatorConfig.CFOCompensate = false; % for legacy estimator without CFO compensation.

            for iRun = 1:nRuns
                reset(channel);
                [receivedWF0, pathGains, sampleTimes] = channel(transmittedWF);

                if cfo ~= 0
                    nSamples = size(receivedWF0, 1);
                    if (~exist('cfoPhase', 'var') || length(cfoPhase) ~= nSamples)
                        timeIx = (0:length(receivedWF0)-1).';
                        cfoPhase = exp(2j * pi * timeIx * cfo / waveformInfo.SampleRate);
                    end
                    receivedWF0 = receivedWF0 .* cfoPhase;
                end

                noise0 = randn(size(receivedWF0)) + 1j * randn(size(receivedWF0));

                iSNR = 0;
                for SNR = snrValues
                    iSNR = iSNR + 1;
                    noiseVar = 10^(-SNR/10) / waveformInfo.Nfft;
                    noise = noise0 * sqrt(noiseVar / 2);

                    receivedWF = receivedWF0 + noise;

                    % Compute received resource grid.
                    receivedRG = nrOFDMDemodulate(carrier, receivedWF);

                    [channelEst, noiseEstL, rsrpEstL, epreEstL, ~, cfoEstL] ...
                        = srsChannelEstimator(receivedRG, pilots, betaDMRS, hop1, hop2, EstimatorConfig);
                    noiseEst(iSNR, iRun) = noiseEstL;
                    rsrpEst(iSNR, iRun) = rsrpEstL;
                    epreEst(iSNR, iRun) = epreEstL;
                    cfoEst(iSNR, iRun) = cfoEstL;

                    % Get the true channel, for comparison.
                    pathFilters = channel.getPathFilters();
                    channelTrue = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, 0, sampleTimes);

                    if cfo ~= 0
                        cfoNorm = cfo / scs / 1000;
                        cfoFreq = [waveformInfo.CyclicPrefixLengths(1) waveformInfo.CyclicPrefixLengths(2:14) + waveformInfo.Nfft];
                        cfoFreq = cumsum(cfoFreq) * cfoNorm / waveformInfo.Nfft;
                        cfoFreq = exp(2j * pi * cfoFreq);
                        channelTrue = channelTrue * diag(cfoFreq) * exp(1j * pi * ((waveformInfo.Nfft - 1) / waveformInfo.Nfft) * cfoNorm);
                    end

                    % Just for debugging/analysis purposes: set to true to visualize
                    % the effect of channel and channel estimation on a random QAM
                    % points.
                    if false
                        whatSymbol = 1+hop1.startSymbol; %#ok<UNRCH>
                        whatSCS = (channelEst(:, whatSymbol) ~= 0);
                        nSCS = sum(whatSCS);
                        % Create some random QAM points.
                        fakeSymbols = srsTest.helpers.randmod('QPSK', [nSCS, 50]);

                        % Apply the true channel and ZF-equalize with the estimated channel (SC-wise).
                        rr = diag(channelTrue(whatSCS, whatSymbol) ./ channelEst(whatSCS, whatSymbol)) * fakeSymbols;

                        % Split edge and middle points, to visualize the difference in
                        % the estimation performance.
                        rrEdge = rr([1:24, end-23:end], :);
                        rrMiddle = rr(25:end-24, :);
                        plot(real(rrEdge(:)), imag(rrEdge(:)), 'rx', real(rrMiddle(:)), imag(rrMiddle(:)), 'bx')
                        pause
                    end

                    scsIdx = obj.NRE * hop1.PRBstart + (1: obj.NRE * hop1.nPRBs);
                    estErrors = channelEst(scsIdx, hop1.CHsymbols) - channelTrue(scsIdx, hop1.CHsymbols);
                    SQestErrors = sum(abs(estErrors).^2, 2);
                    if ~isempty(hop2.maskPRBs)
                        scsIdx = obj.NRE * hop2.PRBstart + (1: obj.NRE * hop2.nPRBs);
                        estErrors2 = channelEst(scsIdx, hop2.CHsymbols) - channelTrue(scsIdx, hop2.CHsymbols);
                        SQestErrors2 = sum(abs(estErrors2).^2, 2);
                    else
                        SQestErrors2 = [];
                    end

                    mse(iSNR, :) = mse(iSNR, :) + [SQestErrors; SQestErrors2]' / nRuns;
                end
            end

            crlb = repmat(10.^(-snrValues(:)/10), 1, 2) / betaDMRS^2 / sum(hop1.DMRSsymbols);
            crlb = (crlb' .* computeCRLB(hop1.maskPRBs, hop1.DMRSREmask))';
        end % of function testvectorGenerationCases(...)
    end % of methods % public

    methods (Access = private)
        function [hop1, hop2] = configureHops(obj, configuration, FrequencyHopping)
        %Creates a description of the resources allocated in each hop.

            startSymbol = configuration.symbolAllocation(1);
            nAllocatedSymbols = configuration.symbolAllocation(2);
            dmrsStrideTime = configuration.dmrsStrideTime;

            % Create a mask of the OFDM symbols carrying DM-RS.
            obj.DMRSsymbols = false(14, 1);
            obj.DMRSsymbols(startSymbol + (1:dmrsStrideTime:nAllocatedSymbols)) = true;

            nPRBs = configuration.nPRBs;
            dmrsOffset = configuration.dmrsOffset;
            dmrsStrideSCS = configuration.dmrsStrideSCS;

            % Create a DM-RS pattern from the offset and stride.
            obj.DMRSREmask = false(obj.NRE, 1);
            obj.DMRSREmask((dmrsOffset + 1):dmrsStrideSCS:end) = true;

            if strcmp(FrequencyHopping, 'intraSlot')
                PRBstart = randperm(obj.NSizeBWP - nPRBs + 1, 2) - 1 + obj.NStartBWP;

                obj.secondHop = startSymbol + floor(nAllocatedSymbols / 2);
                hopMask = [true(obj.secondHop, 1); false(obj.nSymbolsSlot - obj.secondHop, 1)];

                hop1.DMRSsymbols = (obj.DMRSsymbols & hopMask);
                hop1.DMRSREmask = obj.DMRSREmask;
                hop1.PRBstart = PRBstart(1);
                hop1.nPRBs = nPRBs;
                hop1.maskPRBs = false(obj.NSizeGrid, 1);
                hop1.maskPRBs(hop1.PRBstart + (1:nPRBs)) = true;
                hop1.startSymbol = startSymbol;
                hop1.nAllocatedSymbols = floor(nAllocatedSymbols / 2);
                hop1.CHsymbols = false(obj.nSymbolsSlot, 1);
                hop1.CHsymbols(hop1.startSymbol + (1:hop1.nAllocatedSymbols)) = true;

                hop2.DMRSsymbols = (obj.DMRSsymbols & (~hopMask));
                hop2.DMRSREmask = obj.DMRSREmask;
                hop2.PRBstart = PRBstart(2);
                hop2.nPRBs = nPRBs;
                hop2.maskPRBs = false(obj.NSizeGrid, 1);
                hop2.maskPRBs(hop2.PRBstart + (1:nPRBs)) = true;
                hop2.startSymbol = obj.secondHop;
                hop2.nAllocatedSymbols = ceil(nAllocatedSymbols / 2);
                hop2.CHsymbols = false(obj.nSymbolsSlot, 1);
                hop2.CHsymbols(hop2.startSymbol + (1:hop2.nAllocatedSymbols)) = true;
            else
                PRBstart = randi([0, obj.NSizeBWP - nPRBs]) + obj.NStartBWP;
                obj.secondHop = 'nullopt';

                hop1.DMRSsymbols = obj.DMRSsymbols;
                hop1.DMRSREmask = obj.DMRSREmask;
                hop1.PRBstart = PRBstart;
                hop1.nPRBs = nPRBs;
                hop1.maskPRBs = false(obj.NSizeGrid, 1);
                hop1.maskPRBs(hop1.PRBstart + (1:nPRBs)) = true;
                hop1.startSymbol = startSymbol;
                hop1.nAllocatedSymbols = nAllocatedSymbols;
                hop1.CHsymbols = false(obj.nSymbolsSlot, 1);
                hop1.CHsymbols(hop1.startSymbol + (1:hop1.nAllocatedSymbols)) = true;

                hop2.DMRSsymbols = [];
                hop2.maskPRBs = {};
                hop2.startSymbol = [];
            end
        end % of function [hop1 hop2] = configureHops()

        function transmittedRG = transmitPilots(obj, pilots, betaDMRS, hop1, hop2)
        %Places the pilots on the correct REs and with the correct power on the resource grid.
            transmittedRG = zeros(obj.NSizeGrid * obj.NRE, obj.nSymbolsSlot);

            nPilotSymbolsHop1 = sum(hop1.DMRSsymbols);

            processHop(hop1, pilots(:, 1:nPilotSymbolsHop1));

            if ~isempty(hop2.DMRSsymbols)
                processHop(hop2, pilots(:, (nPilotSymbolsHop1 + 1):end));
            end

            %     Nested functions
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function processHop(hop_, pilots_)
            %Processes the DM-RS corresponding to a single hop.

                % Create a mask for all subcarriers carrying DM-RS.
                maskPRBs_ = hop_.maskPRBs;
                maskREs_ = (kron(maskPRBs_, obj.DMRSREmask) > 0);

                transmittedRG(maskREs_, hop_.DMRSsymbols) = betaDMRS * pilots_;
            end % of function processHop(hop_, pilots_)
        end % of function transmittedRG = transmitPilots(pilots, hop1, hop2)
    end % of methods (Access = private)
end % of classdef srsChEstimatorUnittest

function channel = configureChannel(chModel, delay, doppler, SampleRate, SubcarrierSpacing)
    channel = nrTDLChannel;
    channel.NumTransmitAntennas = 1;
    channel.NumReceiveAntennas = 1;
    channel.MaximumDopplerShift = doppler;
    channel.SampleRate = SampleRate;
    channel.RandomStream = 'Global stream';
    if strcmp(chModel, 'pure-delay')
        channel.DelayProfile = 'Custom';
        if isempty(delay)
            % Random delay, at most one fourth of the cyclic prefix length.
            channel.PathDelays = rand() * 0.018 / SubcarrierSpacing / 1000;
        else
            channel.PathDelays = delay;
        end
        channel.AveragePathGains = 0;
        channel.FadingDistribution = 'Rayleigh';
    elseif ismember(chModel, {'TDL-A', 'TDL-B', 'TDL-C', 'TDL-D', 'TDL-E'})
        channel.DelayProfile = chModel;
        if ~isempty(delay)
            channel.DelaySpread = delay;
        end
    elseif ismember(chModel, {'TDLA30', 'TDLB100', 'TDLC300', 'TDLC60'})
        channel.DelayProfile = chModel;
    else
        error('srsgnb_matlab:srsChEstimatorUnittest:configureChannel', ...
            'Unknown channel model %s', chModel);
    end
end


function mustBeConfiguration(a)
    if ~isfield(a, 'nPRBs')
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Missing configuration field "nPRBs."';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeScalarOrEmpty(a.nPRBs);
    mustBeInteger(a.nPRBs);
    mustBeInRange(a.nPRBs, 1, 273);

    if ~isfield(a, 'symbolAllocation')
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Missing configuration field "symbolAllocation".';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeVector(a.symbolAllocation)
    if numel(a.symbolAllocation) ~= 2
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Configuration field "symbolAllocation" should be an array of two elements.';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeInteger(a.symbolAllocation);
    mustBeNonnegative(a.symbolAllocation);
    if (a.symbolAllocation(1) + a.symbolAllocation(2) > 14)
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Inconsistent symbol allocation.';
        throwAsCaller(MException(eidType, msgType));
    end

    if ~isfield(a, 'dmrsOffset')
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Missing configuration field "dmrsOffset".';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeScalarOrEmpty(a.dmrsOffset);
    mustBeMember(a.dmrsOffset, [0, 1]);

    if ~isfield(a, 'dmrsStrideSCS')
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Missing configuration field "dmrsStrideSCS".';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeScalarOrEmpty(a.dmrsStrideSCS);
    mustBeMember(a.dmrsStrideSCS, [1, 2, 3]);

    if ~isfield(a, 'dmrsStrideTime')
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Missing configuration field "dmrsStrideTime".';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeScalarOrEmpty(a.dmrsStrideTime);
    mustBeMember(a.dmrsStrideTime, [1, 2, 4, 6, 20]);

    if ~isfield(a, 'betaDMRS')
        eidType = 'srsChEstimatorUnittest:characterize';
        msgType = 'Missing configuration field "betaDMRS".';
        throwAsCaller(MException(eidType, msgType));
    end
    mustBeScalarOrEmpty(a.betaDMRS);
    mustBeMember(a.betaDMRS, [-3, 0]);
end

function crlb = computeCRLB(prbMask, reMask)
%computeCRLB Cramer-Rao Lower Bound
%   CRLB = computeCRLB(PRBMASK, REMASK) computes the Cramer-Rao Lower Bound (CRLB)
%   for the channel estimation. The CRLB is computed assuming that the entire band
%   can be used for the estimation, with pilots spaced according to REMASK (first
%   entry) or with pilots in all REs (second entry). The assumption is needed to
%   avoid a singular Fisher matrix.

    Nprb = length(prbMask);
    Nre = Nprb * 12;
    assert(length(reMask) == 12);
    E = diag(kron(ones(Nprb, 1), reMask));
    Jbig = ifft(fft(E, Nre, 2), Nre, 1);
    cp = floor(Nre / 10);
    J = Jbig(1:cp, 1:cp);
    s = warning('error', 'MATLAB:nearlySingularMatrix');
    crlb = nan(2, 1);
    chMask = (kron(prbMask, ones(12, 1)) == 1);
    try
        C = inv(J);
        M = fft(ifft(C, Nre, 2), Nre, 1);

        crlb(1) = real(trace(M(chMask, chMask))) / sum(chMask);
    catch ME
        if strcmp(ME.identifier, 'MATLAB:nearlySingularMatrix')
            warning('Pattern CRLB can''t be computed.');
        else
            rethrow(ME);
        end
    end

    E = diag(kron(ones(Nprb, 1), ones(12, 1)));
    Jbig = ifft(fft(E, Nre, 2), Nre, 1);
    J = Jbig(1:cp, 1:cp);
    try
        C = inv(J);
        M = fft(ifft(C, Nre, 2), Nre, 1);

        crlb(2) = real(trace(M(chMask, chMask))) / sum(chMask);
    catch ME
        if ~strcmp(ME.identifier, 'MATLAB:nearlySingularMatrix')
            warning('Full CRLB can''t be computed.');
        else
            rethrow(ME);
        end
    end
    warning(s);
end
