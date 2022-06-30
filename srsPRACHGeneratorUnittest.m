%srsPRACHGeneratorUnittest Unit tests for PRACH waveform generator.
%   This class implements unit tests for the PRACH waveform generator
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with
%       testCase = srsPRACHGeneratorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPRACHGeneratorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'prach_generator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPRACHGeneratorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPRACHGeneratorUnittest Properties (TestParameter):
%
%   DuplexMode          - Duplexing mode FDD or TDD.
%   CarrierBandwidth    - Carrier bandwidth in PRB.
%   PreambleFormat      - Indicates the preamble format to generate.
%   RestrictedSet       - Selects the restricted set.
%   ZeroCorrelationZone - Cyclic shift configuration index {0, 15}.
%   RBOffset            - Indicates the frequency domain sequence mapping.
%  
%   srsPRACHGeneratorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsPRACHGeneratorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPRACHGeneratorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'prach_generator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'prach_generator' tests will be erased).
        outputPath = {['testPRACHGenerator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Carrier duplex, set to
        %   - FDD for paired spectrum with 15kHz subcarrier spacing, or
        %   - TDD for unpaired spectrum with 30kHz subcarrier spacing.
        DuplexMode = {'FDD', 'TDD'}

        %Carrier bandwidth in PRB.
        CarrierBandwidth = {52, 106}

        %Preamble formats.
        PreambleFormat = {'0', '1', '2', '3'}

        %Selects the restricted set, possible values are
        %{'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'}
        RestrictedSet = {'UnrestrictedSet'}

        % Zero correlation zone, cyclic shift configuration index.
        ZeroCorrelationZone = {0, 5, 12}

        % Starting resource block (RB) index of the initial uplink
        % bandwidth part (BWP) relative to carrier resource grid. 
        RBOffset = {0, 1, 2, 13};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsgnb/phy/upper/channel_processors/prach_generator.h"\n'...
                '#include "srsgnb/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'struct prach_context {\n'...
                '  unsigned nof_prb_ul_grid;\n'...
                '  unsigned dft_size_15kHz;\n'...
                '  prach_generator::configuration config;\n'...
                '};\n'...
                '\n'...
                'struct test_case_t {\n'...
                '  prach_context context;\n'...
                '  file_vector<cf_t> sequence;\n'...
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
        % DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet,
        % ZeroCorrelationZone and RBOffset. The parameters SequenceIndex
        % and PreambleIndex are generated randomly.

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
                    error('Preamble format %s not implemented.', PreambleFormat);
            end

            % Generate waveform
            [waveform, gridset] = srsPRACHgenerator(carrier, prach);

            % Remove time offset
            if gridset.Info.OffsetLength
                waveform = waveform(gridset.Info.OffsetLength+1:end);
            end

            % Calculate the DFT size for 15kHz SCS
            dftSize15kHz = gridset.Info.SampleRate / 15e3;

            % Write the generated PRACH sequence into a binary file
            testCase.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, waveform);

            srsPRACHFormat = ['preamble_format::FORMAT', prach.Format];

            switch prach.RestrictedSet
                case 'UnrestrictedSet'
                    srsRestrictedSet = 'restricted_set_config::UNRESTRICTED';
                case 'RestrictedSetTypeA'
                    srsRestrictedSet = 'restricted_set_config::TYPE_A';
                case 'RestrictedSetTypeB'
                    srsRestrictedSet = 'restricted_set_config::TYPE_B';
            end

            Numerology = ['subcarrier_spacing::kHz' num2str(carrier.SubcarrierSpacing)];

            % srsgnb PRACH configuration
            srsPRACHConfig = {...
                srsPRACHFormat, ...            % format
                prach.SequenceIndex, ...       % root_sequence_index
                prach.PreambleIndex, ...       % preamble_index
                srsRestrictedSet, ...          % restricted_set
                prach.ZeroCorrelationZone, ... % zero_correlation_zone
                prach.RBOffset, ...            % rb_offset
                Numerology, ...                % pusch_scs
                };

            % test context
            srsTestContext = {
                carrier.NSizeGrid, ... % nof_prb_ul_grid
                dftSize15kHz, ...      % dft_size_15kHz
                srsPRACHConfig, ...    % config
                };

            % Generate the test case entry
            testCaseString = testCase.testCaseToString(TestID, ...
                srsTestContext, true, '_test_output');

            % Add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPRACHGeneratorUnittest

function ConfigurationIndex = selectConfigurationIndex(ConfigurationsTable, PreambleFormat)
%selectConfigurationIndex selects a valid configuration index.
%   CONFIGURATIONINDEX = selectConfigurationIndex(CONFIGURATIONSTABLE, PREAMBLEFORMAT)
%   Gets the first configuration index CONFIGURATIONINDEX in a configurations table  CONFIGURATIONSTABLE with the
%   given preamble format PREAMBLEFORMAT.
  for rowIndex=1:height(ConfigurationsTable)
      if ConfigurationsTable.PreambleFormat{rowIndex} == PreambleFormat
          ConfigurationIndex = ConfigurationsTable.ConfigurationIndex(rowIndex);
          return;
      end
  end
end
