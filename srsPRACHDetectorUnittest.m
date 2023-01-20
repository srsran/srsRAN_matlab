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
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsPRACHDetectorUnittest Methods (TestTags = {'testmex'}):
%
%   mexTest  - Tests the mex wrapper of the SRSGNB PRACH detector.
%
%   srsPRACHDetectorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPRACHDetectorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block. It should be noted that the 'testvector'
        %   generation method is conforming the testvectors naming and data
        %   structuring to that of 'srsPRACHGeneratorUnittest', taking into
        %   account that the 'prach_detector_vectortest' test application
        %   of SRSGNB has been implemented to reuse the testvectors that it
        %   produces. Hence 'srsBlock' is not set to 'prach_detector' as it
        %   would be usually done.
        srsBlock = 'prach_generator'

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
	    RBOffset = {0, 13, 28};
    end

    properties (Constant, Hidden)
        % Currently fixed parameter values (e.g., XXX)

        %TBD: Fill or remove.

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
                '#include "srsgnb/phy/upper/channel_processors/prach_generator.h"\n'...
                '#include "srsgnb/support/file_vector.h"\n'...
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

            import srsMatlabWrappers.phy.helpers.srsSelectPRACHConfigurationIndex
        
            % Generate carrier configuration.
            obj.carrier = nrCarrierConfig;
            obj.carrier.CyclicPrefix = 'normal';
            obj.carrier.NSizeGrid = CarrierBandwidth;
    
            % Generate PRACH configuration.
            obj.prach = nrPRACHConfig;
            obj.prach.DuplexMode = DuplexMode;
            obj.prach.SequenceIndex = randi([0, 1023], 1, 1);%834;
            obj.prach.PreambleIndex = randi([0, 63], 1, 1);%57;
            obj.prach.RestrictedSet = RestrictedSet;
            obj.prach.ZeroCorrelationZone = ZeroCorrelationZone;
            obj.prach.RBOffset = RBOffset;
    
            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    obj.carrier.SubcarrierSpacing = 15;
                    ConfigurationsTable = obj.prach.Tables.ConfigurationsFR1PairedSUL;
                case 'TDD'
                    obj.carrier.SubcarrierSpacing = 30;
                    ConfigurationsTable = obj.prach.Tables.ConfigurationsFR1Unpaired;
                otherwise
                    error('Invalid duplex mode %s', DuplexMode);
            end
            obj.prach.ConfigurationIndex = srsSelectPRACHConfigurationIndex(ConfigurationsTable, PreambleFormat);
    
            % Select PRACH subcarrier spacing from the selected format.
            switch PreambleFormat
                case '0'
                    obj.prach.SubcarrierSpacing = 1.25;
                    obj.prach.LRA = 839;
                case '1'
                    obj.prach.SubcarrierSpacing = 1.25;
                    obj.prach.LRA = 839;
                case '2'
                    obj.prach.SubcarrierSpacing = 1.25;
                    obj.prach.LRA = 839;
                case '3'
                    obj.prach.SubcarrierSpacing = 5;
                    obj.prach.LRA = 839;
                otherwise
                    error('Preamble format %s not implemented.', PreambleFormat);
            end
        end % of function setupsimulation(obj, SymbolAllocation, PRBAllocation, mcs)
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset)
        %testvectorGenerationCases Generates a test vector for the given 
        %   DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet,
        %   ZeroCorrelationZone and RBOffset. The parameters SequenceIndex
        %   and PreambleIndex are generated randomly.
        %   It should be noted that the generated testvectors will conform
        %   to the naming and data structuring of 'srsPRACHGeneratorUnittest',
        %   taking into account that the 'prach_detector_vectortest' test 
        %   application of SRSGNB has been implemented to reuse the 
        %   testvectors that it produces.

            import srsTest.helpers.writeComplexFloatFile
            import srsMatlabWrappers.phy.upper.channel_processors.srsPRACHgenerator
            import srsMatlabWrappers.phy.upper.channel_processors.srsPRACHdemodulator
            
            % Generate a unique test ID.
            TestID = obj.generateTestID;
            
            % Configure the test.
            setupsimulation(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset);

            % Generate waveform.
            [waveform, gridset, info] = srsPRACHgenerator(obj.carrier, obj.prach);

            % Remove the time offset.
            if gridset.Info.OffsetLength
                waveform = waveform(gridset.Info.OffsetLength+1:end);
            end

            % Demodulate the PRACH signal.
            PRACHSymbols = srsPRACHdemodulator(obj.carrier, obj.prach, gridset, waveform, info);

            % Write the generated PRACH sequence into a binary file.
            obj.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, PRACHSymbols);

            % Prepare the test header file.
            srsPRACHFormat = ['preamble_format::FORMAT', obj.prach.Format];

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

            % srsgnb PRACH configuration.
            srsPRACHConfig = {...
                srsPRACHFormat, ...            % format
                obj.prach.SequenceIndex, ...       % root_sequence_index
                obj.prach.PreambleIndex, ...       % preamble_index
                srsRestrictedSet, ...          % restricted_set
                obj.prach.ZeroCorrelationZone, ... % zero_correlation_zone
                };

            % Generate the test case entry.
            testCaseString = obj.testCaseToString(TestID, ...
                srsPRACHConfig, true, '_test_output');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, DuplexMode, CarrierBandwidth, PreambleFormat, RestrictedSet, ZeroCorrelationZone, RBOffset)
        %mexTest  Tests the mex wrapper of the SRSGNB PUSCH decoder.
        %   mexTest(OBJ, DUPLEXMODE, CARRIERBANDWIDTH, PREAMBLEFORMAT, 
        %   RESTRICTEDSET, ZEROCORRELATIONZONE, RBOFFSET) runs a short 
        %   simulation with an UL transmission using a carrier with duplex
        %   mode DUPLEXMODE and a bandiwth of CARRIERBANDWITH PRBs. This
        %   transmision comprises a PRACH signal using preamble format 
        %   PREAMBLEFORMAT, restricted set configuration RESTRICTEDSET, 
        %   cyclic shift index configuration ZEROCORRELATIONINDEX and a RB
        %   offset RBOFFSET. The PRACH transmission is demodulated in 
        %   Matlab and PRACH detection is then performed using the mex 
        %   wraper of the SRSGNB C++ component. The test is considered
        %   as passed if the detected PRACH is equal to the transmitted one.

        %TBD: Add implementation.

        end % of function mextest
    end % of methods (Test, TestTags = {'testmex'})
end % of classdef srsPUSCHDecoderUnittest
