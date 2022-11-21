%srsDFTprocessorUnittest Unit tests for OFDM modulator functions.
%   This class implements unit tests for the DFT function using the matlab.unittest
%   framework. The simplest use consists in creating an object with
%       testCase = srsDFTprocessorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsDFTprocessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dft_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/generic_functions').
%
%   srsDFTprocessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsDFTprocessorUnittest Properties (TestParameter):
%
%   size      - Defines the DFT size.
%   direction - Defines if the DFT is direct or inverse.
%
%   srsDFTprocessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates test vectors according to the provided
%                               parameters.
%
%   srsDFTprocessorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest and nrOFDMModulate.
classdef srsDFTprocessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dft_processor'

        %Type of the tested block.
        srsBlockType = 'phy/generic_functions'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ofdm_modulator' tests will be erased).
        outputPath = {['testDFTprocessor', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Defines the DFT size.
        DFTsize = {128, 139, 256, 384, 512, 768, 839, 1024, 1536, 2048, ...
            3072, 4096, 4608, 6144, 9216, 12288, 18432, 24576, 36864, 49152}

        %Defines if the DFT is direct or inverse.
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

    methods (TestClassSetup)
        function classSetup(testCase)
            orig = rng;
            testCase.addTeardown(@rng,orig)
            rng('default');
        end
    end

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
                % apply the required scaling in the inverse case
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
end % of classdef srsDFTprocessorUnittest
