%srsPDCCHdmrsUnittest Unit tests for PDCCH DMRS processor functions.
%   This class implements unit tests for the PDCCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPDCCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDCCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pdcch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsPDCCHdmrsUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDCCHdmrsUnittest Properties (TestParameter):
%
%   NCellID          - PHY-layer cell ID (0...1007).
%   NSlot            - Slot index (0...19).
%   RNTI             - Radio network temporary ID (0...65535).
%   numerology       - Defines the subcarrier spacing (0, 1).
%   Duration         - CORESET duration (1, 2, 3).
%   CCEREGMapping    - CCE-to-REG mapping ('interleaved', 'noninteleaved').
%   AggregationLevel - PDCCH aggregation level (1, 2, 4, 8, 16).
%
%   srsPDCCHdmrsUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPBCHdmrsUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%   See also matlab.unittest.

classdef srsPDCCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pdcch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pdcch_processor' tests will be erased).
        outputPath = {['testPDCCHdmrs', datestr(now, 30)]}
    end

    properties (TestParameter)
        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %Slot index (0...19).
        NSlot = num2cell(0:19)

        %Radio network temporary ID (0...65535).
        RNTI = num2cell(0:65535)

        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %CORESET duration (1, 2, 3).
        Duration = {1, 2, 3}

        %CCE-to-REG mapping ('interleaved', 'noninteleaved').
        CCEREGMapping = {'interleaved','noninterleaved'}

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        AggregationLevel= {1, 2, 4, 8, 16}
    end % of properties (TestParameter)

    properties(Constant, Hidden)
        randomizeTestvector = randperm(1008)
        randomizeSlotNum0 = randi([1, 10], 1, 1008)
        randomizeSlotNum1 = randi([1, 20], 1, 1008)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, Duration, CCEREGMapping, AggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given numerology, Duration,
        %   CCEREGMapping and AggregationLevel, while using a random NCellID and a random NSlot.

            import srsTest.helpers.cellarray2str
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigureCORESET
            import srsMatlabWrappers.phy.helpers.srsConfigurePDCCH
            import srsMatlabWrappers.phy.upper.signal_processors.srsPDCCHdmrs
            import srsMatlabWrappers.phy.helpers.srsGetUniqueSymbolsIndices
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.RBallocationMask2string

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % use a unique NCellID, NSlot and rnti for each test
            randomizedCellID = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedCellID};

            if numerology == 0
                randomizedSlot = testCase.randomizeSlotNum0(testID + 1);
            else
                randomizedSlot = testCase.randomizeSlotNum1(testID + 1);
            end
            NSlotLoc = testCase.NSlot{randomizedSlot};

            % current fixed parameter values (e.g., maximum grid size with current interleaving
            % configuration, CORESET will use all available frequency resources)
            NSizeGrid = 216;
            NStartGrid = 0;
            NFrame = 0;
            CyclicPrefix = 'normal';
            maxFrequencyResources = floor(NSizeGrid / 6);
            FrequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            InterleaverSize = 2;
            REGBundleSize = 6;
            SearchSpaceType = 'ue';
            RNTILoc = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            AllocatedCandidate = 1;
            numPorts = 1;
            referencePointKrb = 0;
            startSymbolIndex = 0;
            DMRSScramblingID = NCellIDLoc;
            DMRSamplitude = 1.0;
            PDCCHports = zeros(numPorts, 1);
            PDCCHportsStr = cellarray2str({PDCCHports}, true);

            % only encode the PDCCH when it fits
            isAggregationOK = (sum(FrequencyResources) * Duration >= AggregationLevel);
            isREGbundleSizeOK = (mod(sum(FrequencyResources) * Duration, InterleaverSize * REGBundleSize) == 0);
            isCCEREGMappingOK = (strcmp(CCEREGMapping, 'noninterleaved') || ...
                (strcmp(CCEREGMapping, 'interleaved') &&  isREGbundleSizeOK));

            if (isAggregationOK && isCCEREGMappingOK)

                % configure the carrier according to the test parameters
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(NCellIDLoc, SubcarrierSpacing, NSizeGrid, ...
                    NStartGrid, NSlotLoc, NFrame, CyclicPrefix);

                % configure the CORESET according to the test parameters
                CORESET = srsConfigureCORESET(FrequencyResources, Duration, ...
                    CCEREGMapping, REGBundleSize, InterleaverSize);

                % configure the PDCCH according to the test parameters
                pdcch = srsConfigurePDCCH(CORESET, NStartBWP, NSizeBWP, RNTILoc, ...
                    AggregationLevel, SearchSpaceType, AllocatedCandidate, DMRSScramblingID);

                % call the PDCCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch);

                % put all generated DMRS symbols and indices in a single cell
                [DMRSsymbolsVector, symbolIndicesVector] = ...
                    srsGetUniqueSymbolsIndices(DMRSsymbols, symbolIndices);

                % write each complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile('_test_output', testID, @writeResourceGridEntryFile, ...
                    DMRSsymbolsVector, symbolIndicesVector);

                % generate a 'slot_point' configuration string
                slotPointConfig = cellarray2str({numerology, NFrame, ...
                    floor(NSlotLoc / carrier.SlotsPerSubframe), ...
                    rem(NSlotLoc, carrier.SlotsPerSubframe)}, true);

                % generate a RB allocation mask string
                rbAllocationMask = RBallocationMask2string(symbolIndicesVector);

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, ...
                    {slotPointConfig, ['cyclic_prefix::', upper(CyclicPrefix)], ...
                        referencePointKrb, rbAllocationMask, startSymbolIndex, ...
                        Duration, DMRSScramblingID, DMRSamplitude, PDCCHportsStr}, ...
                        true, '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end % of if (isAggregationOK && isCCEREGMappingOK)
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHdmrsUnittest
