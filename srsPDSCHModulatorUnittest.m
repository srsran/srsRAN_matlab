%srsPDSCHModulatorUnittest Unit tests for PDSCH symbol modulator functions.
%   This class implements unit tests for the PDSCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPDSCHModulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPDSCHModulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdsch_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPDSCHModulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHModulatorUnittest Properties (TestParameter):
%
%   SymbolAllocation       - Symbols allocated to the PDSCH transmission.
%   Modulation             - Modulation scheme.
%   DMRSAdditionalPosition - Number of DMRS additional positions.
%
%   srsPDSCHModulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsPDSCHModulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPDSCHModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdsch_modulator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pdsch_modulator' tests will be erased).
        outputPath = {['testPDSCHModulator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Symbols allocated to the PDSCH transmission. The symbol allocation is described
        %   by a two-elemnt array with the starting symbol (0...13) and the length (1...14)
        %   of the PDSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %Modulation scheme ('QPSK', '16QAM', '64QAM', '256QAM').
        Modulation = {'QPSK', '16QAM', '64QAM', '256QAM'}

        %Number of DMRS additional positions (0, 1, 2, 3).
        DMRSAdditionalPosition = {0, 1, 2, 3}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYchproc(obj, fileID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, Modulation, ...
                DMRSAdditionalPosition)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme and DMRSAdditionalPosition. Other parameters (e.g., the RNTI)
        %   are generated randomly.

            % Generate a unique test ID
            testID = testCase.generateTestID;

            % Generate default carrier configuration
            carrier = nrCarrierConfig;

            % configure the PDSCH DMRS symbols according to the test parameters
            import srsMatlabWrappers.phy.helpers.srsConfigurePDSCHdmrs
            DMRS = srsConfigurePDSCHdmrs(DMRSAdditionalPosition);

            % configure the PDSCH according to the test parameters
            import srsMatlabWrappers.phy.helpers.srsConfigurePDSCH
            pdsch = srsConfigurePDSCH(SymbolAllocation, Modulation);

            % Set randomized values
            pdsch.NID = randi([1, 1023]);
            pdsch.RNTI = randi([1, 65535]);

            if iscell(pdsch.Modulation)
                error('Unsupported');
            else
                switch pdsch.Modulation
                    case 'QPSK'
                        modOrder1 = 2;
                        modString1 = 'modulation_scheme::QPSK';
                    case '16QAM'
                        modOrder1 = 4;
                        modString1 = 'modulation_scheme::QAM16';
                    case '64QAM'
                        modOrder1 = 6;
                        modString1 = 'modulation_scheme::QAM64';
                    case '256QAM'
                        modOrder1 = 8;
                        modString1 = 'modulation_scheme::QAM256';
                end
                modOrder2 = modOrder1;
                modString2 = modString1;
            end


            % Calculate number of encoded bits
            nBits = length(nrPDSCHIndices(carrier, pdsch)) * modOrder1;

            % Generate codewords
            cws = randi([0,1], nBits, 1);

            % write the BCH cw to a binary file
            import srsTest.helpers.writeUint8File
            testCase.saveDataFile('_test_input', testID, @writeUint8File, cws);

            % call the PDSCH symbol modulation Matlab functions
            import srsMatlabWrappers.phy.upper.channel_processors.srsPDSCHmodulator
            [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws);

            % write each complex symbol into a binary file, and the associated indices to another
            import srsTest.helpers.writeResourceGridEntryFile
            testCase.saveDataFile('_test_output', testID, ...
                @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            % Generate DMRS symbol mask
            import srsMatlabWrappers.phy.upper.signal_processors.srsPDSCHdmrs
            [~, symbolIndices] = srsPDSCHdmrs(carrier, pdsch);
            import srsTest.helpers.symbolAllocationMask2string
            dmrsSymbolMask = symbolAllocationMask2string(symbolIndices);

            reserved_str = '{}';

            ports_str = '{0}';

            import srsTest.helpers.array2str
            rb_allocation_str = ['rb_allocation({', array2str(pdsch.PRBSet), '}, vrb_to_prb_mapping_type::NON_INTERLEAVED)'];

            dmrs_type_str = sprintf('dmrs_type::TYPE%d', pdsch.DMRS.DMRSConfigurationType);

            config = [ {pdsch.RNTI}, {carrier.NSizeGrid}, {carrier.NStartGrid}, ...
                {modString1}, {modString1}, {rb_allocation_str}, {pdsch.SymbolAllocation(1)}, ...
                {pdsch.SymbolAllocation(2)}, {dmrsSymbolMask}, {dmrs_type_str}, ...
                {pdsch.DMRS.NumCDMGroupsWithoutData}, {pdsch.NID}, {1}, {reserved_str}, {0}, {ports_str}];

            testCaseString = testCase.testCaseToString(testID, true, config, true);

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHModulatorUnittest