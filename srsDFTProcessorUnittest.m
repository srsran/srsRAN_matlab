%srsDFTProcessorUnittest Unit tests for DFT processor functions.
%   This class implements unit tests for the DFT processor functions using
%   the matlab.unittest framework. The simplest use consists in creating an
%   object with
%       testCase = srsDFTProcessorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsDFTProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dft_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/generic_functions').
%
%   srsDFTProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsDFTProcessorUnittest Properties (TestParameter):
%
%   size      - DFT size.
%   direction - DFT direction flag ('direct', 'inverse').
%
%   srsDFTProcessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates test vectors according to the provided
%                               parameters.
%
%   srsDFTProcessorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, fft and ifft.

%   Copyright 2021-2023 Software Radio Systems Limited
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

classdef srsDFTProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dft_processor'

        %Type of the tested block.
        srsBlockType = 'phy/generic_functions'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dft_processor' tests will be erased).
        outputPath = {['testDFTprocessor',  char(datetime('now', 'Format', ...
            'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %DFT size.
        DFTsize = {128, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096, ...
            4608, 6144, 9216, 12288, 18432, 24576, 36864, 49152}

        %DFT direction flag ('direct', 'inverse').
        direction = {'direct', 'inverse'}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchmod(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations)
        %   to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'dft_processor::configuration config;\n');
            fprintf(fileID, 'file_vector<cf_t> data;\n');
            fprintf(fileID, 'file_vector<cf_t> transform;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, DFTsize, direction)
        %testvectorGenerationCases Generates a test vector for the given DFTsize
        %   and direction.

            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate the DFT input data.
            inputData = [1 1j] * (2 * rand(2, DFTsize) - 1);

            % Write the DFT input data into a binary file.
            testCase.saveDataFile('_test_input', testID, ...
                 @writeComplexFloatFile, inputData);

            % Call the DFT MATLAB functions.
            if strcmp(direction, 'direct')
                outputData = fft(inputData, DFTsize);
            else
                % Apply the required scaling in the inverse case.
                outputData = ifft(inputData, DFTsize) * DFTsize;
            end

            % Write the DFT results into a binary file.
            testCase.saveDataFile('_test_output', testID, ...
                @writeComplexFloatFile, outputData);

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, {DFTsize, ...
                ['dft_processor::direction::', upper(direction)]}, true, ...
                '_test_input', '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsDFTProcessorUnittest
