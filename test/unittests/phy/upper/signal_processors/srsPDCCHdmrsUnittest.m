classdef srsPDCCHdmrsUnittest < matlab.unittest.TestCase
%SRSPBCHDMRSUNITTEST Unit tests for PDCCH DMRS processor functions.
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
%   rnti             - radio network temporary ID (0, ..., 65535)
%   numerology       - defines the subcarrier spacing (0, 1)
%   duration         - CORESET duration (1, 2, 3)
%   CCEREGMapping    - CCE-to-REG mapping ('interleaved', 'noninteleaved')
%   aggregationLevel - PDCCH aggregation level (1, 2, 4, 8, 16)
%
%   SRSPDCCHDMRSUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible combinations of numerology,
%                               duration, CCEREGMapping and aggregationLevel, while using a random
%                               NCellID and NSlot for each test, jointly with some fixed parameters.
%
%   SRSPBCHMODULATORUNITTEST Methods (TestTags = {'srsPHYvalidation'}):
%
%  See also MATLAB.UNITTEST.
%  SRSPBCHDMRSUNITTEST Methods:
%    The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%      * testvectorGenerationCases - generates testvectors for all possible combinations of numerology,
%                                    duration, CCEREGMapping and aggregationLevel, while using a random
%                                    NCellID and NSlot for each test, jointly with some fixed parameters.
%
%    The following methods are available for the SRS PHY validation tests (TestTags = {'srsPHYvalidation'}):
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
        rnti = num2cell(0:1:65535);
        numerology = {0, 1};
        duration = {1, 2, 3};
        CCEREGMapping = {'interleaved','noninterleaved'};
        aggregationLevel= {1, 2, 4, 8, 16};
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
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, numerology, duration, CCEREGMapping, aggregationLevel)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible combinations of numerology,
%   duration, CCEREGMapping and aggregationLevel, while using a random NCellID and NSlot for
%   each test, jointly with some fixed parameters.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_output*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID, NSlot and rnti for each test
            randomizedCellID = testCase.randomizeTestvector{testID+1};
            NCellIDLoc = testCase.NCellID{randomizedCellID};
            if numerology == 0
                randomizedSlot = testCase.randomizeSlotNum0{testID+1};
            else
                randomizedSlot = testCase.randomizeSlotNum1{testID+1};
            end
            NSlotLoc = testCase.NSlot{randomizedSlot};

            % current fixed parameter values (e.g., maximum grid size with current interleaving
            %   configuration, CORESET will use all available frequency resources)
            NSizeGrid = 216;
            NStartGrid = 0;
            NFrame = 0;
            cyclicPrefix = 'normal';
            maxFrequencyResources = floor(NSizeGrid / 6);
            frequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            interleaverSize = 2;
            REGBundleSize = 6;
            searchSpaceType = 'ue';
            rnti = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            allocatedCandidate = 1;
            numPorts = 1;
            referencePointKrb = 0;
            startSymbolIndex = 0;
            nID = NCellIDLoc;
            DMRSamplitude = 1;
            PDCCHports = zeros(numPorts, 1);
            PDCCHportsStr = array2str(PDCCHports);

            % only encode the PDCCH when it fits
            if sum(frequencyResources) * duration >= aggregationLevel && ...
               (strcmp(CCEREGMapping, 'noninterleaved') || ...
                (strcmp(CCEREGMapping, 'interleaved') && mod(sum(frequencyResources) * duration, interleaverSize * REGBundleSize) == 0))
                % configure the carrier according to the test parameters
                carrier = srsConfigureCarrier(NCellIDLoc, numerology, NSizeGrid, NStartGrid, NSlotLoc, NFrame, cyclicPrefix);

                % configure the CORESET according to the test parameters
                coreset = srsConfigureCORESET(frequencyResources, duration, CCEREGMapping, REGBundleSize, interleaverSize);

                % configure the PDCCH according to the test parameters
                pdcch = srsConfigurePDCCH(coreset, NStartBWP, NSizeBWP, rnti, aggregationLevel, searchSpaceType, allocatedCandidate, nID);

                % call the PDCCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch);

                % put all generated DMRS symbols and indices in a single cell
                [DMRSsymbolsVector, symbolIndicesVector] = srsGetUniqueSymbolsIndices(DMRSsymbols, symbolIndices);

                % write each complex symbol into a binary file, and the associated indices to another
                testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, DMRSsymbolsVector, symbolIndicesVector);

                % generate a 'slot_point' configuration string
                slotPointConfig = generateSlotPointConfigString(numerology, NFrame, NSlotLoc, carrier.SlotsPerSubframe);

                % generate a RB allocation mask string
                rbAllocationMask = generateRBallocationMaskString(symbolIndicesVector);

                % generate the test case entry
                testCaseString = testImpl.testCaseToString('{{%s}, cyclic_prefix::%s, %d, {%s}, %d, %d, %d, %.1f, {%s}}', baseFilename, testID, false, slotPointConfig, ...
                                                          upper(cyclicPrefix), referencePointKrb, rbAllocationMask, startSymbolIndex, duration, nID, DMRSamplitude, PDCCHportsStr);

                % add the test to the file header
                testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
            end
        end
    end
end
