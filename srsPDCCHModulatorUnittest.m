%srsPDCCHModulatorUnittest Unit tests for PDCCH modulator functions.
%   This class implements unit tests for the PDCCH modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPDCCHModulatorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDCCHModulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pddch_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   nofNCellID       - Number of possible PHY cell identifiers.
%   REGBundleSizes   - Possible REGBundle sizes  for each CORESET Duration.
%   InterleaverSizes - Possible interleaver sizes.
%
%   srsPDCCHModulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDCCHModulatorUnittest Properties (TestParameter):
%
%   Duration         - CORESET Duration.
%   CCEREGMapping    - CCE-to-REG mapping.
%   AggregationLevel - PDCCH aggregation level.
%
%   srsPDCCHModulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDCCHModulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.

classdef srsPDCCHModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdcch_modulator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'

        %Number of possible PHY cell identifiers - NCellID takes values in (0...1007).
        nofNCellID = 1008

        %Possible REGBundle sizes  for each CORESET Duration.
        REGBundleSizes = [[2, 6]; [2, 6]; [3, 6]]

        %Possible interleaver sizes.
        InterleaverSizes = [2, 3, 6]
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pddch_processor' tests will be erased).
        outputPath = {['testPDCCHmodulator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %CORESET duration (1, 2, 3).
        Duration = {1, 2, 3}

        %CCE-to-REG mapping ('noninteleaved', 'interleaved').
        CCEREGMapping = {'noninterleaved', 'interleaved'}

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        AggregationLevel= {1, 2, 4, 8, 16}
    end

    properties (Constant, Hidden)
        randomizeTestvector = randperm(srsPDCCHModulatorUnittest.nofNCellID)
        randomizeSlot = randi([1, 10], 1, srsPDCCHModulatorUnittest.nofNCellID)
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
        function testvectorGenerationCases(testCase, Duration, CCEREGMapping, AggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given CORESET duration,
        %   CCEREGMapping and AggregationLevel, while using randomly generated NCellID,
        %   RNTI and codeword.

            import srsTest.helpers.array2str
            import srsTest.helpers.writeResourceGridEntryFile
            import srsMatlabWrappers.phy.upper.channel_processors.srsPDCCHmodulator
            import srsTest.helpers.writeUint8File
            import srsMatlabWrappers.phy.helpers.srsConfigurePDCCH
            import srsMatlabWrappers.phy.helpers.srsConfigureCORESET
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsTest.helpers.RBallocationMask2string

            % generate a unique test ID
            testID = testCase.generateTestID;

            % use a unique nCellID, nSlot and RNTI for each test
            testCellID = testCase.randomizeTestvector(testID + 1) - 1;
            slotIndex = testCase.randomizeSlot(testID + 1);
            RNTI = randi([0, 65535]);
            maxAllowedStartSymbol = 14 - Duration;
            startSymbolIndex = randi([1, maxAllowedStartSymbol]);
            if strcmp(CCEREGMapping, 'interleaved')
                InterleaverSize = testCase.InterleaverSizes(randi([1, 3]));
                REGBundleSize = testCase.REGBundleSizes(Duration, randi([1, 2]));
            else
                InterleaverSize = 2;
                REGBundleSize = 6;
            end
            % currently fixed to 1 port of random number from [0, 7]
            PDCCHports = randi([0, 7]);
            PDCCHportsStr = ['{', array2str(PDCCHports), '}'];

            % current fixed parameter values (e.g., maximum grid size with current interleaving
            %   configuration, CORESET will use all available frequency resources)
            cyclicPrefix = 'normal';
            NSizeGrid = 52;
            NStartGrid = 0;
            NFrame = 0;
            maxFrequencyResources = floor(NSizeGrid / 6);
            FrequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            SearchSpaceType = 'ue';
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            AllocatedCandidate = 1;
            nID = testCellID;

            % only encode the PDCCH when it fits
            isAggregationOK = (sum(FrequencyResources) * Duration >= AggregationLevel);
            isREGbundleSizeOK = (mod(sum(FrequencyResources) * Duration, InterleaverSize * REGBundleSize) == 0);
            isCCEREGMappingOK = (strcmp(CCEREGMapping, 'noninterleaved') || ...
                (strcmp(CCEREGMapping, 'interleaved') &&  isREGbundleSizeOK));

            if (isAggregationOK && isCCEREGMappingOK)
                % configure the carrier according to the test parameters
                carrier = srsConfigureCarrier(testCellID, 0, NSizeGrid, NStartGrid, ...
                    slotIndex, NFrame, cyclicPrefix);

                % configure the CORESET according to the test parameters
                CORESET = srsConfigureCORESET(FrequencyResources, Duration, ...
                    CCEREGMapping, REGBundleSize, InterleaverSize);

                % configure the PDCCH according to the test parameters
                pdcch = srsConfigurePDCCH(CORESET, NStartBWP, NSizeBWP, RNTI, ...
                    AggregationLevel, SearchSpaceType, AllocatedCandidate, nID);

                % set startSymbol using random value generated above
                pdcch.SearchSpace.StartSymbolWithinSlot = startSymbolIndex;

                % generate random codeword, 54REs per CCE, 2 bits per QPSK symbol
                codeWord = randi([0 1], 54 * 2 * AggregationLevel, 1);

                % write the codeWord to a binary file
                testCase.saveDataFile('_test_input', testID, @writeUint8File, codeWord);

                % call the PDCCH modulator MATLAB functions
                [PDCCHsymbols, symbolIndices] = srsPDCCHmodulator(codeWord, carrier, pdcch, nID, RNTI);
                symbolIndices(:, 3) = int32(PDCCHports);

                % write each complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, PDCCHsymbols, symbolIndices);

                % generate a RB allocation mask string
                rbAllocationMaskStr = RBallocationMask2string(symbolIndices);

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, true, {rbAllocationMaskStr, ...
                                   startSymbolIndex, Duration, nID, RNTI, 1.0, PDCCHportsStr}, true);

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHModulatorUnittest< srsTest.srsBlockUnittest
