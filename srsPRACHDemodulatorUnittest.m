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
%  See also matlab.unittest.
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
        CarrierBandwidth = {52, 79, 106}

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
        RBOffset = {0, 13, 28};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsran/phy/lower/modulation/ofdm_prach_demodulator.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'struct prach_context {\n'...
                '  unsigned dft_size_15kHz;\n'...
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
            import srsMatlabWrappers.phy.upper.channel_processors.srsPRACHgenerator

            % Generate a unique test ID
            TestID = testCase.generateTestID;
            
            % Generate carrier configuration
            carrier = nrCarrierConfig;
            carrier.CyclicPrefix = 'normal';
            carrier.NSizeGrid = CarrierBandwidth;

            % Generate PRACH configuration
            prach = nrPRACHConfig;
            prach.DuplexMode = DuplexMode;
            prach.SequenceIndex = randi([0, 1023], 1, 1);
            prach.PreambleIndex = randi([0, 63], 1, 1);
            prach.RestrictedSet = RestrictedSet;
            prach.ZeroCorrelationZone = ZeroCorrelationZone;
            prach.RBOffset = RBOffset;

            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    carrier.SubcarrierSpacing = 15;
                    ConfigurationsTable = prach.Tables.ConfigurationsFR1PairedSUL;
                case 'TDD'
                    carrier.SubcarrierSpacing = 30;
                    ConfigurationsTable = prach.Tables.ConfigurationsFR1Unpaired;
                otherwise
                    error('Invalid duplex mode %s', DuplexMode);
            end
            prach.ConfigurationIndex = selectConfigurationIndex(ConfigurationsTable, PreambleFormat);

            % Select PRACH subcarrier spacing from the selected format.
            switch PreambleFormat
                case '0'
                    prach.SubcarrierSpacing = 1.25;
                    prach.LRA = 839;
                case '1'
                    prach.SubcarrierSpacing = 1.25;
                    prach.LRA = 839;
                case '2'
                    prach.SubcarrierSpacing = 1.25;
                    prach.LRA = 839;
                case '3'
                    prach.SubcarrierSpacing = 5;
                    prach.LRA = 839;
                otherwise
                    prach.SubcarrierSpacing = carrier.SubcarrierSpacing;
                    prach.LRA = 139;
                    if strcmp(DuplexMode, 'TDD')
                        prach.ActivePRACHSlot = 1;
                    end
            end

            % Generate waveform
            [waveform, gridset, info] = srsPRACHgenerator(carrier, prach);

            % Remove time offset
            if gridset.Info.OffsetLength
                waveform = waveform(gridset.Info.OffsetLength+1:end);
            end

            % Calculate the DFT size for 15kHz SCS
            dftSize15kHz = gridset.Info.SampleRate / 15e3;

            % Write the generated PRACH sequence into a binary file
            testCase.saveDataFile('_test_input', TestID, ...
                @writeComplexFloatFile, waveform);

            % Write the PRACH symbols into a binary file
            testCase.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, info.PRACHSymbols);


            srsPRACHFormat = sprintf('to_prach_format_type("%s")', prach.Format);
            Numerology = ['subcarrier_spacing::kHz' num2str(carrier.SubcarrierSpacing)];

            % srsran PRACH configuration
            srsPRACHConfig = {...
                srsPRACHFormat, ...    % format
                prach.RBOffset, ...    % rb_offset
                carrier.NSizeGrid, ... % nof_prb_ul_grid
                Numerology, ...        % pusch_scs
                };

            % test context
            srsTestContext = {
                dftSize15kHz, ...      % dft_size_15kHz
                srsPRACHConfig, ...    % config
                };

            % Generate the test case entry
            testCaseString = testCase.testCaseToString(TestID, ...
                srsTestContext, true, '_test_input', '_test_output');

            % Add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPRACHDemodulatorUnittest

function ConfigurationIndex = selectConfigurationIndex(ConfigurationsTable, PreambleFormat)
%selectConfigurationIndex selects a valid configuration index.
%   CONFIGURATIONINDEX = selectConfigurationIndex(CONFIGURATIONSTABLE, PREAMBLEFORMAT)
%   Gets the first configuration index CONFIGURATIONINDEX in a configurations table  CONFIGURATIONSTABLE with the
%   given preamble format PREAMBLEFORMAT.
  for rowIndex = 1:height(ConfigurationsTable)
      if strcmp(ConfigurationsTable.PreambleFormat{rowIndex}, PreambleFormat)
          ConfigurationIndex = ConfigurationsTable.ConfigurationIndex(rowIndex);
          return;
      end
  end
end
