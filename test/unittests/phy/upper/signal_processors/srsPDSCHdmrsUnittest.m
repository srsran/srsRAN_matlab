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
%   RNTI                    - radio network temporary ID (0, ..., 65535)
%   numerology              - defines the subcarrier spacing (0, 1)
%   NumLayers               - number of transmisson layers (1, 2, 4, 8)
%   DMRSTypeAPosition       - position of first DMRS OFDM symbol (2, 3)
%   DMRSAdditionalPosition  - maximum number of DMRS additional positions (0, 1, 2, 3)
%   DMRSLength              - number of consecutive front-loaded DMRS OFDM symbols (1, 2)
%   DMRSConfigurationType   - DMRS configuration type (1, 2)
%   NumCDMGroupsWithoutData - number of DM-RS CDM groups without data (1, 2, 3)
%
%   SRSPDSCHDMRSUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB path and
%                               initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible combinations of numerology,
%                               NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength and
%                               DMRSConfigurationType, while using a random NCellID, NSlot and PRB
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
        randomizePRBSet0 = num2cell(randi([0,136], 1, 768))
        randomizePRBSet1 = num2cell(randi([137,271], 1, 768));
        NCellID = num2cell(0:1:1007);
        NSlot = num2cell(0:1:19);
        RNTI = num2cell(0:1:65535);
        numerology = {0, 1};
        NumLayers = {1, 2, 4, 8};
        DMRSTypeAPosition = {2, 3};
        DMRSAdditionalPosition = {0, 1, 2, 3};
        DMRSLength = {1, 2};
        DMRSConfigurationType = {1, 2};
        NumCDMGroupsWithoutData = {1, 2, 3};
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
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, numerology, NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, DMRSConfigurationType)
%TESTVECTORGENERATIONCASES Generates test vectors for all possible combinations of numerology,
%   NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength and DMRSConfigurationType,
%   while using a random NCellID, NSlot and PRB set for each test, jointly with some fixed
%   parameters.

            % generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_output*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % use a unique NCellID, NSlot, scrambling ID and PRB allocation for each test
            randomizedCellID = testCase.randomizeTestvector{testID + 1};
            NCellIDLoc = testCase.NCellID{randomizedCellID};
            if numerology == 0
                randomizedSlot = testCase.randomizeSlotNum0{testID + 1};
            else
                randomizedSlot = testCase.randomizeSlotNum1{testID + 1};
            end
            NSlotLoc = testCase.NSlot{randomizedSlot};
            NSCID = testCase.randomizeScramblingInit{testID+1};
            PRBstart = testCase.randomizePRBSet0{testID+1};
            PRBend = testCase.randomizePRBSet1{testID+1};

            % current fixed parameter values (e.g., number of CDM groups without data)
            NSizeGrid = 272;
            NStartGrid = 0;
            NFrame = 0;
            CyclicPrefix = 'normal';
            RNTILoc = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            numPorts = 1;
            referencePointKrb = 0;
            startSymbolIndex = 0;
            NIDNSCID = NCellIDLoc;
            NumCDMGroupsWithoutDataLoc = 2;
            NID = NCellIDLoc;
            ReservedRE = [];
            Modulation = '16QAM';
            MappingType = 'A';
            SymbolAllocation = [1 13];
            PRBSet = [PRBstart:PRBend];
            pmi = 0;
            PDSCHports = zeros(numPorts, 1);
            PDSCHportsStr = cellarray2str({PDSCHports}, true);

            % skip those invalid configuration cases
            isDMRSLengthOK = (DMRSLength == 1 || DMRSAdditionalPosition < 2);
            if isDMRSLengthOK
                % configure the carrier according to the test parameters
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(NCellIDLoc, SubcarrierSpacing, NSizeGrid, NStartGrid, NSlotLoc, NFrame, CyclicPrefix);

                % configure the PDSCH DMRS symbols according to the test parameters
                DMRS = srsConfigurePDSCHdmrs(DMRSConfigurationType, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, NIDNSCID, NSCID, NumCDMGroupsWithoutDataLoc);

                % configure the PDSCH according to the test parameters
                pdsch = srsConfigurePDSCH(DMRS, NStartBWP, NSizeBWP, NID, RNTILoc, ReservedRE, Modulation, NumLayers, MappingType, SymbolAllocation, PRBSet);

                % call the PDSCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPDSCHdmrs(carrier, pdsch);

                % write each complex symbol into a binary file, and the associated indices to another
                testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, DMRSsymbols, symbolIndices);

                % generate a 'slot_point' configuration string
                slotPointConfig = cellarray2str({numerology, NFrame, floor(NSlotLoc / carrier.SlotsPerSubframe), ...
                                                 rem(NSlotLoc, carrier.SlotsPerSubframe)}, true);

                % generate a symbol allocation mask string
                symbolAllocationMask = symbolAllocationMask2string(symbolIndices);

                % generate a RB allocation mask string
                rbAllocationMask = RBallocationMask2string(PRBstart, PRBend);

                % generate the test case entry
                testCaseString = testImpl.testCaseToString( baseFilename, testID, false, {slotPointConfig, referencePointKrb, ['dmrs_type::TYPE', num2str(DMRSConfigurationType)], ...
                                      NIDNSCID, NSCID, NumCDMGroupsWithoutDataLoc, pmi, symbolAllocationMask, rbAllocationMask, PDSCHportsStr}, true);

                % add the test to the file header
                testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
            end
        end
    end
end
