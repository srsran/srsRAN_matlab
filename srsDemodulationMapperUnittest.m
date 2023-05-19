%srsDemodulationMapperUnittest Unit tests for the modulation mapper functions.
%   This class implements unit tests for the demodulation mapper functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsDemodulationMapperUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsDemodulationMapperUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'demodulation_mapper').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_modulation').
%
%   srsDemodulationMapperUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsDemodulationMapperUnittest Properties (TestParameter):
%
%   Modulation - Modulation scheme (see extended documentation for details).
%   nSymbols  - Number of modulated output symbols (257, 997).
%
%   srsDemodulationMapperUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given modulation
%                               scheme and number of symbols.
%
%   srsDemodulationMapperUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.

classdef srsDemodulationMapperUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'demodulation_mapper'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_modulation'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'modulation_mapper' tests will be erased).
        outputPath = {['testDemodulationMapper', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Number of modulated output symbols (257, 997).
        nSymbols = {257, 997}

        %Modulation scheme.
        Modulation = {'BPSK', 'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'}
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchmod(obj, fileID);
            fprintf(fileID, '#include "srsran/phy/upper/log_likelihood_ratio.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'std::size_t          nsymbols;\n');
            fprintf(fileID, 'modulation_scheme    scheme;\n');
            fprintf(fileID, 'file_vector<cf_t>    symbols;\n');
            fprintf(fileID, 'file_vector<float>   noise_var;\n');
            fprintf(fileID, 'file_vector<log_likelihood_ratio>  soft_bits;\n');
            fprintf(fileID, 'file_vector<uint8_t> hard_bits;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, nSymbols, Modulation)
        %testvectorGenerationCases(TESTCASE, NSYMBOLS, MODSCHEME) Generates a test vector
        %   for the given number of symbols NSYMBOLS and modulation scheme and MODSCHEME.

            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeFloatFile
            import srsTest.helpers.writeComplexFloatFile
            import srsLib.phy.helpers.srsGetBitsSymbol
            import srsLib.phy.helpers.srsModulationFromMatlab
            import srsLib.phy.upper.channel_modulation.srsDemodulator
            import srsLib.phy.upper.channel_modulation.srsModulator

            % Generate a unique test ID by looking at the number of files generated so far.
            testID = testCase.generateTestID;

            % Generate random test input as a bit sequence.
            bitsSymbol = srsGetBitsSymbol(Modulation);
            codeword = randi([0 1], nSymbols * bitsSymbol, 1);

            % Call the symbol modulation MATLAB functions.
            modulatedSymbols = srsModulator(codeword, Modulation);

            % Create some noise samples with different variances (SNR in the range 0 -- 20 dB).
            normNoise = randn(nSymbols, 2) * [1; 1i] / sqrt(2);
            noiseStd = 0.1 + 0.9 * rand(nSymbols, 1);
            noiseVar = noiseStd.^2;

            % Create noisy modulated symbols.
            noisySymbols = modulatedSymbols + noiseStd .* normNoise;

            % Write noise variances to a binary file.
            testCase.saveDataFile('_test_noisevar', testID, @writeFloatFile, noiseVar);

            % Write noisy symbols to a binary file.
            testCase.saveDataFile('_test_input', testID, @writeComplexFloatFile, noisySymbols);

            % Demodulate (note that srsDemodulator returns integer values
            % that can be directly assigned to int8_t variables).
            softBits = srsDemodulator(noisySymbols, Modulation, noiseVar);

            % Write soft bits to a binary file.
            testCase.saveDataFile('_test_soft_bits', testID, @writeInt8File, softBits);

            % Hard decision.
            hardBits = (1 - (softBits > 0));

            % Write hard bits into a binary file.
            testCase.saveDataFile('_test_hard_bits', testID, @writeUint8File, hardBits);

            % Generate the test case entry.
            modSchemeString = srsModulationFromMatlab(Modulation, 'full');
            testCaseString = testCase.testCaseToString(testID, {nSymbols, modSchemeString}, false, ...
                '_test_input', '_test_noisevar', '_test_soft_bits', '_test_hard_bits');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsDemodulationMapperUnittest
