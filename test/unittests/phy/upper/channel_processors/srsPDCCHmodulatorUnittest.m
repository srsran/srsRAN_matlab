classdef srsPDCCHmodulatorUnittest < matlab.unittest.TestCase
%srsPDCCHmodulatorUnittest Unit tests for PDCCH modulator functions.
%   This class implements unit tests for the PDCCH processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = SRSPDCCHDMRSUNITTEST
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDCCHmodulatorUnittest properties, randomly chosen in every test case:
%
%   NCellID          - PHY-layer cell ID (0, ..., 1007).
%   NSlot            - slot index (0, ..., 10).
%   rnti             - radio network temporary ID (0, ..., 65535)
%   port             - port index used for PDCCH transmission (0, ..., 7).
%   interleaverSize  - interleaver size used in a CORESET mapping {2, 3, 6}.
%   REGbundleSize    - REG bundle size used in a CORESET mapping {Ns, 6}, where Ns is a CORESET duration
%
%   srsPDCCHmodulatorUnittest test properties:
%
%   duration         - CORESET duration (1, 2, 3)
%   CCEREGMapping    - CCE-to-REG mapping ('noninteleaved', 'interleaved')
%   aggregationLevel - PDCCH aggregation level (1, 2, 4, 8, 16)
%
%   SRSPDCCHDMRSUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               registers callback action performed on a test teardown.
%   testvectorGenerationCases - Generates test vectors for all possible combinations of CORESET duration,
%                               CORESET CCEREGMapping and aggregationLevel, while using a random
%                               parameters as described above.
%
%   srsPDCCHmodulatorUnittest Methods (TestTags = {'srsPHYvalidation'}):
%
%  See also MATLAB.UNITTEST.

    properties
        randomizeTestvector = num2cell(randi([1, 1008], 1, 60));
        randomizeSlot = num2cell(randi([1, 10], 1, 60));
        nCellID = num2cell(0:1:1007);
        nSlot  = num2cell(0:1:10);
        port   = num2cell(randi([0 7], 1, 60));
        % possible REGBundle sizes  for each CORESET duration
        REGbundleSizes = [[2, 6]; [2, 6]; [3, 6]];
        interleaverSizes = [2, 3, 6];
    end

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        duration = {1, 2, 3};
        CCEREGMapping = {'noninterleaved', 'interleaved'};
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
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, duration, CCEREGMapping, aggregationLevel)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible combinations of numerology,
% duration, CCEREGMapping, aggregationLevel while using a random nCellID, RNTI and codeword for each test.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_output*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique nCellID, nSlot and rnti for each test
            randomizedCellID = testCase.randomizeTestvector{testID+1};
            testCellID = testCase.nCellID{randomizedCellID};
            randomizedSlot = testCase.randomizeSlot{testID+1};
            slotIndex = testCase.nSlot{randomizedSlot};
            rnti = randi([0, 65535], 1, 1);
            maxAllowedStartSymbol = 14 - duration;
            startSymbolIndex = randi([1, maxAllowedStartSymbol], 1, 1);
            if strcmp(CCEREGMapping, 'interleaved')
                interleaverSize = testCase.interleaverSizes(randi([1,3], 1, 1));
                REGBundleSize = testCase.REGbundleSizes(duration, randi([1,2], 1, 1));
            else
                interleaverSize = 2;
                REGBundleSize = 6;
            end
            % currently fixed to 1 port of random number from [0, 7]
            PDCCHports = testCase.port{testID + 1};
            PDCCHportsStr = ['{', array2str(PDCCHports), '}'];

            % current fixed parameter values (e.g., maximum grid size with current interleaving
            %   configuration, CORESET will use all available frequency resources)
            cyclicPrefix = 'normal';
            NSizeGrid = 216;
            NStartGrid = 0;
            NFrame = 0;
            maxFrequencyResources = floor(NSizeGrid / 6);
            frequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            searchSpaceType = 'ue';
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            allocatedCandidate = 1;
            nID = testCellID;

            % only encode the PDCCH when it fits
            if sum(frequencyResources) * duration >= aggregationLevel && ...
               (strcmp(CCEREGMapping, 'noninterleaved') || ...
                (strcmp(CCEREGMapping, 'interleaved') && mod(sum(frequencyResources) * duration, interleaverSize * REGBundleSize) == 0))
                % configure the carrier according to the test parameters
                carrier = srsConfigureCarrier(testCellID, 0, NSizeGrid, NStartGrid, slotIndex, NFrame, cyclicPrefix);

                % configure the CORESET according to the test parameters
                coreset = srsConfigureCORESET(frequencyResources, duration, CCEREGMapping, REGBundleSize, interleaverSize);

                % configure the PDCCH according to the test parameters
                pdcch = srsConfigurePDCCH(coreset, NStartBWP, NSizeBWP, rnti, aggregationLevel, searchSpaceType, allocatedCandidate, nID);

                % set startSymbol using random value generated above
                pdcch.SearchSpace.StartSymbolWithinSlot = startSymbolIndex;

                % generate random codeword, 54REs per CCE, 2 bits per QPSK symbol
                codeWord = randi([0 1], 54 * 2 * aggregationLevel, 1);

                % write the codeWord to a binary file
                testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, @writeUint8File, codeWord);

                % call the PDCCH modulator MATLAB functions
                [PDCCHsymbols, symbolIndices] = srsPDCCHmodulator(codeWord, carrier, pdcch, nID, rnti);
                symbolIndices(:, 3) = int32(PDCCHports);

                % write each complex symbol into a binary file, and the associated indices to another
                testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, PDCCHsymbols, symbolIndices);

                % generate a RB allocation mask string
                rbAllocationMask = repelem({'false'}, NSizeGrid, 1);
                rbAllocationMask(fix(double(symbolIndices(:, 1)) / 12) + 1) = {'true'}; % + 1 due to MATLAB indexing
                rbAllocationMaskStr = cellarray2str(rbAllocationMask');

                % generate the test case entry
                testCaseString = testImpl.testCaseToString(baseFilename, testID, true, {rbAllocationMaskStr, ...
                    startSymbolIndex, duration, nID, rnti, double(1.0), PDCCHportsStr});

                % add the test to the file header
                testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
            end
        end
    end
end
