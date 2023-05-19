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
%   SymbolAllocation  - Symbols allocated to the PDSCH transmission.
%   Modulation        - Modulation scheme.
%
%   srsPDSCHModulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
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
        outputPath = {['testPDSCHModulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Symbols allocated to the PDSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PDSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %Modulation scheme ('QPSK', '16QAM', '64QAM', '256QAM').
        Modulation = {'QPSK', '16QAM', '64QAM', '256QAM'}
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
        function testvectorGenerationCases(testCase, SymbolAllocation, Modulation)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme. Other parameters (e.g., the RNTI)
        %   are generated randomly.

            import srsLib.phy.helpers.srsConfigurePDSCHdmrs
            import srsLib.phy.helpers.srsConfigurePDSCH
            import srsLib.phy.helpers.srsGetBitsSymbol
            import srsLib.phy.helpers.srsModulationFromMatlab
            import srsLib.phy.upper.channel_processors.srsPDSCHmodulator
            import srsLib.phy.upper.signal_processors.srsPDSCHdmrs
            import srsTest.helpers.array2str
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeUint8File

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate default carrier configuration.
            carrier = nrCarrierConfig;

            % Configure the PDSCH according to the test parameters.
            pdsch = srsConfigurePDSCH(SymbolAllocation, Modulation);

            % Set randomized values.
            pdsch.NID = randi([1, 1023]);
            pdsch.RNTI = randi([1, 65535]);

            modOrder1 = srsGetBitsSymbol(pdsch.Modulation);
            modString1 = srsModulationFromMatlab(pdsch.Modulation, 'full');


            % Calculate number of encoded bits.
            nBits = length(nrPDSCHIndices(carrier, pdsch)) * modOrder1;

            % Generate codewords.
            cws = randi([0,1], nBits, 1);

            % Write the DLSCH cw to a binary file.
            testCase.saveDataFile('_test_input', testID, @writeUint8File, cws);

            % Call the PDSCH symbol modulation Matlab functions.
            [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws);

            % Write each complex symbol into a binary file, and the associated indices to another.
            testCase.saveDataFile('_test_output', testID, ...
                @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            % Generate DMRS symbol mask.
            [~, symbolIndices] = srsPDSCHdmrs(carrier, pdsch);
            dmrsSymbolMask = symbolAllocationMask2string(symbolIndices);

            % Generate the test case entry.
            reservedString = '{}';

            portsString = '{0}';

            RBAllocationString = rbAllocationIndexes2String(pdsch.PRBSet);

            DMRSTypeString = sprintf('dmrs_type::TYPE%d', pdsch.DMRS.DMRSConfigurationType);

            config = [ {pdsch.RNTI}, {carrier.NSizeGrid}, {carrier.NStartGrid}, ...
                {modString1}, {modString1}, {RBAllocationString}, {pdsch.SymbolAllocation(1)}, ...
                {pdsch.SymbolAllocation(2)}, {dmrsSymbolMask}, {DMRSTypeString}, ...
                {pdsch.DMRS.NumCDMGroupsWithoutData}, {pdsch.NID}, {1}, {reservedString}, {0}, {portsString}];

            testCaseString = testCase.testCaseToString(testID, config, true, ...
                '_test_input', '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHModulatorUnittest
