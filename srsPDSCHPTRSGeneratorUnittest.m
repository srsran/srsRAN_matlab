%srsPDSCHPTRSGeneratorUnittest Unit tests for PDSCH PT-RS generator functions.
%   This class implements unit tests for the PDSCH PT-RS generator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPDSCHPTRSGeneratorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDSCHPTRSGeneratorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ptrs_pdsch_generator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors/ptrs').
%   ValidDMRSReferencePoint - DM-RS Reference point.
%   PowerLevelNumLayer - List of power levels indexed by the number of
%                        layers. Specified in TS38.214 Table 4.1-2.
%
%   srsPDSCHPTRSGeneratorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHPTRSGeneratorUnittest Properties (TestParameter):
%
%   Numerology       - Defines the subcarrier spacing (0, 1, 2, 3).
%   NumLayers        - Number of transmission layers (1, 2, 3, 4).
%   FrequencyDensity - PT-RS frequency domain density (2, 4).
%   TimeDensity      - PT-RS time domain density (1, 2, 4).
%   REOffset         - PT-RS RE offset configuration (00, 01, 10, 11).
%
%   srsPDSCHPTRSGeneratorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDSCHPTRSGeneratorUnittest Methods (Access = protected):
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

classdef srsPDSCHPTRSGeneratorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ptrs_pdsch_generator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors/ptrs'

        %List of valid DM-RS reference points.
        ValidDMRSReferencePoint = {'CRB0', 'PRB0'}

        %Power levels indexed by the number of layers, given in TS38.214
        %Table 4.1-2.
        PowerLevelNumLayer = [0, 3, 4.77, 6, 7, 7.78]
    end

    properties (Hidden)
        randomizeTestvector
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ptrs_pdsch_generator' tests will be erased).
        outputPath = {['testPDSCHptrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing, up to 120kHz (0, 1, 2, 3).
        Numerology = {0, 1, 2, 3}

        %Number of transmission layers (1, 2, 3, 4).
        NumLayers = {1, 2, 3, 4}

        %PT-RS for PDSCH frequency density (2, 4).
        FrequencyDensity = {2, 4}

        %PT-RS for PDSCH time density (1, 2, 4).
        TimeDensity = {1, 2, 4}

        %RE Offset (00, 01, 10, 11)
        REOffset = {'00', '01', '10', '11'};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/ptrs/ptrs_pdsch_generator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/ran/precoding/precoding_codebooks.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  ptrs_pdsch_generator::configuration                     config;\n');
            fprintf(fileID, '  file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '};\n');
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, Numerology, NumLayers, ...
                FrequencyDensity, TimeDensity, REOffset)
        %testvectorGenerationCases Generates a test vector for the given Numerology,
        %   NumLayers, FrequencyDensity, TimeDensity, and
        %   REOffset. Other parameters are selected randomly.

        import srsTest.helpers.cellarray2str
        import srsTest.helpers.writeResourceGridEntryFile
        import srsTest.helpers.symbolAllocationMask2string
        import srsTest.helpers.RBallocationMask2string

        % Generate a unique test ID.
        testID = testCase.generateTestID;

        % Grid size, use maximum.
        nStartGrid = 0;
        nSizeGrid = 272;

        % Select random parameters.
        nCellID = testCase.randomizeTestvector(testID + 1) - 1;
        nSlot = randi([0, 10 * pow2(Numerology) - 1]);
        NSCID = randi([0, 1]);
        nStartBWP = randi([0 10]);
        nSizeBWP = nSizeGrid - nStartBWP;
        PRBstart = randi([0, nSizeBWP - 2]);
        PRBend = randi([PRBstart + 1, nSizeBWP - 1]);
        DMRSTypeAPosition = randi([2 3]);
        DMRSAdditionalPosition = randi([0 3]);
        RNTI = randi([1, 65535]);
        DMRSReferencePoint = testCase.ValidDMRSReferencePoint{randi([1 numel(testCase.ValidDMRSReferencePoint)])};

        % Current fixed parameter values (e.g., number of CDM groups
        % without data).
        nFrame = 0;
        cyclicPrefix = 'normal';
        NIDNSCID = nCellID;
        nID = nCellID;
        reservedRE = [];
        modulation = '16QAM';
        mappingType = 'A';
        symbolAllocation = [1 13];
        PRBSet = PRBstart:PRBend;
        amplitude = 10 .^ (testCase.PowerLevelNumLayer(NumLayers) / 20);
        DMRSConfigurationType = 1;
        DMRSLength = 1;

        % Configure the carrier according to the test parameters.
        subcarrierSpacing = 15 * (2 .^ Numerology);
        carrier = nrCarrierConfig( ...
            NCellID=nCellID, ...
            SubcarrierSpacing=subcarrierSpacing, ...
            NSizeGrid=nSizeGrid, ...
            NStartGrid=nStartGrid, ...
            NSlot=nSlot, ...
            NFrame=nFrame, ...
            CyclicPrefix=cyclicPrefix ...
            );

        % Configure the PDSCH DM-RS symbols according to the test
        % parameters.
        DMRS = nrPDSCHDMRSConfig( ...
            DMRSConfigurationType=DMRSConfigurationType, ...
            DMRSTypeAPosition=DMRSTypeAPosition, ...
            DMRSAdditionalPosition=DMRSAdditionalPosition, ...
            DMRSLength=DMRSLength, ...
            NIDNSCID=NIDNSCID, ...
            NSCID=NSCID, ...
            DMRSReferencePoint=DMRSReferencePoint...
            );

        % Configure the PDSCH PT-RS symbols according to the test
        % parameters.
        PTRS = nrPDSCHPTRSConfig( ...
            TimeDensity=TimeDensity, ...
            FrequencyDensity=FrequencyDensity, ...
            REOffset=REOffset ...
            );

        % Configure the PDSCH according to the test parameters.
        pdsch = nrPDSCHConfig( ...
            DMRS=DMRS, ...
            PTRS=PTRS, ...
            EnablePTRS=true, ...
            NStartBWP=nStartBWP, ...
            NSizeBWP=nSizeBWP, ...
            NID=nID, ...
            RNTI=RNTI, ...
            ReservedRE=reservedRE, ...
            Modulation=modulation, ...
            NumLayers=NumLayers, ...
            MappingType=mappingType, ...
            SymbolAllocation=symbolAllocation, ...
            PRBSet=PRBSet ...
            );

        % Call the PDSCH PT-RS symbol processor MATLAB functions.
        symbols = nrPDSCHPTRS(carrier, pdsch);
        indices = nrPDSCHPTRSIndices(carrier, pdsch, ...
            IndexStyle='subscript', IndexBase='0based');

        % Generate PDSCH DM-RS for calculating the DM-RS symbol mask.
        dmrsIndices = nrPDSCHDMRSIndices(carrier, pdsch, ...
            IndexStyle='subscript', IndexBase='0based');

        % Write each complex symbol along with their associated indices to
        % a binary file.
        testCase.saveDataFile('_test_output', testID, ...
            @writeResourceGridEntryFile, amplitude * symbols, indices);

        % Generate a 'slot_point' configuration string.
        slotPointConfig = cellarray2str({Numerology, nFrame, ...
            floor(nSlot / carrier.SlotsPerSubframe), ...
            rem(nSlot, carrier.SlotsPerSubframe)}, true);

        % Convert the RNTI to a string.
        rntiStr = ['rnti_t(' num2str(pdsch.RNTI) ')'];

        % Select reference point.
        referencePointKrb = 0;
        if strcmp(DMRSReferencePoint, 'PRB0')
            referencePointKrb = nStartBWP;
        end

        % Generate a symbol allocation mask string.
        symbolAllocationMask = symbolAllocationMask2string(dmrsIndices);

        % Create transmission symbol allocation as begin and end.
        symbolAllocation = {pdsch.SymbolAllocation(1), ...
            pdsch.SymbolAllocation(1) + pdsch.SymbolAllocation(2)};

        % Generate a RB allocation mask string.
        rbAllocationMask = RBallocationMask2string(PRBstart + nStartBWP, PRBend + nStartBWP);

        precodingString = ['precoding_configuration::make_wideband(make_identity(' num2str(NumLayers) '))'];

        words = {'one', 'two', 'three', 'four'};
        frequencyDensityStr = ['ptrs_frequency_density::' words{FrequencyDensity}];
        timeDensityStr = ['ptrs_time_density::' words{TimeDensity}];
        reOffsetStr = ['ptrs_re_offset::offset' REOffset];

        configCell = {...
            slotPointConfig, ...                                     % slot
            rntiStr, ...                                             % rnti
            ['dmrs_type::TYPE', num2str(DMRSConfigurationType)], ... % dmrs_config_type
            referencePointKrb, ...                                   % reference_point_k_rb
            NIDNSCID, ...                                            % scrambling_id
            NSCID,...                                                % n_scid
            amplitude, ...                                           % amplitude
            symbolAllocationMask, ...                                % dmrs_symbols_mask
            rbAllocationMask, ...                                    % rb_mask
            symbolAllocation, ...                                    % time_allocation
            frequencyDensityStr, ...                                 % freq_density
            timeDensityStr, ...                                      % time_density
            reOffsetStr, ...                                         % re_offset
            {}, ...                                                  % reserved
            precodingString...                                       % precoding
            };

        % Generate the test case entry.
        testCaseString = testCase.testCaseToString(testID, configCell, ...
            true, '_test_output');

        % Add the test to the file header.
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHPTRSGeneratorUnittest
