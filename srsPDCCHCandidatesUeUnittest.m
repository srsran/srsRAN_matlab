%srsPDCCHCandidatesUeUnittest Unit tests for PDCCH Candidates generation in UE-Specific SS.
%   This class implements unit tests for the PDCCH Candidates in 
%   UE-Specific SS generation functions using the  matlab.unittest 
%   framework. The simplest use consists in creating an object with 
%       testCase = srsPDCCHCandidatesUeUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDCCHCandidatesUeUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdcch_candidates_ue').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'ran/pdcch').
%
%   srsPDCCHCandidatesUeUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDCCHCandidatesUeUnittest Properties (TestParameter):
%
%   numCCEs          - Number of CCE available in the CORESET.
%   numCandidates    - Number of candidates given by the SS configuration.
%   aggregationLevel - Number of CCE taken by a PDCCH transmission.
%
%   srsPDCCHCandidatesUeUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDCCHCandidatesUeUnittest Methods (Access = protected):
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

classdef srsPDCCHCandidatesUeUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdcch_candidates_ue'

        %Type of the tested block.
        srsBlockType = 'ran/pdcch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pdcch_candidates_ue' tests will be erased).
        outputPath = {['testPDCCHCandidatesUe', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %CORESET number of CCEs.
        numCCEs = {24, 48, 72, 96, 120, 144};

        %Number of candidates.
        numCandidates = {0, 1, 2, 3, 4, 5, 6, 7, 8};

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        aggregationLevel= {1, 2, 4, 8, 16};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "srsran/ran/pdcch/pdcch_candidates.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                '\n'...
                'struct test_case_t {\n'...
                '  pdcch_candidates_ue_ss_configuration config;\n'...
                '  pdcch_candidate_list                 candidates;\n'...
                '};\n'
                ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numCCEs, numCandidates, aggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given
        %   number of CCE, number of candidates and AggregationLevel. It
        %   randomly selects the CoresetId, the rnti and the slotNum. 

        % Skip test case if the number of CCEs for the CORESET cannot
        % fit all the candidates.
        if aggregationLevel * numCandidates > numCCEs
            return;
        end

        % Allow zero candidates only if the aggregation level is one.
        if (numCandidates == 0) && (aggregationLevel ~= 1)
            return;
        end

        % Select random parameters.
        CoresetId = randi([1, 11]);
        rnti = randi([1, 65535]);
        slotNum = randi([0, 159]);

        import srsTest.helpers.cellarray2str
        import srsLib.ran.pdcch.srsPDCCHCandidatesUE

        candidates = srsPDCCHCandidatesUE(numCCEs, numCandidates, aggregationLevel, CoresetId, rnti, slotNum);

        % Generate a unique test ID.
        testID = testCase.generateTestID;

        aggregationLevelString = sprintf('aggregation_level::n%d', aggregationLevel);
        CoresetIdString = sprintf('to_coreset_id(%d)', CoresetId);
        rntiString = sprintf('to_rnti(%d)', rnti);

        configCell = {...
            aggregationLevelString, ... % L
            numCandidates, ...          % nof_candidates
            numCCEs, ...                % nof_cce_coreset
            CoresetIdString, ...        % coreset_id
            rntiString, ...             % rnti
            slotNum, ...                % slot_index
            };

        configStr = cellarray2str(configCell, true);

        if isempty(candidates)
            candidatesCell = {};
        else
            candidatesCell = {candidates};
        end

        candidatesStr = cellarray2str(candidatesCell, length(candidates) <= 1);

        testCaseData = {configStr, candidatesStr};

        % Generate the test case entry.
        testCaseString = testCase.testCaseToString(testID, testCaseData,...
            false);

        % Add the test to the file header.
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHCandidatesUeUnittest< srsTest.srsBlockUnittest
