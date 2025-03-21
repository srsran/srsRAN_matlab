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
%                   (i.e., 'phy/upper/channel_processors/pdcch').
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
%   See also matlab.unittest.

%   Copyright 2021-2025 Software Radio Systems Limited
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

classdef srsPDCCHModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdcch_modulator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pdcch'

        %Number of possible PHY cell identifiers - NCellID takes values in (0...1007).
        nofNCellID = 1008

        %Possible REGBundle sizes  for each CORESET Duration.
        REGBundleSizes = [[2, 6]; [2, 6]; [3, 6]]

        %Possible interleaver sizes.
        InterleaverSizes = [2, 3, 6]
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pddch_processor' tests will be erased).
        outputPath = {['testPDCCHmodulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %CORESET duration (1, 2, 3).
        Duration = {1, 2, 3}

        %CCE-to-REG mapping ('noninteleaved', 'interleaved').
        CCEREGMapping = {'noninterleaved', 'interleaved'}

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        AggregationLevel= {1, 2, 4, 8, 16}
    end

    properties (Hidden)
        randomizeTestvector
        randomizeSlot
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, [...
                '#include "../../../support/resource_grid_test_doubles.h"\n'...
                '#include "srsran/phy/upper/channel_processors/pdcch/pdcch_modulator.h"\n'...
                '#include "srsran/ran/precoding/precoding_codebooks.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'static const precoding_configuration default_precoding = precoding_configuration::make_wideband(make_single_port());\n');
            fprintf(fileID, '\n');
            addTestDefinitionToHeaderFilePHYchproc(obj, fileID);
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(srsPDCCHModulatorUnittest.nofNCellID);
            obj.randomizeSlot = randi([1, 10], 1, srsPDCCHModulatorUnittest.nofNCellID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, Duration, CCEREGMapping, AggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given CORESET duration,
        %   CCEREGMapping and AggregationLevel, while using randomly generated NCellID,
        %   RNTI and codeword.

            import srsTest.helpers.array2str
            import srsTest.helpers.writeResourceGridEntryFile
            import srsLib.phy.upper.channel_processors.srsPDCCHmodulator
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.RBallocationMask2string

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Use a unique nCellID, nSlot and RNTI for each test.
            testCellID = testCase.randomizeTestvector(testID + 1) - 1;
            nSlot = testCase.randomizeSlot(testID + 1);
            rnti = randi([0, 65519]);
            maxAllowedStartSymbol = 14 - Duration;
            startSymbolIndex = randi([1, maxAllowedStartSymbol]);
            if strcmp(CCEREGMapping, 'interleaved')
                interleaverSize = testCase.InterleaverSizes(randi([1, 3]));
                REGBundleSize = testCase.REGBundleSizes(Duration, randi([1, 2]));
            else
                interleaverSize = 2;
                REGBundleSize = 6;
            end

            % Current fixed parameter values (e.g., maximum grid size with current interleaving
            % configuration, CORESET will use all available frequency resources).
            cyclicPrefix = 'normal';
            nSizeGrid = 52;
            nStartGrid = 0;
            nFrame = 0;
            maxFrequencyResources = floor(nSizeGrid / 6);
            frequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            searchSpaceType = 'ue';
            nStartBWP = 0;
            nSizeBWP = nSizeGrid;
            allocatedCandidate = 1;
            DMRSScramblingID = testCellID;

            % Only encode the PDCCH when it fits.
            isAggregationOK = (sum(frequencyResources) * Duration >= AggregationLevel);
            isREGbundleSizeOK = (mod(sum(frequencyResources) * Duration, interleaverSize * REGBundleSize) == 0);
            isCCEREGMappingOK = (strcmp(CCEREGMapping, 'noninterleaved') || ...
                (strcmp(CCEREGMapping, 'interleaved') &&  isREGbundleSizeOK));

            if (isAggregationOK && isCCEREGMappingOK)
                % Configure the carrier according to the test parameters.
                carrier = nrCarrierConfig( ...
                    NSizeGrid=nSizeGrid, ...
                    NStartGrid=nStartGrid, ...
                    NSlot=nSlot, ...
                    NFrame=nFrame, ...
                    CyclicPrefix=cyclicPrefix ...
                    );

                % Configure the CORESET according to the test parameters.
                coreset = nrCORESETConfig( ...
                    FrequencyResources=frequencyResources, ...
                    Duration=Duration, ...
                    CCEREGMapping=CCEREGMapping, ...
                    REGBundleSize=REGBundleSize, ...
                    InterleaverSize=interleaverSize ...
                    );

                % Configure the PDCCH according to the test parameters.
                pdcch = nrPDCCHConfig( ...
                    CORESET=coreset, ...
                    NStartBWP=nStartBWP, ...
                    NSizeBWP=nSizeBWP, ...
                    RNTI=rnti, ...
                    AggregationLevel=AggregationLevel, ...
                    AllocatedCandidate=allocatedCandidate, ...
                    DMRSScramblingID=DMRSScramblingID ...
                    );

                % Set startSymbol using random value generated above.
                pdcch.SearchSpace.StartSymbolWithinSlot = startSymbolIndex;
                pdcch.SearchSpace.SearchSpaceType = searchSpaceType;

                % Generate random codeword, 54REs per CCE, 2 bits per QPSK symbol.
                codeWord = randi([0 1], 54 * 2 * AggregationLevel, 1);

                % Write the codeWord to a binary file.
                testCase.saveDataFile('_test_input', testID, @writeUint8File, codeWord);

                % Call the PDCCH modulator MATLAB functions.
                [PDCCHsymbols, symbolIndices] = srsPDCCHmodulator(codeWord, carrier, pdcch, DMRSScramblingID, rnti);

                % Write each complex symbol into a binary file, and the associated indices to another.
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, PDCCHsymbols, symbolIndices);

                % Generate a RB allocation mask string.
                rbAllocationMaskStr = RBallocationMask2string(symbolIndices);

                configCell = {...
                    rbAllocationMaskStr, ... rb_mask
                    startSymbolIndex, ...    start_symbol_index
                    Duration, ...            duration
                    DMRSScramblingID, ...    n_id
                    rnti, ...                n_rnti
                    1.0, ...                 scaling
                    'default_precoding'...   precoding
                    };

                % Generate the test case entry.
                testCaseString = testCase.testCaseToString(testID, configCell, ...
                                   true, '_test_input', '_test_output');

                % Add the test to the file header.
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHModulatorUnittest< srsTest.srsBlockUnittest
