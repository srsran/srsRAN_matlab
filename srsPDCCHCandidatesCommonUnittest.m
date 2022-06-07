%srsPDCCHCandidatesCommonUnittest Unit tests for PDCCH Candidates generation in Common SS.
%   This class implements unit tests for the PDCCH Candidates in Common SS
%   generation functions using the  matlab.unittest framework. The simplest
%   use consists in creating an object with 
%       testCase = srsPDCCHCandidatesCommonUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPDCCHCandidatesCommonUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdcch_candidates_common').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   nofNCellID       - Number of possible PHY cell identifiers.
%   REGBundleSizes   - Possible REGBundle sizes  for each CORESET Duration.
%   InterleaverSizes - Possible interleaver sizes.
%
%   srsPDCCHCandidatesCommonUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDCCHCandidatesCommonUnittest Properties (TestParameter):
%
%   Duration         - CORESET Duration.
%   CCEREGMapping    - CCE-to-REG mapping.
%   AggregationLevel - PDCCH aggregation level.
%
%   srsPDCCHCandidatesCommonUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDCCHCandidatesCommonUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.

classdef srsPDCCHCandidatesCommonUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdcch_candidates_common'

        %Type of the tested block.
        srsBlockType = 'ran/pdcch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pddch_processor' tests will be erased).
        outputPath = {['testPDCCHCandidatesCommon', datestr(now, 30)]}
    end

    properties (TestParameter)
        %CORESET number of CCEs.
        numCCEs = {24, 48, 72, 96, 120, 144};

        %Number of candidates.
        numCandidates = {0, 1, 2, 3, 4, 5, 6, 7, 8};

        %PDCCH aggregation level (1, 2, 4, 8, 16).
        aggregationLevel= {1, 2, 4, 8, 16}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsgnb/ran/pdcch/pdcch_candidates.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                '\n'...
                'struct test_case_t {\n'...
                '  pdcch_candidates_common_ss_configuration config;\n'...
                '  pdcch_candidate_list                     candidates;\n'...
                '};\n'
                ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numCCEs, numCandidates, aggregationLevel)
        %testvectorGenerationCases Generates a test vector for the given CORESET duration,
        %   CCEREGMapping and AggregationLevel, while using randomly generated NCellID,
        %   RNTI and codeword.

        % Skip test case if the number of CCEs for the CORESET cannot
        % fit all the candidates.
        if aggregationLevel * numCandidates > numCCEs
            return;
        end

        % Allow zero candidates only if the aggregation level is one.
        if numCandidates == 0 && aggregationLevel ~= 1
            return;
        end

        import srsTest.helpers.array2str
        import srsTest.helpers.cellarray2str
        import srsMatlabWrappers.ran.pdcch.srsPDCCHCandidatesCommon

        candidates = srsPDCCHCandidatesCommon(numCCEs, numCandidates, aggregationLevel);

        % generate a unique test ID
        testID = testCase.generateTestID;

        aggregationLevelString = ['aggregation_level::n' num2str(aggregationLevel)];

        configStr = cellarray2str({aggregationLevelString, numCandidates, numCCEs}, true);

        if length(candidates) == 0
            candidatesCell = {};
        else
            candidatesCell = {candidates};
        end

        candidatesStr = cellarray2str(candidatesCell, length(candidates) <= 1);

        testCaseData = {configStr, candidatesStr};

        % generate the test case entry
        testCaseString = testCase.testCaseToString(testID, testCaseData,...
            false);

        % add the test to the file header
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDCCHCandidatesCommonUnittest< srsTest.srsBlockUnittest
