%srsShortBlockDetectorUnittest Unit tests for the short-block detector.
%   This class implements unit tests for the short-block detector using the matlab.unittest
%   framework. The simplest use consists in creating an object with
%       testCase = srsShortBlockDetectorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsShortBlockDetectorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'short_block_detector').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_coding/short').
%
%   srsShortBlockDetectorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsShortBlockDetectorUnittest Properties (TestParameter):
%
%   msgLength - Length of sequence of decoded bits (1...11).
%   modOrder  - Number of bits per modulation symbol (1, 2, 4, 6, 8).
%
%   srsShortBlockDetectorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given message length
%                               and modulation order.
%
%   srsShortBlockDetectorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrUCIDecode.

classdef srsShortBlockDetectorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'short_block_detector'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_coding/short'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'short_block_detector' tests will be erased).
        outputPath = {['testShortBlockDetector', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Length of sequence of decoded bits (1...11).
        msgLength = num2cell(1:11)

        %Number of bits per modulation symbol (1, 2, 4, 6, 8).
        modOrder = num2cell([1, 2, 4, 6, 8])
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.

            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsgnb/ran/modulation_scheme.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/log_likelihood_ratio.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'unsigned nof_messages     = 0;\n');
            fprintf(fileID, 'unsigned message_length   = 0;\n');
            fprintf(fileID, 'unsigned codeblock_length = 0;\n');
            fprintf(fileID, 'modulation_scheme mod     = {};\n');
            fprintf(fileID, 'file_vector<log_likelihood_ratio> codeblocks;\n');
            fprintf(fileID, 'file_vector<uint8_t> messages;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, msgLength, modOrder)
        %testvectorGenerationCases Generates a test vector for the given message length
        %   and modulation order.

            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeInt8File
            import srsMatlabWrappers.phy.helpers.srsGetModulation

            % When encoding more than 2 bits, the output doesn't depend on the
            % modulation. So we execute the test only for modOrder == 1.
            if ((msgLength > 2) && (modOrder > 1))
                return;
            end

            % generate a unique test ID
            testID = obj.generateTestID;

            if msgLength == 1
                blkLength = modOrder;
            elseif msgLength == 2
                blkLength = 3 * modOrder;
            else
                blkLength = 32;
            end

            % Block length after rate-matching: at least as long as the basic block length.
            blkLength = round(blkLength * (1 + randi([0, 8]) / 4));

            % random messages
            nMessages = 10;
            messages = randi([0, 1], msgLength, nMessages);

            modSchemeLabels = srsGetModulation(modOrder);

            codeblocks = nan(blkLength, nMessages);
            for iMessage = 1:nMessages
                % recall modScheme is ignored if msgLength > 2
                codeblocks(:, iMessage) = nrUCIEncode(messages(:, iMessage), ...
                    blkLength, modSchemeLabels{1});
            end

            % Replace placeholders.
            codeblocks(codeblocks == -1) = 1;
            codeblocks(codeblocks == -2) = codeblocks(find(codeblocks == -2) - 1);

            % Even though we have different modulations, we cast the codeblocks as simple
            % BPSK-like LLRs.
            codeblocks = 10 - 20 * codeblocks;
            % add some noise (SNR 20 dB)
            codeblocks = codeblocks + randn(blkLength, nMessages);

            % clip and quantize
            codeblocks(abs(codeblocks) > 20) = 20;
            codeblocks = round(codeblocks * 6); % this is codeblocks * 120 / 20

            % decode
            messages = nan(msgLength, nMessages);
            for iMessage = 1:nMessages
                % recall modScheme is ignored if msgLength > 2
                messages(:, iMessage) = nrUCIDecode(codeblocks(:, iMessage), ...
                    msgLength, modSchemeLabels{1});
            end

            % write codeblocks
            obj.saveDataFile('_test_input', testID, @writeInt8File, codeblocks(:));

            % write messages
            obj.saveDataFile('_test_output', testID, @writeUint8File, messages(:));

            modScheme = ['modulation_scheme::', modSchemeLabels{2}];

            % generate the test case entry
            testCaseString = obj.testCaseToString(testID, {nMessages, ...
                msgLength, blkLength, modScheme}, false, '_test_input', '_test_output');

            % add the test to the file header
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function addTestIncludesToHeaderFile
    end % of methods (Access = protected)

end % of classdef srsShortBlockDetectorUnittest
