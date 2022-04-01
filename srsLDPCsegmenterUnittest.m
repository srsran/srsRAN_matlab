%srsLDPCsegmenterUnittest Unit tests for the LDPC segmentation functions.
%   This class implements unit tests for the LDPC segmentation functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsLDPCsegmenterUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsLDPCsegmenterUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ldpc_segmenter').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_coding/ldpc').
%
%   srsLDPCsegmenterUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsLDPCsegmenterUnittest Properties (TestParameter):
%
%   cases  - Configurations to test.
%
%   srsLDPCsegmenterUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors for the given configuration.
%
%   srsLDPCsegmenterUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrCodeBlockSegmentLDPC.

classdef srsLDPCsegmenterUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ldpc_segmenter'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_coding/ldpc'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ldpc_segmenter' tests will be erased).
        outputPath = {['testLDPCsegmenter', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Configurations to test. A configuration is given by a struct with fields "length",
        %   the length of transport block in number of bits, and "bg", the base graph of
        %   the LDPC encoder.
        cases = {struct('length', 96, 'bg', 1), ...
                 struct('length', 600, 'bg', 1), ...
                 struct('length', 4000, 'bg', 1), ...
                 struct('length', 12000, 'bg', 1), ...
                 struct('length', 40000, 'bg', 1), ...
                 struct('length', 96, 'bg', 2), ...
                 struct('length', 320, 'bg', 2), ...
                 struct('length', 320, 'bg', 2), ...
                 struct('length', 600, 'bg', 2), ...
                 struct('length', 4000, 'bg', 2), ...
                 struct('length', 12000, 'bg', 2)};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFilePHY(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.

            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'unsigned tbs                     = 0;\n');
            fprintf(fileID, 'unsigned bg                      = 0;\n');
            fprintf(fileID, 'unsigned nof_segments            = 0;\n');
            fprintf(fileID, 'unsigned segment_length          = 0;\n');
            fprintf(fileID, 'file_vector<uint8_t> trans_block;\n');
            fprintf(fileID, 'file_vector<uint8_t> segments;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, cases)
        %testvectorGenerationCases Generates a test vectors for the given configuration.

            import srsMatlabWrappers.phy.upper.channel_coding.ldpc.srsLDPCsegmenter
            import srsTest.helpers.writeUint8File

            % generate a unique test ID
            testID = obj.generateTestID;

            % random transport block
            transBlock = randi([0, 1], cases.length, 1);

            % add CRC and split into segments
            segments = srsLDPCsegmenter(transBlock, cases.bg);

            % write packed format of transport block
            transBlockPkd = reshape(transBlock, 8, [])' * 2.^(7:-1:0)';
            obj.saveDataFile('_test_input', testID, @writeUint8File, transBlockPkd);

            % write concatenated segments
            obj.saveDataFile('_test_output', testID, @writeUint8File, segments(:));

            [segmentLength, nSegments] = size(segments);
            % generate the test case entry
            testCaseString = obj.testCaseToString(testID, true, ...
                {cases.length, cases.bg, nSegments, segmentLength}, false);

            % add the test to the file header
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);
        end
    end

end
