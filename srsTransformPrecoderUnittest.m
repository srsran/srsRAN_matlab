%srsTransformPrecoderUnittest Unit tests for transform precoding functions.
%   This class implements unit tests for the transform precoding
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with 
%      testCase = srsTransformPrecoderUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsTransformPrecoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'transform_precoder').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/generic_functions/transform_precoding').
%
%   srsTransformPrecoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsTransformPrecoderUnittest Properties (TestParameter):
%
%   NumPRB               - Number of resource blocks.
%   NumOFDMSymbols       - Number of OFDM symbols to perform precoding.
%
%   srsTransformPrecoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsTransformPrecoderUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrULSCHDemultiplex, nrULSCHInfo.

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

classdef srsTransformPrecoderUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'transform_precoder'

        %Type of the tested block.
        srsBlockType = 'phy/generic_functions/transform_precoding'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ulsch_demultiplex' tests will be erased).
        outputPath = {['testTransformDeprecoder', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Valid number of RB to apply transform precode.
        NumPRB = {...
              1,   2,   3,   4,   5,   6,   8,   9,  10,  12,  15,  16, ...
             18,  20,  24,  25,  27,  30,  32,  36,  40,  45,  48,  50, ...
             54,  60,  64,  72,  75,  80,  81,  90,  96, 100, 108, 120, ...
            125, 128, 135, 144, 150, 160, 162, 180, 192, 200, 216, 225, ...
            240, 243, 250, 256, 270};

        %Number of OFDM symbols to apply transform precoding.
        NumOFDMSymbols = {1, 2, 4, 8, 12}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "srsran/adt/complex.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  unsigned          M_rb;\n');
            fprintf(fileID, '  file_vector<cf_t> x;\n');
            fprintf(fileID, '  file_vector<cf_t> y;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, ...
                NumPRB, NumOFDMSymbols)
        %testvectorGenerationCases Generates a test vectors given the
        %   combinations of MRB and  nofOFDMSymbols. 

            import srsTest.helpers.writeComplexFloatFile
            import srsTest.helpers.approxbf16

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            % Calculate total number of subcarriers.
            NumSC = NumPRB * 12 * NumOFDMSymbols;

            % Generate random QPSK subcarriers.
            x = (randi([0 1], NumSC, 2) * 2 - 1) * [1; 1i];

            % Approximate subcarriers to brain float.
            x = approxbf16(x);

            % Apply transform precoding.
            y = nrTransformPrecode(x, NumPRB);

            % Approximate transform precoded to brain float.
            y = approxbf16(y);

            % Save data before transform precoding.
            testCase.saveDataFile('_test_input_x', testID, @writeComplexFloatFile, x);

            % Save data after transform precoding.
            testCase.saveDataFile('_test_output_y', testID, @writeComplexFloatFile, y);


            testCaseString = testCase.testCaseToString(testID, ...
                {NumPRB}, false, '_test_input_x', '_test_output_y');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsTransformPrecoderUnittest
