%srsShortBlockEncoderUnittest Unit tests for the short-block encoder.
%   This class implements unit tests for the short-block encoder using the matlab.unittest
%   framework. The simplest use consists in creating an object with
%       testCase = srsShortBlockEncoderUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsShortBlockEncoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'short_block_encoder').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_coding/short').
%
%   srsShortBlockEncoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsShortBlockEncoderUnittest Properties (TestParameter):
%
%   msgLength - Length of sequence of bits to encode (1...11).
%   modOrder  - Number of bits per modulation symbol (1, 2, 4, 6, 8).
%
%   srsShortBlockEncoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given message length
%                               and modulation order.
%
%   srsShortBlockEncoderUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrUCIEncode.

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

classdef srsShortBlockEncoderUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'short_block_encoder'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_coding/short'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'short_block_encoder' tests will be erased).
        outputPath = {['testShortBlockEncoder', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Length of sequence of bits to encode (1...11).
        msgLength = num2cell(1:11)

        %Number of bits per modulation symbol (1, 2, 4, 6, 8).
        modOrder = num2cell([1, 2, 4, 6, 8])
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.

            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsran/ran/sch/modulation_scheme.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'unsigned nof_messages            = 0;\n');
            fprintf(fileID, 'unsigned message_length            = 0;\n');
            fprintf(fileID, 'unsigned codeblock_length           = 0;\n');
            fprintf(fileID, 'modulation_scheme mod = {};\n');
            fprintf(fileID, 'file_vector<uint8_t> messages;\n');
            fprintf(fileID, 'file_vector<uint8_t> codeblocks;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, msgLength, modOrder)
        %testvectorGenerationCases Generates a test vector for the given message length
        %   and modulation order.

            import srsTest.helpers.writeUint8File
            import srsLib.phy.helpers.srsGetModulation

            % When encoding more than 2 bits, the output doesn't depend on the
            % modulation. So we execute the test only for modOrder == 1.
            if ((msgLength > 2) && (modOrder > 1))
                return;
            end

            % generate a unique test ID
            testID = obj.generateTestID;

            % random messages
            nMessages = 10;
            messages = randi([0, 1], msgLength, nMessages);

            if msgLength == 1
                blkLength = modOrder;
            elseif msgLength == 2
                blkLength = 3 * modOrder;
            else
                blkLength = 32;
            end

            % Block length after rate-matching: at least as long as the basic block length.
            blkLength = round(blkLength * (1 + randi([0, 8]) / 4));

            [modScheme, modSchemeSRS] = srsGetModulation(modOrder);

            % encode
            codeblocks = nan(blkLength, nMessages);
            for iMessage = 1:nMessages
                % recall modScheme is ignored if msgLength > 2
                codeblocks(:, iMessage) = nrUCIEncode(messages(:, iMessage), ...
                    blkLength, modScheme);
            end

            % use SRS convention for placeholders
            codeblocks(codeblocks == -1) = 255;
            codeblocks(codeblocks == -2) = 254;

            % write messages
            obj.saveDataFile('_test_input', testID, @writeUint8File, messages(:));

            % write codeblocks
            obj.saveDataFile('_test_output', testID, @writeUint8File, codeblocks(:));

            modScheme = ['modulation_scheme::', modSchemeSRS];

            % generate the test case entry
            testCaseString = obj.testCaseToString(testID, {nMessages, ...
                msgLength, blkLength, modScheme}, false, '_test_input', '_test_output');

            % add the test to the file header
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function addTestIncludesToHeaderFile
    end % of methods (Access = protected)

end % of classdef srsShortBlockEncoderUnittest
