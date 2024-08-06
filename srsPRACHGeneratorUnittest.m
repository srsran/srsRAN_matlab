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

classdef srsPRACHGeneratorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'prach_generator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'prach_generator' tests will be erased).
        outputPath = {['testPRACHGenerator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Carrier duplex, set to
        %   - FDD for paired spectrum with 15kHz subcarrier spacing, or
        %   - TDD for unpaired spectrum with 30kHz subcarrier spacing.
        DuplexMode = {'FDD', 'TDD'}

        %Carrier bandwidth in PRB.
        CarrierBandwidth = {52, 106}

        %Preamble formats.
        PreambleFormat = {'0', '1', '2', '3', 'A1', 'A1/B1', 'A2', ...
            'A2/B2', 'A3', 'A3/B3', 'B1', 'B4', 'C0', 'C2'}

        %Restricted set type.
        %   Possible values are {'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'}.
        RestrictedSet = {'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'}

        %Zero correlation zone, cyclic shift configuration index.
        ZeroCorrelationZone = {0, 5, 12}

        %Starting resource block (RB) index of the initial uplink bandwidth
        %part (BWP) relative to carrier resource grid.
        RBOffset = {0};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsran/phy/upper/channel_processors/prach_generator.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'struct test_case_t {\n'...
                '  prach_generator::configuration config;\n'...
                '  file_vector<cf_t> sequence;\n'...
                '};\n'...
                ]);
        end

    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset)
        %testvectorGenerationCases Generates a test vector for the given
        %DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet,
        %ZeroCorrelationZone and RBOffset. The parameters SequenceIndex
        %and PreambleIndex are generated randomly.

            import srsTest.helpers.writeComplexFloatFile
            import srsLib.phy.helpers.srsConfigurePRACH
            import srsLib.phy.upper.channel_processors.srsPRACHgenerator

            % Generate a unique test ID
            TestID = testCase.generateTestID;

            % Generate carrier configuration
            carrier = nrCarrierConfig;
            carrier.CyclicPrefix = 'normal';
            carrier.NSizeGrid = CarrierBandwidth;

            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    carrier.SubcarrierSpacing = 15;
                case 'TDD'
                    carrier.SubcarrierSpacing = 30;
                otherwise
                    error('Invalid duplex mode %s', DuplexMode);
            end

            % Generate PRACH configuration.
            sequenceIndex = randi([0, 1023], 1, 1);
            preambleIndex = randi([0, 63], 1, 1);
            prach = srsConfigurePRACH(PreambleFormat, ...
                DuplexMode=DuplexMode, ...
                SubcarrierSpacing=carrier.SubcarrierSpacing, ...
                SequenceIndex=sequenceIndex, ...
                PreambleIndex=preambleIndex, ...
                RestrictedSet=RestrictedSet, ...
                ZeroCorrelationZone=ZeroCorrelationZone, ...
                RBOffset=RBOffset ...
                );

            % Generate waveform
            [~, ~, info] = srsPRACHgenerator(carrier, prach);

            % Write the generated PRACH sequence into a binary file
            testCase.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, info.PRACHSymbols(1:prach.LRA));

            srsPRACHFormat = sprintf('to_prach_format_type("%s")', prach.Format);

            switch prach.RestrictedSet
                case 'UnrestrictedSet'
                    srsRestrictedSet = 'restricted_set_config::UNRESTRICTED';
                case 'RestrictedSetTypeA'
                    srsRestrictedSet = 'restricted_set_config::TYPE_A';
                case 'RestrictedSetTypeB'
                    srsRestrictedSet = 'restricted_set_config::TYPE_B';
                otherwise
                    error('Invalid restricted set %s', prach.RestrictedSet);
            end

            % srsran PRACH configuration
            srsPRACHConfig = {...
                srsPRACHFormat, ...            % format
                prach.SequenceIndex, ...       % root_sequence_index
                prach.PreambleIndex, ...       % preamble_index
                srsRestrictedSet, ...          % restricted_set
                prach.ZeroCorrelationZone, ... % zero_correlation_zone
                };

            % Generate the test case entry
            testCaseString = testCase.testCaseToString(TestID, ...
                srsPRACHConfig, true, '_test_output');

            % Add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPRACHGeneratorUnittest
