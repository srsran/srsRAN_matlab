%srsPRACHDemodulatorUnittest Unit tests for PRACH waveform demodulator.
%   This class implements unit tests for the PRACH waveform demodulator
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with
%       testCase = srsPRACHDemodulatorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPRACHDemodulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ofdm_prach_demodulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/lower/modulation').
%
%   srsPRACHDemodulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPRACHDemodulatorUnittest Properties (TestParameter):
%
%   DuplexMode          - Duplexing mode FDD or TDD.
%   CarrierBandwidth    - Carrier bandwidth in PRB.
%   PreambleFormat      - Generated preamble format.
%   RestrictedSet       - Restricted set type.
%   ZeroCorrelationZone - Cyclic shift configuration index {0, 15}.
%   RBOffset            - Frequency-domain sequence mapping. 
%
%   srsPRACHDemodulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsPRACHDemodulatorUnittest Methods (Access = protected):
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

classdef srsPRACHDemodulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ofdm_prach_demodulator'

        %Type of the tested block.
        srsBlockType = 'phy/lower/modulation'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ofdm_prach_demodulator' tests will be erased).
        outputPath = {['testPRACHDemodulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Carrier duplexing mode, set to
        %   - FDD for paired spectrum with 15kHz subcarrier spacing, or
        %   - TDD for unpaired spectrum with 30kHz subcarrier spacing.
        DuplexMode = {'FDD', 'TDD'}

        %Carrier bandwidth in PRB.
        CarrierBandwidth = {79, 106}

        %Preamble formats.
        PreambleFormat = {'0', '1', '2', '3', 'A1', 'A1/B1', 'A2', ...
            'A2/B2', 'A3', 'A3/B3', 'B1', 'B4', 'C0', 'C2'}

        %Restricted set type.
        %   Possible values are {'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'}.
        RestrictedSet = {'UnrestrictedSet'}

        %Zero correlation zone, cyclic shift configuration index.
        ZeroCorrelationZone = {0}

        %Frequency-domain sequence mapping.
        %   Starting resource block (RB) index of the initial uplink bandwidth
        %   part (BWP) relative to carrier resource grid.
        RBOffset = {0, 2};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsran/phy/lower/modulation/ofdm_prach_demodulator.h"\n'...
                '#include "srsran/phy/lower/sampling_rate.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'struct prach_context {\n'...
                '  sampling_rate srate;\n'...
                '  ofdm_prach_demodulator::configuration config;\n'...
                '};\n'...
                '\n'...
                'struct test_case_t {\n'...
                '  prach_context context;\n'...
                '  file_vector<cf_t> input;\n'...
                '  file_vector<cf_t> output;\n'...
                '};\n'...
                ]);
        end

    end % of methods (Access = protected)

    methods (TestClassSetup)
        function classSetup(testCase)
            orig = rng;
            testCase.addTeardown(@rng,orig)
            rng('default');
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset)
        %testvectorGenerationCases Generates a test vector for the given
        %   DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet,
        %   ZeroCorrelationZone and RBOffset. The parameters SequenceIndex
        %   and PreambleIndex are generated randomly.

            import srsTest.helpers.writeComplexFloatFile
            import srsLib.phy.helpers.srsConfigurePRACH
            import srsLib.phy.upper.channel_processors.srsPRACHgenerator

            % Generate a unique test ID
            TestID = testCase.generateTestID;

            % Generate carrier configuration
            carrier = nrCarrierConfig;
            carrier.CyclicPrefix = 'normal';
            carrier.NSizeGrid = CarrierBandwidth;

            % Generate PRACH configuration.
            SequenceIndex = randi([0, 1023], 1, 1);
            prach = srsConfigurePRACH(DuplexMode, SequenceIndex, RestrictedSet, ZeroCorrelationZone, RBOffset, PreambleFormat);

            % Select a symbolic number of frequency-domain occasions.
            NumFreqOccasions = 2;

            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    carrier.SubcarrierSpacing = 15;
                case 'TDD'
                    carrier.SubcarrierSpacing = 30;
                otherwise
                    error('Invalid duplex mode %s', DuplexMode);
            end

            % Get PRACH modulation information.
            PrachOfdmInfo = nrPRACHOFDMInfo(carrier, prach);

            % Allocate the modulated waveform.
            waveform = zeros(sum(PrachOfdmInfo.SymbolLengths), 1);

            % Prepare matrix with PRACH symbols to modulate.
            PRACHSymbols = nan(prach.LRA, NumFreqOccasions, prach.NumTimeOccasions);

            % Generate a waveform for each time and frequency occasion.
            for TimeIndex = 1:prach.NumTimeOccasions
                for FrequencyIndex = 1:NumFreqOccasions
                    % Select time- and frequency-domain occasion.
                    prach.TimeIndex = TimeIndex - 1;
                    prach.FrequencyIndex = FrequencyIndex - 1;

                    % Select a random preamble index.
                    prach.PreambleIndex = randi([0, 63]);

                    % Generate waveform for each occasion.
                    [occasion, gridset, info] = srsPRACHgenerator(carrier, prach);

                    % Combine the waveform of each occasion.
                    waveform = occasion + waveform;

                    % Store PRACH sequence.
                    PRACHSymbols(:, FrequencyIndex, TimeIndex) = info.PRACHSymbols(1:prach.LRA);
                end % for FrequencyIndex = NumFreqOccasions
            end % for TimeIndex = 0:prach.NumTimeOccasions

            % Correct waveform scaling for the demodulator.
            ofdmInfo = nrOFDMInfo(carrier);
            prachInfo = nrPRACHOFDMInfo(carrier, prach);
            scaling = sqrt(prach.LRA * ofdmInfo.Nfft / prachInfo.Nfft);
            waveform = waveform * scaling;

            % Reset time and frequency indexes.
            prach.TimeIndex = 0;
            prach.FrequencyIndex = 0;

            % Select the starting symbol within the slot and duration in symbols.
            StartSymbolWithinSlot = mod(prach.SymbolLocation, 14);
            if strcmp(PreambleFormat, 'C0')
                % Undoes MATLAB constrain, explained in nrPRACHConfig help.
                StartSymbolWithinSlot = mod(prach.SymbolLocation * 2, 14);
            end

            % Convert the sampling rate to srsRAN format.
            srsSampleRateString = sprintf('sampling_rate::from_MHz(%.2f)', gridset.Info.SampleRate / 1e6);

            % Write the generated PRACH sequence into a binary file.
            testCase.saveDataFile('_test_input', TestID, ...
                @writeComplexFloatFile, waveform);

            % Write the PRACH symbols into a binary file.
            testCase.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, PRACHSymbols);

            srsPRACHFormat = sprintf('to_prach_format_type("%s")', PreambleFormat);
            Numerology = ['subcarrier_spacing::kHz' num2str(carrier.SubcarrierSpacing)];

            % srsran PRACH configuration
            srsPRACHConfig = {...
                srsPRACHFormat, ...                   % format
                max([1, prach.NumTimeOccasions]), ... % nof_td_occasions
                max([1, NumFreqOccasions]), ...       % nof_fd_occasions
                StartSymbolWithinSlot , ...           % start_symbol
                prach.RBOffset, ...                   % rb_offset
                carrier.NSizeGrid, ...                % nof_prb_ul_grid
                Numerology, ...                       % pusch_scs
                };

            % test context
            srsTestContext = {
                srsSampleRateString, ... % srate
                srsPRACHConfig, ...      % config
                };

            % Generate the test case entry
            testCaseString = testCase.testCaseToString(TestID, ...
                srsTestContext, true, '_test_input', '_test_output');

            % Add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPRACHDemodulatorUnittest

