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
%   ZeroCorrelationZone - Cyclic shift configuration index {0, 15}.
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

%   Copyright 2021-2023 Software Radio Systems Limited
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
        DuplexMode = {'FDD', 'TDD'}

        %Carrier bandwidth in PRB.
        CarrierBandwidth = {52, 79, 106}

        %Preamble formats.
        PreambleFormat = {'0', '1', '2', '3'}

        %Restricted set type.
        %   Possible values are {'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'}.
        RestrictedSet = {'UnrestrictedSet'}

        %Zero correlation zone, cyclic shift configuration index.
        ZeroCorrelationZone = {0}

        %Frequency-domain sequence mapping.
        %   Starting resource block (RB) index of the initial uplink bandwidth
        %   part (BWP) relative to carrier resource grid.
        RBOffset = {0, 13, 28}

        % Currently fixed parameter values (e.g., sample delay).
        DelaySamples = {-8, 0, 1, 3}
    end

    properties (Constant, Hidden)
        % DFT size of the PRACH detector.
        DFTsizeDetector = 1536
        % Start preamble index to monitor.
        StartPreambleIndex = 0
        % Number of preamble indices to monitor.
        NofPreamblesIndices = 64
    end % of properties (Constant, Hidden)

    properties (Hidden)
        % Carrier.
        carrier
        % PRACH sequence.
        prach
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsran/phy/upper/channel_processors/prach_detector.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'struct context_t {\n'...
                '  prach_detector::configuration config;\n'...
                '  prach_detection_result        result;\n'...
                '};\n'...
                'struct test_case_t {\n'...
                '  context_t context;\n'...
                '  file_vector<cf_t> symbols;\n'...
                '};\n'...
                ]);
        end
    end % of methods (Access = protected)

    methods (TestClassSetup)
        function classSetup(obj)
            orig = rng;
            obj.addTeardown(@rng,orig)
            rng('default');
        end
    end % of methods (TestClassSetup)

    methods (Access = private)
        function setupsimulation(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset)
        % Sets secondary simulation variables.

            import srsLib.phy.helpers.srsConfigurePRACH
        
            % Generate carrier configuration.
            obj.carrier = nrCarrierConfig;
            obj.carrier.CyclicPrefix = 'normal';
            obj.carrier.NSizeGrid = CarrierBandwidth;

            % Generate PRACH configuration.
            SequenceIndex = randi([0, 1023], 1, 1);
            PreambleIndex = randi([0, 63], 1, 1);
            obj.prach = srsConfigurePRACH(DuplexMode, SequenceIndex, PreambleIndex, RestrictedSet, ZeroCorrelationZone, RBOffset, PreambleFormat);

            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    obj.carrier.SubcarrierSpacing = 15;
                case 'TDD'
                    obj.carrier.SubcarrierSpacing = 30;
                otherwise
                    error('Invalid duplex mode %s', DuplexMode);
            end
        end % of function setupsimulation(obj, SymbolAllocation, PRBAllocation, mcs)
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset)
        %testvectorGenerationCases Generates a test vector for the given
        %   DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet,
        %   ZeroCorrelationZone and RBOffset. The parameters SequenceIndex
        %   and PreambleIndex are generated randomly.

            import srsTest.helpers.writeComplexFloatFile
            import srsLib.phy.upper.channel_processors.srsPRACHgenerator
            import srsLib.phy.lower.modulation.srsPRACHdemodulator
            
            % Generate a unique test ID.
            TestID = obj.generateTestID;

            % Configure the test.
            setupsimulation(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset);

            % Generate waveform.
            [waveform, gridset, info] = srsPRACHgenerator(obj.carrier, obj.prach);

            % Demodulate the PRACH signal.
            PRACHSymbols = srsPRACHdemodulator(obj.carrier, obj.prach, gridset.Info, waveform, info);

            % Write the generated PRACH sequence into a binary file.
            obj.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, PRACHSymbols);

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

            % PRACH detector configuration.
            srsPRACHDetectorConfig = {...
                obj.prach.SequenceIndex, ...        % root_sequence_index
                srsPRACHFormat, ...                 % format
                srsRestrictedSet, ...               % restricted_set
                obj.prach.ZeroCorrelationZone, ...  % zero_correlation_zone
                obj.StartPreambleIndex, ...         % start_preamble_index
                obj.NofPreamblesIndices, ...        % nof_preamble_indices
                };

            srsPreambleIndication = {...
                obj.prach.PreambleIndex, ...            % preamble_index
                'phy_time_unit::from_seconds(0.0)', ... % time_advance
                0.0, ...                                % power_dB
                0.0, ...                                % snr_dB
                };

            srsPrachDetectionResult = {...
                0.0, ...                                % rssi_dB
                'phy_time_unit::from_seconds(0.0)', ... % time_resolution
                'phy_time_unit::from_seconds(0.0)', ... % time_advance_max
                {srsPreambleIndication}, ...            % preambles
                };

            srsContext = {
                srsPRACHDetectorConfig, ...  % config
                srsPrachDetectionResult, ... % result
                };

            % Generate the test case entry.
            testCaseString = obj.testCaseToString(TestID, ...
                srsContext, true, '_test_output');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset, DelaySamples)
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
    
            import srsLib.phy.upper.channel_processors.srsPRACHgenerator
            import srsLib.phy.lower.modulation.srsPRACHdemodulator
            import srsMEX.phy.srsPRACHDetector

            % Configure the test.
            setupsimulation(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset);

            % Generate waveform.
            [waveform, gridset, info] = srsPRACHgenerator(obj.carrier, obj.prach);

            % Nominal SNR value to add some noise.
            snr = 30; % dB
            noiseStdDev = 10 ^ (-snr / 20);

            % Add some (very little) noise.
            waveformLength = length(waveform);
            normNoise = (randn(waveformLength, 1) + 1i * randn(waveformLength, 1)) / sqrt(2);
            waveform = waveform + (noiseStdDev * normNoise);

            % Demodulate the PRACH signal.
            PRACHSymbols = srsPRACHdemodulator(obj.carrier, obj.prach, gridset.Info, waveform, info);

            % Configure the SRS PRACH detector mex.
            PRACHDetector = srsPRACHDetector('DelaySamples', DelaySamples);

            % Fill the PRACH configuration for the detector.
            PRACHCfg = srsPRACHDetector.configurePRACH(obj.prach);

            % Run the PRACH detector.
            PRACHdetectionResult = PRACHDetector(PRACHSymbols, PRACHCfg);

            % Verify the correct detection (expected, since the SNR is very high).
            obj.assertEqual(double(PRACHdetectionResult.nof_detected_preambles), 1, 'More than one PRACH preamble detected.');
            expectedDelay = DelaySamples / (obj.DFTsizeDetector * obj.prach.SubcarrierSpacing*1000);
            obj.assertEqual(PRACHdetectionResult.time_advance, expectedDelay, 'Expected delay error.');
            obj.assertEqual(double(PRACHdetectionResult.preamble_index), PRACHCfg.preamble_index, 'PRACH preamble index error.');
        end % of function mextest
    end % of methods (Test, TestTags = {'testmex'})
end % of classdef srsPUSCHDecoderUnittest
