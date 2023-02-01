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
%   FrequencyHopping  - Frequency hopping type.
%
%   srsChEstimatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsChEstimatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
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

        % Fix BWP size and start as well as the frame number, since they
        % are irrelevant for the test.
        NSizeBWP = 51
        NStartBWP = 1
        NSizeGrid = srsChEstimatorUnittest.NSizeBWP + srsChEstimatorUnittest.NStartBWP
    end % of properties (Hidden, Constant)

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
        %   dmrsStrideTime   - Stride between OFDM symbols containing DM-RS (1...4).
        %   betaDMRS         - The gain of the DM-RS pilots with respect to the data
        %                      symbols in dB (0, 3).
        configuration = {...
            struct(...        % PUSCH DM-RS configuration Type 1 (inspired to).
               'nPRBs', 3, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 2, ...
               'dmrsStrideTime', 4, ...
               'betaDMRS', -3 ...
               ),...
            struct(...        % PUSCH DM-RS configuration Type 1 (inspired to).
               'nPRBs', 20, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 2, ...
               'dmrsStrideTime', 4, ...
               'betaDMRS', -3 ...
               ), ...
            struct(...        % PUSCH DM-RS configuration Type 1 (inspired to).
               'nPRBs', 51, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 2, ...
               'dmrsStrideTime', 4, ...
               'betaDMRS', -3 ...
               ), ...
            struct(...        % PUCCH Format 1 (inspired to).
               'nPRBs', 1, ...
               'symbolAllocation', [8, 4], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 1, ...
               'dmrsStrideTime', 2, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % PUCCH Format 1 (inspired to).
               'nPRBs', 1, ...
               'symbolAllocation', [0, 14], ...
               'dmrsOffset', 0, ...
               'dmrsStrideSCS', 1, ...
               'dmrsStrideTime', 2, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % PUCCH Format 2 (inspired to).
               'nPRBs', 1, ...
               'symbolAllocation', [0, 2], ...
               'dmrsOffset', 1, ...
               'dmrsStrideSCS', 3, ...
               'dmrsStrideTime', 1, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % PUCCH Format 2 (inspired to).
               'nPRBs', 6, ...
               'symbolAllocation', [5, 1], ...
               'dmrsOffset', 1, ...
               'dmrsStrideSCS', 3, ...
               'dmrsStrideTime', 1, ...
               'betaDMRS', 0 ...
               ), ...
            struct(...        % PUCCH Format 2 (inspired to).
               'nPRBs', 16, ...
               'symbolAllocation', [5, 2], ...
               'dmrsOffset', 1, ...
               'dmrsStrideSCS', 3, ...
               'dmrsStrideTime', 1, ...
               'betaDMRS', 0 ...
               ), ...
            }

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'}
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
            fprintf(fileID, '#include "srsgnb/phy/upper/signal_processors/port_channel_estimator.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');

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
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '  file_vector<cf_t>                                       pilots;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> estimates;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, configuration, FrequencyHopping)
        %testvectorGenerationCases - Generates a test vector according to the provided
        %   CONFIGURATION and FREQUENCYHOPPING type.

            import srsMatlabWrappers.phy.upper.signal_processors.srsChannelEstimator
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeComplexFloatFile

            % Cannot do frequency hopping if the entire BWP is allocated or if using a single OFDM symbol.
            if ((configuration.nPRBs == obj.NSizeBWP) || (configuration.symbolAllocation(2) == 1)) ...
                    && strcmp(FrequencyHopping, 'intraSlot')
                return;
            end

            assert((sum(configuration.symbolAllocation) <= obj.nSymbolsSlot), ...
                'srsgnb_matlab:srsChEstimatorUnittest', 'Time allocation exceeds slot length.');

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

            % For now, consider a single-tap channel.
            channelDelay = randi([0, 40]);
            channelCoef = exp(2j * pi * rand);
            channelTF = fft([zeros(channelDelay, 1); channelCoef; zeros(5, 1)], obj.NSizeGrid * obj.NRE);
            channelTF = fftshift(channelTF);
            % We assume the channel constant over the entire slot.
            channelRG = repmat(channelTF, 1, obj.nSymbolsSlot);

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
            EstimatorConfig.nPilotsNoiseAvg = sum(obj.DMRSREmask);
            [channelEst, noiseEst, rsrp, epre] = srsChannelEstimator(receivedRG, pilots, betaDMRS, hop1, hop2, EstimatorConfig);

            % TODO: The ratio of the two quantities below should give a metric that allows us
            % to decide whether pilots were sent or not. However, it should be normalized
            % and it's a bit tricky.
            % detectMetricNum = detectMetricNum / nDMRSsymbols;
            % detectMetricDen = noiseEst;
            % detectionMetric = detectMetricNum / detectMetricDen;

            snrEst = rsrp / betaDMRS^2 / noiseEst;

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

            configurationOut = {...
                'subcarrier_spacing::kHz15', ... % scs
                'cyclic_prefix::NORMAL', ...     % cp
                startSymbol, ...                 % first_symbol
                nAllocatedSymbols, ...           % nof_symbols
                {dmrsPattern}, ...               % dmrs_patterns
                {0}, ...                         % rx_ports
                betaDMRS, ...                    % betaDMRS
                };

            context = {...
                configurationOut, ...
                obj.NSizeGrid, ...
                rsrp, ...
                epre, ...
                SNR, ...
                10 * log10(snrEst), ...
                noiseEst, ...
                };

            testCaseString = obj.testCaseToString(testID, context, false, ...
                '_test_input_rg', '_test_pilots', '_test_output_ch_est');

            % Add the test to the header file.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases(...)
    end % of methods (Test, TestTags = {'testvector'})

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
