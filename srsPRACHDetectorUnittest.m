%srsPRACHDetectorUnittest Unit tests for PRACH detector functions.
%   This class implements unit tests for the PRACH detector functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPRACHDetectorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPRACHDetectorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'prach_detector').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPRACHDetectorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPRACHDetectorUnittest Properties (TestParameter):
%
%   DuplexMode          - Duplexing mode FDD or TDD.
%   CarrierBandwidth    - Carrier bandwidth in PRB.
%   PreambleFormat      - Generated preamble format.
%   RestrictedSet       - Restricted set type.
%   UseZCZ              - Boolean flag for larger-than-zero zero-correlation zone.
%   RBOffset            - Frequency-domain sequence mapping.
%
%   srsPRACHDetectorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPRACHDetectorUnittest Methods (TestTags = {'testmex'}):
%
%   mexTest  - Tests the mex wrapper of the SRSRAN PRACH detector.
%
%   srsPRACHDetectorUnittest Methods (Access = protected):
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

classdef srsPRACHDetectorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'prach_detector'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'prach_detector' tests will be erased).
        outputPath = {['testPRACHDetector', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Carrier duplexing mode, set to
        %   - FDD for paired spectrum with 15kHz subcarrier spacing, or
        %   - TDD for unpaired spectrum with 30kHz subcarrier spacing.
        %   - TDD-FR2 for unpaired spectrum with 120kHz subcarrier spacing (Frequency Range 2).
        DuplexMode = {'FDD', 'TDD', 'TDD-FR2'}

        %Preamble formats.
        PreambleFormat = {'0', '1', '2', 'A1','B4'}

        %Zero-correlation zone boolean flag. Set to false for no cyclic shift
        %   and set to true for cyclic shift. The final value of the zero-configuration
        %   zone index is the one given in TS38.141 Table A.6-1.
        UseZCZ = {false, true}

        %Number of receive antennas.
        nAntennas = {1, 2, 4};
    end

    properties (Constant, Hidden)
        %Restricted set type.
        %   Possible values are {'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'}.
        RestrictedSet = 'UnrestrictedSet'
        %Frequency-domain sequence mapping.
        %   Starting resource block (RB) index of the initial uplink bandwidth
        %   part (BWP) relative to carrier resource grid.
        RBOffset = 0
        %Carrier bandwidth in PRB.
        CarrierBandwidth = 52
        %Start preamble index to monitor.
        StartPreambleIndex = 0
        %Number of preamble indices to monitor.
        NofPreamblesIndices = 64
    end % of properties (Constant, Hidden)

    properties (Hidden)
        %Carrier.
        carrier
        %PRACH sequence.
        prach
        %Signal delay (in seconds).
        TrueDelay
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsran/phy/upper/channel_processors/prach_detector.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                '#include "../../support/prach_buffer_test_doubles.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'using sequence_data_type = file_tensor<static_cast<unsigned>(prach_buffer_tensor::dims::count), cf_t, prach_buffer_tensor::dims>;\n'...
                '\n'...
                'struct context_t {\n'...
                '  prach_detector::configuration config;\n'...
                '  phy_time_unit                 true_delay;\n' ...
                '  prach_detection_result        result;\n'...
                '};\n'...
                '\n'...
                'struct test_case_t {\n'...
                '  context_t context;\n'...
                '  sequence_data_type symbols;\n'...
                '};\n'...
                ]);
        end
    end % of methods (Access = protected)

    methods (TestClassSetup)
        function silenceWarnings(obj)
            warn = warning('query', 'srsran_matlab:srsPRACHdetector');
            warning('off', 'srsran_matlab:srsPRACHdetector');

            obj.addTeardown(@warning, warn.state, 'srsran_matlab:srsPRACHdetector');
        end
    end % of methods (TestClassSetup)

    methods (Access = private)
        function setupsimulation(obj, DuplexMode, PreambleFormat, UseZCZ)
        % Sets secondary simulation variables.

            import srsLib.phy.helpers.srsConfigurePRACH

            obj.assumeTrue(~strcmp(DuplexMode, 'TDD-FR2') || ismember(PreambleFormat, {'A1', 'B4'}), ...
                'Only short formats allowed in FR2.');

            restrictedSet = obj.RestrictedSet;
            rbOffset = obj.RBOffset;

            % Select PRACH random parameters.
            sequenceIndex = randi([0, 1023], 1, 1);
            preambleIndex = randi([0, 63], 1, 1);

            % Generate carrier configuration.
            obj.carrier = nrCarrierConfig;
            obj.carrier.CyclicPrefix = 'normal';
            obj.carrier.NSizeGrid = obj.CarrierBandwidth;

            frequencyRange = 'FR1';

            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    obj.carrier.SubcarrierSpacing = 15;
                case 'TDD'
                    obj.carrier.SubcarrierSpacing = 30;
                case 'TDD-FR2'
                    obj.carrier.SubcarrierSpacing = 120;
                    frequencyRange = 'FR2';
                otherwise
                    error('Invalid duplex mode %s', obj.DuplexMode);
            end

            zeroCorrelationZone = 0;

            % Select zero correlation zone according to TS38.104 Table A.6-1.
            if UseZCZ
                if strlength(PreambleFormat) == 1
                    zeroCorrelationZone = 1;
                else
                    if strcmp(DuplexMode, 'FDD') 
                        zeroCorrelationZone = 11;
                    else
                        zeroCorrelationZone = 14;
                    end
                end
            end

            % Generate PRACH configuration.
            obj.prach = srsConfigurePRACH(PreambleFormat, ...
                FrequencyRange=frequencyRange, ...
                DuplexMode=DuplexMode(1:3), ...
                SubcarrierSpacing=obj.carrier.SubcarrierSpacing, ...
                SequenceIndex=sequenceIndex, ...
                PreambleIndex=preambleIndex, ...
                RestrictedSet=restrictedSet, ...
                ZeroCorrelationZone=zeroCorrelationZone, ...
                RBOffset=rbOffset ...
                );
        end % of function setupsimulation(obj, PreambleFormat, UseZCZ)

        function grid = generatePRACH(obj, nAntennas) 
            import srsLib.phy.upper.channel_processors.srsPRACHgenerator
            import srsLib.phy.lower.modulation.srsPRACHdemodulator

            % Generate waveform.
            [waveform, gridset, info] = srsPRACHgenerator(obj.carrier, obj.prach);
            obj.prach.NPRACHSlot = info.NPRACHSlot;

            carrOFDMInfo = nrOFDMInfo(obj.carrier);

            % The maximum delay is 1/128 of the PRACH duration (half of the
            % smallest zero-correlation zone).
            obj.TrueDelay = (0.1 + 0.9 * rand) / obj.prach.SubcarrierSpacing / 1000 / 128;
            delaySamples = floor(obj.TrueDelay * gridset.Info.SampleRate);

            channelMatrix = ones(1, nAntennas);
            rxWaveform = [zeros(delaySamples, 1); waveform] * channelMatrix;

            % Add some noise.
            snr = 0; % dB
            noiseStdDev = 10 ^ (-snr / 20) / sqrt(nAntennas * carrOFDMInfo.Nfft);

            waveformSize = size(rxWaveform);
            normNoise = (randn(waveformSize) + 1i * randn(waveformSize)) / sqrt(2);
            rxWaveform = rxWaveform + (noiseStdDev * normNoise);

            % Demodulate the PRACH signal.
            grid = srsPRACHdemodulator(obj.carrier, obj.prach, gridset.Info, rxWaveform, info);

        end % of function grid = generatePRACH(nAntennas) 
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, DuplexMode, PreambleFormat, UseZCZ, nAntennas)
        %testvectorGenerationCases Generates a test vector for the given
        %   DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet,
        %   UseZCZ and RBOffset. The parameters SequenceIndex
        %   and PreambleIndex are generated randomly.

            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID.
            TestID = obj.generateTestID;

            % Configure the test.
            obj.setupsimulation(DuplexMode, PreambleFormat, UseZCZ);

            % Generate PRACH grid.
            grid = obj.generatePRACH(nAntennas);

            [ix, delays, normMetric, rssi] = srsLib.phy.upper.channel_processors.srsPRACHdetector(obj.carrier, obj.prach, grid, true);
            pp = obj.prach.PreambleIndex + 1;
            assert(ix(pp), 'Transmitted preamble %d not detected.', pp - 1);

            % Reshape grid with PRACH symbols.
            grid = reshape(grid, obj.prach.LRA, obj.prach.PRACHDuration, nAntennas);

            % Write the generated PRACH sequence into a binary file.
            obj.saveDataFile('_test_input', TestID, ...
                @writeComplexFloatFile, grid);

            % Prepare the test header file.
            srsPRACHFormat = sprintf('to_prach_format_type("%s")', obj.prach.Format);

            switch obj.prach.RestrictedSet
                case 'UnrestrictedSet'
                    srsRestrictedSet = 'restricted_set_config::UNRESTRICTED';
                case 'RestrictedSetTypeA'
                    srsRestrictedSet = 'restricted_set_config::TYPE_A';
                case 'RestrictedSetTypeB'
                    srsRestrictedSet = 'restricted_set_config::TYPE_B';
                otherwise
                    error('Invalid restricted set %s', ojb.prach.RestrictedSet);
            end

            prachSCSString = sprintf('to_ra_subcarrier_spacing("%fkHz")', ...
                obj.prach.SubcarrierSpacing);

            % PRACH detector configuration.
            srsPRACHDetectorConfig = {...
                obj.prach.SequenceIndex, ...        % root_sequence_index
                srsPRACHFormat, ...                 % format
                srsRestrictedSet, ...               % restricted_set
                obj.prach.ZeroCorrelationZone, ...  % zero_correlation_zone
                obj.StartPreambleIndex, ...         % start_preamble_index
                obj.NofPreamblesIndices, ...        % nof_preamble_indices
                prachSCSString, ...                 % ra_scs
                nAntennas, ...                      % nof_rx_ports
                };

            delayString = sprintf('phy_time_unit::from_seconds(%g)', delays(pp) * 1e-6);
            srsPreambleIndication = {...
                obj.prach.PreambleIndex, ...            % preamble_index
                delayString, ...                        % time_advance
                normMetric(pp), ...                     % normalized detection metric
                };

            srsPrachDetectionResult = {...
                rssi, ...                               % rssi_dB
                'phy_time_unit::from_seconds(0.0)', ... % time_resolution
                'phy_time_unit::from_seconds(0.0)', ... % time_advance_max
                {srsPreambleIndication}, ...            % preambles
                };

            truedelayString = sprintf('phy_time_unit::from_seconds(%g)', obj.TrueDelay);
            srsContext = {
                srsPRACHDetectorConfig, ...  % config
                truedelayString, ...         % true PRACH delay
                srsPrachDetectionResult, ... % result
                };

            prachGridDims = {...
                size(grid, 1), ... % Number of RE.
                size(grid, 2), ... % Number of symbols.
                1, ...             % Number of frequency-domain occasions.
                1, ...             % Number of time-domain occasions.
                size(grid, 3), ... % Number of ports.
                };

            % Generate the test case entry.
            testCaseString = obj.testCaseToString(TestID, ...
                srsContext, true, {'_test_input', prachGridDims});

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, DuplexMode, PreambleFormat, UseZCZ, nAntennas)
            %mexTest  Tests the mex wrapper of the SRSRAN PRACH detector.
            %   mexTest(OBJ, DUPLEXMODE, CARRIERBANDWIDTH, PREAMBLEFORMAT,
            %   RESTRICTEDSET, ZEROCORRELATIONZONE, RBOFFSET) runs a short
            %   simulation with a UL transmission using a carrier with duplex
            %   mode DUPLEXMODE and a bandiwth of CARRIERBANDWITH PRBs. This
            %   transmision comprises a PRACH signal using preamble format
            %   PREAMBLEFORMAT, restricted set configuration RESTRICTEDSET,
            %   cyclic shift index configuration ZEROCORRELATIONINDEX and a RB
            %   offset RBOFFSET. The PRACH transmission is demodulated in
            %   MATLAB and PRACH detection is then performed using the mex
            %   wrapper of the SRSRAN C++ component. The test is considered
            %   as passed if the detected PRACH is equal to the transmitted one.

            import srsMEX.phy.srsPRACHDetector

            obj.assumeTrue(ismember(PreambleFormat, {'0', '1', 'A1', 'B4'}), ['Format ' PreambleFormat ' not yet supported.']);
            obj.assumeFalse(strcmp(PreambleFormat, 'B4') && strcmp(DuplexMode, 'FDD'), ...
                'For now, Format B4 is supported in TDD only (SCS 30 kHz).');

            % Configure the test.
            obj.setupsimulation(DuplexMode, PreambleFormat, UseZCZ);

            % Configure the SRS PRACH detector mex.
            PRACHDetector = srsPRACHDetector();

            nRuns = 10;
            nDetections = 0;
            nPerfectDetections = 0;
            for iRun = 1:nRuns
                % Generate PRACH grid.
                PRACHGrid = obj.generatePRACH(nAntennas);

                % Reshape grid with PRACH symbols.
                PRACHGrid = reshape(PRACHGrid, obj.prach.LRA, obj.prach.PRACHDuration, nAntennas);

                % Run the PRACH detector.
                PRACHdetectionResult = PRACHDetector(obj.prach, PRACHGrid);

                maskDetected = (PRACHdetectionResult.PreambleIndices == obj.prach.PreambleIndex);

                % If we only detect the transmitted preamble...
                if (sum(maskDetected) == 1)
                    nDetections = nDetections + 1;

                    % Now check if it's a perfect detection.
                    timeAdvanceDetected = PRACHdetectionResult.TimeAdvance(maskDetected);
                    if (abs(timeAdvanceDetected - obj.TrueDelay) <= 1.0e-6)
                        nPerfectDetections = nPerfectDetections + 1;
                    end
                end
            end
            % Not a performance test: set very loose detection probability requirements.
            obj.assertGreaterThan(nDetections, nRuns * 0.7, 'Detection probability too low.');
            obj.assertGreaterThan(nPerfectDetections, nRuns * 0.6, 'Perfect detection probability too low.');
        end % of function mextest
    end % of methods (Test, TestTags = {'testmex'})
end % of classdef srsPUSCHDecoderUnittest
