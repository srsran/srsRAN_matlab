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
%  See also matlab.unittest.
classdef srsPUSCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pusch_estimator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (Constant, Hidden)
        norNCellID = 1008
        randomizeTestvector = randperm(srsPUSCHdmrsUnittest.norNCellID);
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
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.


            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/signal_processors/dmrs_pusch_estimator.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  dmrs_pusch_estimator::configuration                     config;\n');
	    fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');
	    fprintf(fileID, '};\n');
	end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, NumLayers, ...
                DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, DMRSConfigurationType)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength and
        %   DMRSConfigurationType. NCellID, NSlot and PRB are randomly generated.

            import srsTest.helpers.cellarray2str
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCHdmrs
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.upper.signal_processors.srsPUSCHdmrs
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.RBallocationMask2string

            % generate a unique test ID
            testID = testCase.generateTestID;

            % use a unique NCellID, NSlot, scrambling ID and PRB allocation for each test
            NCellID = testCase.randomizeTestvector(testID + 1) - 1;
            if numerology == 0
                NSlot = randi([0, 9]);
            else
                NSlot = randi([0, 19]);
            end
            NSCID = randi([0, 1]);
            PRBstart = randi([0, 136]);
            PRBend = randi([136, 271]);

            % current fixed parameter values (e.g., number of CDM groups without data)
            NSizeGrid = 272;
            NStartGrid = 0;
            NFrame = 0;
            CyclicPrefix = 'normal';
            RNTI = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            NIDNSCID = NCellID;
            NID = NCellID;
            Modulation = '16QAM';
            MappingType = 'A';
            SymbolAllocation = [1 13];
            PRBSet = PRBstart:PRBend;
            amplitude = 0.5;
            PUSCHports = 0:(NumLayers-1);

            % skip those invalid configuration cases
            isDMRSLengthOK = (DMRSLength == 1 || DMRSAdditionalPosition < 2);
            if isDMRSLengthOK
                % configure the carrier according to the test parameters
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, ...
                    NSizeGrid, NStartGrid, NSlot, NFrame, CyclicPrefix);

                % configure the PUSCH DMRS symbols according to the test parameters
                DMRS = srsConfigurePUSCHdmrs(DMRSConfigurationType, ...
                    DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, ...
                    NIDNSCID, NSCID);

                % configure the PUSCH according to the test parameters
                pusch = srsConfigurePUSCH(DMRS, NStartBWP, NSizeBWP, NID, RNTI, ...
                    Modulation, NumLayers, MappingType, SymbolAllocation, PRBSet);

                % call the PUSCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPUSCHdmrs(carrier, pusch);

                % write each complex symbol and their associated indices into a binary file.
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, amplitude * DMRSsymbols, symbolIndices);

                % generate a 'slot_point' configuration string
                slotPointConfig = cellarray2str({numerology, NFrame, ...
                    floor(NSlot / carrier.SlotsPerSubframe), ...
                    rem(NSlot, carrier.SlotsPerSubframe)}, true);

                % DMRS type
                DmrsTypeStr = ['dmrs_type::TYPE', num2str(DMRSConfigurationType)];

                % Cyclic Prefix.
		cyclicPrefixStr = 'cyclic_prefix::NORMAL';

                % generate a symbol allocation mask string
                symbolAllocationMask = symbolAllocationMask2string(symbolIndices);

                % generate a RB allocation mask string
                rbAllocationMask = RBallocationMask2string(PRBstart, PRBend);


                % Prepare DMRS configuration cell
		dmrsConfigCell = { ...
			slotPointConfig, ...  % slot
			DmrsTypeStr, ...      % type
                        NIDNSCID, ...         % Scrambling_id
			NSCID, ...            % n_scid
			amplitude, ...        % scaling
                        cyclicPrefixStr, ...  % c_prefix
                        symbolAllocationMask, ... % symbol_mask
			rbAllocationMask, ... % rb_mask
			pusch.SymbolAllocation(1), ... % first_symbol
			pusch.SymbolAllocation(2), ... % nof_symbols
			NumLayers, ...        % nof_tx_layers
			{PUSCHports}, ...       % rx_ports
			};

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, dmrsConfigCell, ...
                        true, '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHdmrsUnittest
