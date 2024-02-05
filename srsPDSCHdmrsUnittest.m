%srsPDSCHdmrsUnittest Unit tests for PDSCH DMRS processor functions.
%   This class implements unit tests for the PDSCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPDSCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDSCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pdsch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsPDSCHdmrsUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHdmrsUnittest Properties (TestParameter):
%
%   numerology              - Defines the subcarrier spacing (0, 1).
%   NumLayers               - Number of transmission layers (1, 2, 4, 8).
%   DMRSTypeAPosition       - Position of the first DMRS OFDM symbol (2, 3).
%   DMRSAdditionalPosition  - Maximum number of DMRS additional positions (0, 1, 2, 3).
%   DMRSLength              - Number of consecutive front-loaded DMRS OFDM symbols (1, 2).
%   DMRSConfigurationType   - DMRS configuration type (1, 2).
%
%   srsPDSCHdmrsUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDSCHdmrsUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

%   Copyright 2021-2024 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

classdef srsPDSCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pdsch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (Hidden)
        randomizeTestvector
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pdsch_processor' tests will be erased).
        outputPath = {['testPDSCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %Number of transmission layers (1, 2, 3, 4).
        NumLayers = {1, 2, 3, 4}

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
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
            fprintf(fileID, '#include "srsran/ran/precoding/precoding_codebooks.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, NumLayers, ...
                DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, DMRSConfigurationType)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength and
        %   DMRSConfigurationType. NCellID, NSlot and PRB are randomly generated.

            import srsTest.helpers.cellarray2str
            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsConfigurePDSCHdmrs
            import srsLib.phy.helpers.srsConfigurePDSCH
            import srsLib.phy.upper.signal_processors.srsPDSCHdmrs
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.RBallocationMask2string

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Use a unique NCellID, NSlot, scrambling ID and PRB allocation
            % for each test.
            NCellID = testCase.randomizeTestvector(testID + 1) - 1;
            if numerology == 0
                NSlot = randi([0, 9]);
            else
                NSlot = randi([0, 19]);
            end
            NSCID = randi([0, 1]);
            PRBstart = randi([0, 136]);
            PRBend = randi([136, 271]);

            % Current fixed parameter values (e.g., number of CDM groups
            % without data).
            NSizeGrid = 272;
            NStartGrid = 0;
            NFrame = 0;
            CyclicPrefix = 'normal';
            RNTI = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            referencePointKrb = 0;
            NIDNSCID = NCellID;
            NID = NCellID;
            ReservedRE = [];
            Modulation = '16QAM';
            MappingType = 'A';
            SymbolAllocation = [1 13];
            PRBSet = PRBstart:PRBend;
            amplitude = 0.5;

            % Skip those invalid configuration cases.
            isDMRSLengthOK = (DMRSLength == 1 || DMRSAdditionalPosition < 2);
            if isDMRSLengthOK
                % Configure the carrier according to the test parameters.
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, ...
                    NSizeGrid, NStartGrid, NSlot, NFrame, CyclicPrefix);

                % Configure the PDSCH DMRS symbols according to the test
                % parameters.
                DMRS = srsConfigurePDSCHdmrs(DMRSConfigurationType, ...
                    DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, ...
                    NIDNSCID, NSCID);

                % Configure the PDSCH according to the test parameters.
                pdsch = srsConfigurePDSCH(DMRS, NStartBWP, NSizeBWP, NID, RNTI, ...
                    ReservedRE, Modulation, NumLayers, MappingType, ...
                    SymbolAllocation, PRBSet);

                % Call the PDSCH DMRS symbol processor MATLAB functions.
                [DMRSsymbols, symbolIndices] = srsPDSCHdmrs(carrier, pdsch);

                % Write each complex symbol into a binary file, and the
                % associated indices to another.
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, amplitude * DMRSsymbols, symbolIndices);

                % Generate a 'slot_point' configuration string.
                slotPointConfig = cellarray2str({numerology, NFrame, ...
                    floor(NSlot / carrier.SlotsPerSubframe), ...
                    rem(NSlot, carrier.SlotsPerSubframe)}, true);

                % Generate a symbol allocation mask string.
                symbolAllocationMask = symbolAllocationMask2string(symbolIndices);

                % Generate a RB allocation mask string.
                rbAllocationMask = RBallocationMask2string(PRBstart, PRBend);

                precodingString = ['precoding_configuration::make_wideband(make_identity(' num2str(NumLayers) '))'];

                configCell = {...
                    slotPointConfig, ...                                     % slot
                    referencePointKrb, ...                                   % reference_point_k_rb
                    ['dmrs_type::TYPE', num2str(DMRSConfigurationType)], ... % type
                    NIDNSCID, ...                                            % scrambling_id
                    NSCID,...                                                % n_scid
                    amplitude, ...                                           % amplitude
                    symbolAllocationMask, ...                                % symbols_mask
                    rbAllocationMask, ...                                    % rb_mask
                    precodingString...                                       % precoding
                };

                % Generate the test case entry.
                testCaseString = testCase.testCaseToString(testID, configCell, ...
                        true, '_test_output');

                % Add the test to the file header.
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHdmrsUnittest
