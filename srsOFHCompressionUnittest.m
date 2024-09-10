%srsOFHCompressionUnittest Unit tests for the IQ data compression used in OFH implementation.
%   This class implements unit tests for the IQ data compression functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsOFHCompressionUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsOFHCompressionUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'iq_compression').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/ru/compression').
%
%   srsOFHCompressionUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsOFHCompressionUnittest Properties (TestParameter):
%
%   method    - OFH compression method.
%   nPRBs     - Number of PRBs to be compressed.
%   cIQwidth  - Compressed IQ samples bit-width.
%
%   srsOFHCompressionUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given
%                               compression method and number of PRBs.
%
%   srsOFHCompressionUnittest Methods (Access = protected):
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

classdef srsOFHCompressionUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ofh_compression'

        %Type of the tested block, including layers.
        srsBlockType = 'ofh/compression'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ofh_compression' tests will be erased).
        outputPath = {['testOFHCompression', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Number of PRBs to be compressed (25, 257).
        nPRBs = {25, 275}

        %OFH compression method.
        %   Set to 'none' for testing no-compression case.
        %   Set to 'BFP' for testing block floating point case.
        method = {'none', 'BFP'}

        %Bit width of the compressed IQ samples including the sign bit.
        cIQwidth = {8, 9, 10, 11, 12, 13, 14, 15, 16};
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "srsran/adt/complex.h"\n');
            fprintf(fileID, '#include "srsran/%s/%s"\n', ...
                obj.srsBlockType, 'compression_params.h');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  std::size_t           nof_prb;\n');
            fprintf(fileID, '  ofh::compression_type type;\n');
            fprintf(fileID, '  unsigned              cIQ_width;\n');
            fprintf(fileID, '  float                 iq_scaling;\n');
            fprintf(fileID, '  file_vector<cf_t>     symbols;\n');
            fprintf(fileID, '  file_vector<int16_t>  compressed_IQs;\n');
            fprintf(fileID, '  file_vector<uint8_t>  compressed_params;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, nPRBs, method, cIQwidth)
        %testvectorGenerationCases(TESTCASE, NPRBS, METHOD, CIQWIDTH) Generates a test vector
        %   for the given number of PRB NPRBS, compression method METHOD and 
        %   compressed IQ width CIQWIDTH.

            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeInt16File
            import srsTest.helpers.writeComplexFloatFile
            import srsTest.helpers.approxbf16
            import srsLib.ofh.compression.srsCompressor

            % Generate a unique test ID by looking at the number of files generated so far.
            testID = testCase.generateTestID;

            % Generate random test input.
            iqData = (-1 + 2 * rand(nPRBs * 12, 2)) * [1; 1i];

            % Set two random PRBs to small values.
            smallPRBs = randperm(nPRBs, 2) - 1;
            for n = smallPRBs
                iqData(n*12+1:(n+1)*12) = (-1 + 2 * randi([0 1], 12, 2)) * [0.01; 0.01i];
            end

            % Approximate a brain floating point 16 conversion.
            iqData = approxbf16(iqData);

            % Scaling factor applied prior to quantization.
            scale = 0.25 + rand(1, 1);
            if (scale > 1)
                scale = 1.0;
            end
            iqDataScaled = iqData .* scale;

            if (strcmp(method, 'none'))
                % Simply quantize data based on cIQwidth test parameter.
                quantScaleFactor = 2 ^ (cIQwidth - 1) - 1;
                cIQData          = round(quantScaleFactor * iqDataScaled);
                cParam           = zeros(nPRBs, 1);
            else
                % Convert to int16 representation.
                quantScaleFactor = 2 ^ 15 - 1;
                iqDataQuantized  = round(quantScaleFactor * iqDataScaled);
                % Call the compression MATLAB function.
                [cIQData, cParam] = srsCompressor(iqDataQuantized, method, cIQwidth);
            end

            % Write input IQ data to a binary file.
            testCase.saveDataFile('_test_input', testID, @writeComplexFloatFile, iqData);

            % Convert complex data to array of int16.
            cIQDataInt16 = zeros(nPRBs * 12 * 2, 1);
            cIQDataInt16(1:2:end) = int16(real(cIQData));
            cIQDataInt16(2:2:end) = int16(imag(cIQData));

            % Write compressed PRBs to a binary file.
            testCase.saveDataFile('_test_c_output', testID, @writeInt16File, cIQDataInt16);

            % Write compression parameters to a binary file.
            testCase.saveDataFile('_test_c_param', testID, @writeUint8File, cParam);

            % Generate the test case entry.
            comprMethodString = ['ofh::compression_type::', method];
            testCaseString = testCase.testCaseToString(testID, {nPRBs, comprMethodString, cIQwidth, scale}, ...
                false, '_test_input', '_test_c_output', '_test_c_param');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsOFHCompressionUnittest
