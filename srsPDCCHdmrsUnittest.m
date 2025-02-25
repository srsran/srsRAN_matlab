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

classdef srsPDCCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pdcch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pdcch_processor' tests will be erased).
        outputPath = {['testPDCCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %Slot index (0...19).
        NSlot = num2cell(0:19)

        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %CORESET duration (1, 2, 3).
        Duration = {1, 2, 3}

        %CCE-to-REG mapping ('interleaved', 'noninteleaved').
        CCEREGMapping = {'interleaved','noninterleaved'}

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        AggregationLevel= {1, 2, 4, 8, 16}
    end % of properties (TestParameter)

    properties(Hidden)
        randomizeTestvector
        randomizeSlotNum0
        randomizeSlotNum1
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
            fprintf(fileID, '#include "srsran/ran/precoding/precoding_codebooks.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'static const precoding_configuration default_precoding = precoding_configuration::make_wideband(make_single_port());\n');
            fprintf(fileID, '\n');
            addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
            obj.randomizeSlotNum0 = randi([1, 10], 1, 1008);
            obj.randomizeSlotNum1 = randi([1, 20], 1, 1008);
        end
    end % of methods (Access = protected)

    methods (TestClassSetup)
        function createRandomVector(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, Duration, CCEREGMapping, AggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given numerology, Duration,
        %   CCEREGMapping and AggregationLevel, while using a random NCellID and a random NSlot.

            import srsTest.helpers.cellarray2str
            import srsLib.phy.upper.signal_processors.srsPDCCHdmrs
            import srsLib.phy.helpers.srsGetUniqueSymbolsIndices
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.RBallocationMask2string

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % use a unique NCellID, NSlot and rnti for each test
            randomizedCellID = testCase.randomizeTestvector(testID + 1);
            nCellID = testCase.NCellID{randomizedCellID};

            if numerology == 0
                randomizedSlot = testCase.randomizeSlotNum0(testID + 1);
            else
                randomizedSlot = testCase.randomizeSlotNum1(testID + 1);
            end
            nSlot = testCase.NSlot{randomizedSlot};

            % current fixed parameter values (e.g., maximum grid size with current interleaving
            % configuration, CORESET will use all available frequency resources)
            nSizeGrid = 216;
            nStartGrid = 0;
            nFrame = 0;
            cyclicPrefix = 'normal';
            maxFrequencyResources = floor(nSizeGrid / 6);
            frequencyResources = int2bit(2^maxFrequencyResources - 1, maxFrequencyResources).';
            interleaverSize = 2;
            REGBundleSize = 6;
            searchSpaceType = 'ue';
            rnti = 0;
            nStartBWP = 0;
            nSizeBWP = nSizeGrid;
            allocatedCandidate = 1;
            referencePointKrb = 0;
            startSymbolIndex = 0;
            DMRSScramblingID = nCellID;
            DMRSamplitude = 1.0;

            % only encode the PDCCH when it fits
            isAggregationOK = (sum(frequencyResources) * Duration >= AggregationLevel);
            isREGbundleSizeOK = (mod(sum(frequencyResources) * Duration, interleaverSize * REGBundleSize) == 0);
            isCCEREGMappingOK = (strcmp(CCEREGMapping, 'noninterleaved') || ...
                (strcmp(CCEREGMapping, 'interleaved') &&  isREGbundleSizeOK));

            if (isAggregationOK && isCCEREGMappingOK)

                % configure the carrier according to the test parameters
                subcarrierSpacing = 15 * (2 .^ numerology);
                carrier = nrCarrierConfig( ...
                    NCellID=nCellID, ...
                    SubcarrierSpacing=subcarrierSpacing, ...
                    NSizeGrid=nSizeGrid, ...
                    NStartGrid=nStartGrid, ...
                    NSlot=nSlot, ...
                    NFrame=nFrame, ...
                    CyclicPrefix=cyclicPrefix ...
                    );

                % configure the CORESET according to the test parameters
                coreset = nrCORESETConfig( ...
                    FrequencyResources=frequencyResources, ...
                    Duration=Duration, ...
                    CCEREGMapping=CCEREGMapping, ...
                    REGBundleSize=REGBundleSize, ...
                    InterleaverSize=interleaverSize ...
                    );

                % configure the PDCCH according to the test parameters
                pdcch = nrPDCCHConfig( ...
                    CORESET=coreset, ...
                    NStartBWP=nStartBWP, ...
                    NSizeBWP=nSizeBWP, ...
                    RNTI=rnti, ...
                    AggregationLevel=AggregationLevel, ...
                    AllocatedCandidate=allocatedCandidate, ...
                    DMRSScramblingID=DMRSScramblingID ...
                    );
                pdcch.SearchSpace.SearchSpaceType = searchSpaceType;

                % call the PDCCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch);

                % put all generated DMRS symbols and indices in a single cell
                [DMRSsymbolsVector, symbolIndicesVector] = ...
                    srsGetUniqueSymbolsIndices(DMRSsymbols, symbolIndices);

                % write each complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile('_test_output', testID, @writeResourceGridEntryFile, ...
                    DMRSsymbolsVector, symbolIndicesVector);

                % generate a 'slot_point' configuration string
                slotPointConfig = {numerology, nFrame, ...
                    floor(nSlot / carrier.SlotsPerSubframe), ...
                    rem(nSlot, carrier.SlotsPerSubframe)};

                % generate a RB allocation mask string
                rbAllocationMask = RBallocationMask2string(symbolIndicesVector);


                % Convert cyclic prefix to string.
                cpString = ['cyclic_prefix::', upper(cyclicPrefix)];

                configCell = {...
                    slotPointConfig, ...    % slot
                    cpString, ...           % cp
                    referencePointKrb,...   % reference_point_k_rb
                    rbAllocationMask, ...   % rb_mask
                    startSymbolIndex, ...   % start_symbol_index
                    Duration, ...           % duration
                    DMRSScramblingID, ...   % n_id
                    DMRSamplitude, ...      % amplitude
                    'default_precoding',... % precoding
                    };

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, ...
                    configCell, ...
                        true, '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end % of if (isAggregationOK && isCCEREGMappingOK)
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHdmrsUnittest
