classdef srsPDCCHdmrsUnittest < matlab.unittest.TestCase
%SRSPDCCHDMRSUNITTEST Unit tests for PDCCH DMRS processor functions.
%   This class implements unit tests for the PDCCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = SRSPDCCHDMRSUNITTEST
%   and then running all the tests with
%       testResults = testCase.run
%
%   SRSPDCCHDMRSUNITTEST Properties (TestParameter):
%
%   NCellID          - PHY-layer cell ID (0, ..., 1007).
%   NSlot            - slot index (0, ..., 19).
%   RNTI             - radio network temporary ID (0, ..., 65535)
%   numerology       - defines the subcarrier spacing (0, 1)
%   Duration         - CORESET Duration (1, 2, 3)
%   CCEREGMapping    - CCE-to-REG mapping ('interleaved', 'noninteleaved')
%   AggregationLevel - PDCCH aggregation level (1, 2, 4, 8, 16)
%
%   SRSPDCCHDMRSUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible combinations of numerology,
%                               Duration, CCEREGMapping and AggregationLevel, while using a random
%                               NCellID and NSlot for each test, jointly with some fixed parameters.
%
%   SRSPDCCHDMRSUNITTEST Methods (TestTags = {'srsPHYvalidation'}):
%
%  See also MATLAB.UNITTEST.

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        randomizeTestvector = num2cell(randi([1, 1008], 1, 60));
        randomizeSlotNum0 = num2cell(randi([1, 10], 1, 60));
        randomizeSlotNum1 = num2cell(randi([1, 20], 1, 60));
        NCellID = num2cell(0:1:1007);
        NSlot = num2cell(0:1:19);
        RNTI = num2cell(0:1:65535);
        numerology = {0, 1};
        Duration = {1, 2, 3};
        CCEREGMapping = {'interleaved','noninterleaved'};
        AggregationLevel= {1, 2, 4, 8, 16};
    end

    methods (TestClassSetup)
        function initialize(testCase)
%INITIALIZE Adds the required folders to the MATLAB path and initializes the
%   random seed.

            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, numerology, Duration, CCEREGMapping, AggregationLevel)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible combinations of numerology,
%   Duration, CCEREGMapping and AggregationLevel, while using a random NCellID and NSlot for
%   each test, jointly with some fixed parameters.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_output*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID, NSlot and RNTI for each test
            randomizedCellID = testCase.randomizeTestvector{testID + 1};
            NCellIDLoc = testCase.NCellID{randomizedCellID};
            if numerology == 0
                randomizedSlot = testCase.randomizeSlotNum0{testID + 1};
            else
                randomizedSlot = testCase.randomizeSlotNum1{testID + 1};
            end
            NSlotLoc = testCase.NSlot{randomizedSlot};

            % current fixed parameter values (e.g., maximum grid size with current interleaving
            %   configuration, CORESET will use all available frequency resources)
            NSizeGrid = 216;
            NStartGrid = 0;
            NFrame = 0;
            CyclicPrefix = 'normal';
            maxFrequencyResources = floor(NSizeGrid / 6);
            FrequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            InterleaverSize = 2;
            REGBundleSize = 6;
            SearchSpaceType = 'ue';
            RNTI = 0;
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
                carrier = srsConfigureCarrier(NCellIDLoc, SubcarrierSpacing, NSizeGrid, NStartGrid, NSlotLoc, NFrame, CyclicPrefix);

                % configure the CORESET according to the test parameters
                CORESET = srsConfigureCORESET(FrequencyResources, Duration, CCEREGMapping, REGBundleSize, InterleaverSize);

                % configure the PDCCH according to the test parameters
                pdcch = srsConfigurePDCCH(CORESET, NStartBWP, NSizeBWP, RNTI, AggregationLevel, SearchSpaceType, AllocatedCandidate, DMRSScramblingID);

                % call the PDCCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch);

                % put all generated DMRS symbols and indices in a single cell
                [DMRSsymbolsVector, symbolIndicesVector] = srsGetUniqueSymbolsIndices(DMRSsymbols, symbolIndices);

                % write each complex symbol into a binary file, and the associated indices to another
                testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, DMRSsymbolsVector, symbolIndicesVector);

                % generate a 'slot_point' configuration string
                slotPointConfig = cellarray2str({numerology, NFrame, floor(NSlotLoc / carrier.SlotsPerSubframe), ...
                                                 rem(NSlotLoc, carrier.SlotsPerSubframe)}, true);

                % generate a RB allocation mask string
                rbAllocationMask = RBallocationMask2string(symbolIndicesVector);

                % generate the test case entry
                testCaseString = testImpl.testCaseToString(baseFilename, testID, false, {slotPointConfig, ['cyclic_prefix::', upper(CyclicPrefix)], ...
                                      referencePointKrb, rbAllocationMask, startSymbolIndex, Duration, DMRSScramblingID, DMRSamplitude, PDCCHportsStr}, true);

                % add the test to the file header
                testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
            end
        end
    end
end
