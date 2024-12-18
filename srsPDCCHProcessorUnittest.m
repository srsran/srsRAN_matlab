%srsPDCCHProcessorUnittest Unit tests for PDCCH processor functions.
%   This class implements unit tests for the PDCCH processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPDCCHProcessorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDCCHProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pddch_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors/pdcch').
%
%   nofNCellID       - Number of possible PHY cell identifiers.
%   REGBundleSizes   - Possible REGBundle sizes  for each CORESET Duration.
%   InterleaverSizes - Possible interleaver sizes.
%
%   srsPDCCHProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDCCHProcessorUnittest Properties (TestParameter):
%
%   Duration         - CORESET Duration.
%   CCEREGMapping    - CCE-to-REG mapping.
%   AggregationLevel - PDCCH aggregation level.
%
%   srsPDCCHProcessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDCCHProcessorUnittest Methods (Access = protected):
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

classdef srsPDCCHProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdcch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pdcch'

        %Possible REGBundle sizes  for each CORESET Duration.
        REGBundleSizes = [[2, 6]; [2, 6]; [3, 6]]

        %Possible interleaver sizes.
        InterleaverSizes = [2, 3, 6]
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pddch_processor' tests will be erased).
        outputPath = {['testPDCCHProcessor', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        NSizeGrid = {25, 52, 79, 106, 133, 160, 216, 270}

        %CORESET duration (1, 2, 3).
        Duration = {1, 2, 3}

        %CCE-to-REG mapping ('noninteleaved', 'interleaved').
        CCEREGMapping = {'noninterleaved'}

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        AggregationLevel= {1, 2, 4, 8, 16}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, [...
                '#include "../../../support/resource_grid_test_doubles.h"\n'...
                '#include "srsran/phy/upper/channel_processors/pdcch/pdcch_processor.h"\n'...
                '#include "srsran/ran/precoding/precoding_codebooks.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'static const precoding_configuration default_precoding = precoding_configuration::make_wideband(make_single_port());\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'pdcch_processor::pdu_t config;\n');
            fprintf(fileID, ...
                'file_vector<resource_grid_writer_spy::expected_entry_t> data;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, NSizeGrid, Duration, CCEREGMapping, AggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given CORESET duration,
        %   CCEREGMapping and AggregationLevel, while using randomly generated NCellID,
        %   RNTI and codeword.

        import srsTest.helpers.array2str
        import srsTest.helpers.writeResourceGridEntryFile
        import srsLib.phy.upper.channel_processors.srsPDCCHmodulator
        import srsLib.phy.upper.signal_processors.srsPDCCHdmrs
        import srsLib.ran.pdcch.srsPDCCHCandidatesUE
        import srsTest.helpers.writeUint8File
        import srsTest.helpers.RBallocationMask2string

        % Generate a unique test ID.
        testID = testCase.generateTestID;

        % Generate random parameters.
        testCellID = randi([0, 1007]);
        nSlot = randi([0, 9]);
        RNTI = randi([0, 65519]);
        maxAllowedStartSymbol = 14 - Duration;
        startSymbolWithinSlot = randi([1 maxAllowedStartSymbol]);
        if strcmp(CCEREGMapping, 'interleaved')
            interleaverSize = testCase.InterleaverSizes(randi([1, 3]));
            REGBundleSize = testCase.REGBundleSizes(Duration, randi([1, 2]));
        else
            interleaverSize = 2;
            REGBundleSize = 6;
        end
        coresetID = randi([1, 10]);

        % Current fixed parameter values (e.g., maximum grid size with current interleaving
        % configuration, CORESET will use all available frequency resources).
        cyclicPrefix = 'normal';
        nStartGrid = 0;
        nFrame = randi([0, 1023]);
        frequencyResources = ones(1, floor(NSizeGrid / 6));
        searchSpaceType = 'ue';
        nStartBWP = 0;
        nSizeBWP = NSizeGrid;
        DMRSScramblingID = testCellID;

        % Configure the carrier according to the test parameters.
        carrier = nrCarrierConfig( ...
            NSizeGrid=NSizeGrid, ...
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
            InterleaverSize=interleaverSize, ...
            CORESETID=coresetID ...
            );

        % Select number of candidates.
        numCandidates = floor(coreset.NCCE ./ [1, 2, 4, 8, 16]);
        numCandidates(numCandidates > 8) = 8;

        % Configure Search Space.
        searchSpace = nrSearchSpaceConfig( ...
            SearchSpaceType=searchSpaceType, ...
            StartSymbolWithinSlot=startSymbolWithinSlot, ...
            CORESETID=coresetID, ...
            NumCandidates=numCandidates ...
            );

        % Skip if no candidates available.
        AggregationLevelIndex = floor(log2(AggregationLevel)) + 1;
        if numCandidates(AggregationLevelIndex) == 0
            return;
        end

        % Configure the PDCCH according to the test parameters.
        pdcch = nrPDCCHConfig( ...
            CORESET=coreset, ...
            SearchSpace=searchSpace, ...
            NStartBWP=nStartBWP, ...
            NSizeBWP=nSizeBWP, ...
            RNTI=RNTI, ...
            AggregationLevel=AggregationLevel, ...
            DMRSScramblingID=DMRSScramblingID ...
            );

        % Calculate the available candidates CCE initial positions.
        candidatesCCE = srsPDCCHCandidatesUE(coreset.NCCE, numCandidates(AggregationLevelIndex), AggregationLevel, coreset.CORESETID, RNTI, carrier.NSlot);

        % Select random candidate and initial CCE.
        candidateIndex = randi([1, numCandidates(AggregationLevelIndex)]);
        pdcch.AllocatedCandidate = candidateIndex;
        ncce = candidatesCCE(candidateIndex);

        % Calculate number of encoded bits, 54REs per CCE, 2 bits per QPSK symbol.
        nofEncodedBits = 54 * 2 * AggregationLevel;

        % Select a number of payload bits.
        nofPayloadBits = randi([12, 70]);
        message = randi([0 1], nofPayloadBits, 1);

        % Encode message.
        encodedMsg = nrDCIEncode(message, RNTI, nofEncodedBits);

        % Call the PDCCH modulator MATLAB functions.
        [dataSymbols, dataIndices] = srsPDCCHmodulator(encodedMsg, carrier, pdcch, DMRSScramblingID, RNTI);

        % Call the PDCCH DM-RS symbol processor MATLAB functions.
        [dmrsSymbols, dmrsIndices] = srsPDCCHdmrs(carrier, pdcch);

        if dataIndices(1) ~= ncce * 6 / Duration * 12
            error('fishy case');
        end

        % Select DM-RS from all candidates.
        dmrsSymbols = cell2mat(dmrsSymbols(AggregationLevelIndex));
        dmrsSymbols = dmrsSymbols(:, candidateIndex);
        dmrsIndices = cell2mat(dmrsIndices(AggregationLevelIndex));
        dmrsIndices = dmrsIndices(:, :, candidateIndex);

        % Write each complex symbol into a binary file, and the associated
        % indices to another.
        testCase.saveDataFile('_test_output', testID, ...
            @writeResourceGridEntryFile, [dataSymbols; dmrsSymbols], ...
            [dataIndices; dmrsIndices]);

        slotIndex = nFrame * carrier.SlotsPerSubframe * 10 + nSlot;

        % Generate slot configuration.
        slotConfig = {...
            0, ...         % numerology
            slotIndex, ... % slot
            };

        cpConfig = ['cyclic_prefix::', upper(carrier.CyclicPrefix)];

        CCEREGMappingStr = 'pdcch_processor::cce_to_reg_mapping_type::NON_INTERLEAVED';

        coresetConfig = {...
            nSizeBWP, ...              % bwp_size_rb
            nStartBWP, ...             % bwp_start_rb
            startSymbolWithinSlot, ... % start_symbol_index
            Duration, ...              % duration
            frequencyResources, ...    % frequency_resources
            CCEREGMappingStr, ...      % cce_to_reg_mapping
            0, ...                     % reg_bundle_size
            0, ...                     % interleaver_size
            0, ...                     % shift_index
        };

        dciConfig = {...
            pdcch.RNTI, ...             % rnti
            pdcch.DMRSScramblingID, ... % n_id_pdcch_dmrs
            pdcch.DMRSScramblingID, ... % n_id_pdcch_data
            pdcch.RNTI, ...             % n_rnti
            ncce, ...                   % cce_index
            AggregationLevel, ...       % aggregation_level
            0.0, ...                    % dmrs_power_offset_dB
            0.0, ...                    % data_power_offset_dB
            message, ...                % payload
            'default_precoding', ...    % precoding
            };

        configCell = {
            'std::nullopt', ... % context
            slotConfig , ...    % slot
            cpConfig,...        % cp
            coresetConfig, ...  % coreset
            dciConfig, ...      % dci
            };

        % Generate the test case entry.
        testCaseString = testCase.testCaseToString(testID, ...
            configCell, true, '_test_output');

        % Add the test to the file header.
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHProcessorUnittest< srsTest.srsBlockUnittest
