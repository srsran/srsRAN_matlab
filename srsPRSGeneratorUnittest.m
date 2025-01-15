%srsPRSGeneratorUnittest Unit tests for PRS generator functions.
%   This class implements unit tests for the PRS generator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPRSGeneratorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPRSGeneratorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ptrs_pdsch_generator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors/prs').
%
%   srsPRSGeneratorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPRSGeneratorUnittest Properties (TestParameter):
%
%   Numerology          - Defines the subcarrier spacing (0, 1).
%   DurationAndCombSize - Combinations of duration and comb size.
%
%   srsPRSGeneratorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPRSGeneratorUnittest Methods (Access = protected):
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

classdef srsPRSGeneratorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'prs_generator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors/prs'

        %Minimum bandwidth in PRB. Given in TS38.214 Section 5.1.6.5.
        MinNumRB = 24;

        %Maximum bandwidth in PRB. Given in TS38.214 Section 5.1.6.5.
        MaxNumRB = 272;

        %Bandwidth granularity in PRB. Given in TS38.214 Section 5.1.6.5.
        ResNumRB = 4;

    end

    properties (Hidden)
        randomizeTestvector
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ptrs_pdsch_generator' tests will be erased).
        outputPath = {['testPRS', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Numerology, defines the subcarrier spacing (15kHz and 30kHz).
        Numerology = {0, 1}

        %Valid combinations of comb size and duration. Valid combinations
        %are given in TS38.211 Section 7.4.1.7.3.
        DurationAndCombSize = {[2, 2], [4, 2], [6, 2], [12, 2], [4, 4], [12, 4], [6, 6], [12, 6], [12, 12]}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/prs/prs_generator.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/prs/prs_generator_configuration.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/ran/precoding/precoding_codebooks.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  prs_generator_configuration                             config;\n');
            fprintf(fileID, '  file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '};\n');
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, Numerology, DurationAndCombSize)
        %testvectorGenerationCases Generates a test vector for the given Numerology,
        %   NumLayers, FrequencyDensity, TimeDensity, and
        %   REOffset. Other parameters are selected randomly.

        import srsTest.helpers.cellarray2str
        import srsTest.helpers.writeResourceGridEntryFile
        import srsTest.helpers.symbolAllocationMask2string
        import srsTest.helpers.RBallocationMask2string

        % Derive test parameters.
        subcarrierSpacing = 15 * pow2(Numerology);
        numPRSSymbols = DurationAndCombSize(1);
        combSize = DurationAndCombSize(2);

        % Generate a unique test ID.
        testID = testCase.generateTestID;

        % Grid size, use maximum.
        nSizeGrid = 272;

        % Select random parameters.
        NCellID = randi([0, 504]);
        REOffset = randi([0 combSize - 1]);
        numRB = randi([testCase.MinNumRB / testCase.ResNumRB, ...
            testCase.MaxNumRB / testCase.ResNumRB]) * testCase.ResNumRB;
        symbolStart = randi([0, 14 - numPRSSymbols]);
        RBOffset = randi([0, nSizeGrid - numRB]);
        NPRSID = randi([0 4095]);
        nSlot = randi([0 (10 * pow2(Numerology) - 1)]);
        nFrame = randi([0 1023]);
        amplitude = 10 * (rand() + 1);
        nStartGrid = randi([0, 2176 - numRB - RBOffset]);
        
        % Fix parameters.
        cyclicPrefix = 'normal';

        % Prepare carrier configuration.
        carrier = nrCarrierConfig( ...
            NCellID=NCellID,...
            SubcarrierSpacing=subcarrierSpacing,...
            CyclicPrefix=cyclicPrefix,...
            NSizeGrid=nSizeGrid,...
            NStartGrid=nStartGrid,...
            NSlot=nSlot,...
            NFrame=nFrame);

        % Prepare PRS configuration.
        PRS = nrPRSConfig(...
            NumPRSSymbols=numPRSSymbols,...
            SymbolStart=symbolStart,...
            NumRB=numRB,...
            RBOffset=RBOffset,...
            CombSize=combSize,...
            REOffset=REOffset,...
            NPRSID=NPRSID);

        % Call the PRS symbol processor MATLAB functions.
        symbols = nrPRS(carrier, PRS);
        indices = nrPRSIndices(carrier, PRS, ...
            IndexStyle='subscript', IndexBase='0based');

        % Write each complex symbol along with their associated indices to
        % a binary file.
        testCase.saveDataFile('_test_output', testID, ...
            @writeResourceGridEntryFile, amplitude * symbols, indices);

        % Convert parameters to srsRAN types.
        slotPointStr = cellarray2str({Numerology, nFrame, ...
            floor(nSlot / carrier.SlotsPerSubframe), ...
            rem(nSlot, carrier.SlotsPerSubframe)}, true);
        cyclicPrefixStr = ['cyclic_prefix::' upper(cyclicPrefix)];
        combSizeStr = ['static_cast<prs_comb_size>(' num2str(combSize) ')'];
        durationStr = ['static_cast<prs_num_symbols>(' num2str(numPRSSymbols) ')'];
        rbStart = carrier.NStartGrid + PRS.RBOffset;
        freqAllocConfig = cellarray2str({PRS.RBOffset, PRS.RBOffset + PRS.NumRB}, true);
        powerOffsetdB = 20 * log10(amplitude);
        precodingStr = 'precoding_configuration::make_wideband(make_identity(1))';

        configCell = {...
            slotPointStr, ...              % slot
            cyclicPrefixStr, ...           % cyclic_prefix
            PRS.NPRSID, ...                % n_id_prs
            combSizeStr, ...               % comb_size
            REOffset, ...                  % comb_offset
            durationStr, ...               % duration
            symbolStart, ...               % start_symbol
            rbStart, ...                   % prb_start
            freqAllocConfig, ...           % freq_alloc
            powerOffsetdB, ...             % power_offset_dB
            precodingStr ...               % precoding
            };

        % Generate the test case entry.
        testCaseString = testCase.testCaseToString(testID, configCell, ...
            true, '_test_output');

        % Add the test to the file header.
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPRSGeneratorUnittest
