classdef srsPDSCHdmrsUnittest < matlab.unittest.TestCase
%SRSPDSCHDMRSUNITTEST Unit tests for PDSCH DMRS processor functions.
%   This class implements unit tests for the PDSCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = SRSPDSCHDMRSUNITTEST
%   and then running all the tests with
%       testResults = testCase.run
%
%   SRSPDSCHDMRSUNITTEST Properties (TestParameter):
%
%   NCellID                 - PHY-layer cell ID (0, ..., 1007).
%   NSlot                   - slot index (0, ..., 19).
%   rnti                    - radio network temporary ID (0, ..., 65535)
%   numerology              - defines the subcarrier spacing (0, 1)
%   numLayers               - number of transmisson layers (1, 2, 4, 8)
%   DMRSTypeAPosition       - position of first DMRS OFDM symbol (2, 3)
%   DMRSadditionalPosition  - maximum number of DMRS additional positions (0, 1, 2, 3)
%   DMRSlength              - number of consecutive front-loaded DMRS OFDM symbols (1, 2)
%   DMRSconfigurationType   - DMRS configuration type (1, 2)
%   numCDMgroupsWithoutData - number of DM-RS CDM groups without data (1, 2, 3)
%
%   SRSPDSCHDMRSUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible combinations of numerology,
%                               numLayers, DMRStypeAposition, DMRSadditionalPosition, DMRSlength and
%                               DMRSconfigurationType, while using a random NCellID, NSlot and PRB
%                               set for each test, jointly with some fixed parameters.
%
%   SRSPDSCHDMRSUNITTEST Methods (TestTags = {'srsPHYvalidation'}):
%
%  See also MATLAB.UNITTEST.

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        randomizeTestvector = num2cell(randi([1, 1008], 1, 768));
        randomizeSlotNum0 = num2cell(randi([1, 10], 1, 768));
        randomizeSlotNum1 = num2cell(randi([1, 20], 1, 768));
        randomizeScramblingInit = num2cell(randi([0, 1], 1, 768));
        randomizePRBset0 = num2cell(randi([0,136], 1, 768))
        randomizePRBset1 = num2cell(randi([137,271], 1, 768));
        NCellID = num2cell(0:1:1007);
        NSlot = num2cell(0:1:19);
        rnti = num2cell(0:1:65535);
        numerology = {0, 1};
        numLayers = {1, 2, 4, 8};
        DMRStypeAposition = {2, 3};
        DMRSadditionalPosition = {0, 1, 2, 3};
        DMRSlength = {1, 2};
        DMRSconfigurationType = {1, 2};
        numCDMgroupsWithoutData = {1, 2, 3};
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
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, numerology, numLayers, DMRStypeAposition, DMRSadditionalPosition, DMRSlength, DMRSconfigurationType)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible combinations of numerology,
%   numLayers, DMRStypeAposition, DMRSadditionalPosition, DMRSlength and DMRSconfigurationType,
%   while using a random NCellID, NSlot and PRB set for each test, jointly with some fixed
%   parameters.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_output*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID, NSlot, scrambling ID and PRB allocation for each test
            randomizedCellID = testCase.randomizeTestvector{testID+1};
            NCellIDLoc = testCase.NCellID{randomizedCellID};
            if numerology == 0
                randomizedSlot = testCase.randomizeSlotNum0{testID+1};
            else
                randomizedSlot = testCase.randomizeSlotNum1{testID+1};
            end
            NSlotLoc = testCase.NSlot{randomizedSlot};
            scramblingInitLoc = testCase.randomizeScramblingInit{testID+1};
            PRBstart = testCase.randomizePRBset0{testID+1};
            PRBend = testCase.randomizePRBset1{testID+1};

            % current fixed parameter values (e.g., number of CDM groups without data)
            NSizeGrid = 272;
            NStartGrid = 0;
            NFrame = 0;
            cyclicPrefix = 'normal';
            rnti = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            numPorts = 1;
            referencePointKrb = 0;
            startSymbolIndex = 0;
            DRMSscramblingID = NCellIDLoc;
            numCDMgroupsWithoutDataLoc = 2;
            scramblingID = NCellIDLoc;
            reservedRE = [];
            modulation = '16QAM';
            mappingType = 'A';
            symbolAlocation = [1 13];
            PRBset = [PRBstart:PRBend];
            pmi = 0;
            PDSCHports = zeros(numPorts, 1);
            PDSCHportsStr = cellarray2str({PDSCHports}, true);

            % skip those invalid configuration cases
            isDMRSlengthOK = (DMRSlength == 1 || DMRSadditionalPosition < 2);
            if isDMRSlengthOK
                % configure the carrier according to the test parameters
                carrier = srsConfigureCarrier(NCellIDLoc, numerology, NSizeGrid, NStartGrid, NSlotLoc, NFrame, cyclicPrefix);

                % configure the PDSCH DMRS symbols according to the test parameters
                DMRSconfig = srsConfigurePDSCHdmrs(DMRSconfigurationType, DMRStypeAposition, DMRSadditionalPosition, DMRSlength, DRMSscramblingID, scramblingInitLoc, numCDMgroupsWithoutDataLoc);

                % configure the PDSCH according to the test parameters
                pdsch = srsConfigurePDSCH(DMRSconfig, NStartBWP, NSizeBWP, scramblingID, rnti, reservedRE, modulation, numLayers, mappingType, symbolAlocation, PRBset);

                % call the PDSCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPDSCHdmrs(carrier, pdsch);

                % write each complex symbol into a binary file, and the associated indices to another
                testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, DMRSsymbols, symbolIndices);

                % generate a 'slot_point' configuration string
                slotPointConfig = cellarray2str({numerology, NFrame, floor(NSlotLoc / carrier.SlotsPerSubframe), ...
                                                 rem(NSlotLoc, carrier.SlotsPerSubframe)}, true);

                % generate a symbol allocation mask string
                symbolAllocationMask = generateSymbolAllocationMaskString(symbolIndices);

                % generate a RB allocation mask string
                rbAllocationMask = generateRBallocationMaskString(PRBstart, PRBend);

                % generate the test case entry
                testCaseString = testImpl.testCaseToString( baseFilename, testID, false, {slotPointConfig, referencePointKrb, ['dmrs_type::TYPE', num2str(DMRSconfigurationType)], ...
                                      DRMSscramblingID, scramblingInitLoc, numCDMgroupsWithoutDataLoc, pmi, symbolAllocationMask, rbAllocationMask, PDSCHportsStr}, true);

                % add the test to the file header
                testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
            end
        end
    end
end
