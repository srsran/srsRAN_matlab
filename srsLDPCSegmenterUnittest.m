%srsLDPCSegmenterUnittest Unit tests for the LDPC segmentation functions.
%   This class implements unit tests for the LDPC segmentation functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsLDPCSegmenterUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsLDPCSegmenterUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ldpc_segmenter').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_coding/ldpc').
%
%   srsLDPCSegmenterUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsLDPCSegmenterUnittest Properties (TestParameter):
%
%   cases  - Configurations to test.
%
%   srsLDPCSegmenterUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given configuration.
%
%   srsLDPCSegmenterUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrCodeBlockSegmentLDPC.

classdef srsLDPCSegmenterUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ldpc_segmenter'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_coding/ldpc'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ldpc_segmenter' tests will be erased).
        outputPath = {['testLDPCsegmenter', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
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
                 struct('length', 600, 'bg', 2), ...
                 struct('length', 4000, 'bg', 2), ...
                 struct('length', 12000, 'bg', 2), ...
                 struct('length', 40000, 'bg', 2)};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
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
        %testvectorGenerationCases Generates a test vector for the given configuration.

            import srsMatlabWrappers.phy.upper.channel_coding.ldpc.srsLDPCsegmenter
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File

            % generate a unique test ID
            testID = obj.generateTestID;

            % random transport block
            transBlock = randi([0, 1], cases.length, 1);

            % add CRC and split into segments
            segments = srsLDPCsegmenter(transBlock, cases.bg);

            % write packed format of transport block
            transBlockPkd = bitPack(transBlock);
            obj.saveDataFile('_test_input', testID, @writeUint8File, transBlockPkd);

            % write concatenated segments
            obj.saveDataFile('_test_output', testID, @writeUint8File, segments(:));

            [segmentLength, nSegments] = size(segments);
            % generate the test case entry
            testCaseString = obj.testCaseToString(testID, ...
                {cases.length, cases.bg, nSegments, segmentLength}, false, ...
                '_test_input', '_test_output');

            % add the test to the file header
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function addTestIncludesToHeaderFile
    end % of methods (Access = protected)

end % of classdef srsLDPCSegmenterUnittest
