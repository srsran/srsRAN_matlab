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
%   modScheme - Modulation scheme (see extended documentation for details).
%   nSymbols  - Number of modulated output symbols (257, 997).
%
%   srsDemodulationMapperUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors for the given modulation
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
        outputPath = {['testDemodulationMapper', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Number of modulated output symbols (257, 997).
        nSymbols = {257, 997}

        %Modulation scheme, described as a three-entry cell array. The first
        %entry is the modulation order, the second and the third are the
        %corresponding labels for MATLAB and SRSGNB, respectively.
        %Example: modScheme = {4, '16QAM', 'QAM16'}
        modScheme = {{1, 'BPSK', 'BPSK'}, {2, 'QPSK', 'QPSK'}, {4, '16QAM', 'QAM16'}, ...
            {6, '64QAM', 'QAM64'}, {8, '256QAM', 'QAM256'}}
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchmod(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'std::size_t          nsymbols;\n');
            fprintf(fileID, 'modulation_scheme    scheme;\n');
            fprintf(fileID, 'file_vector<cf_t>    symbols;\n');
            fprintf(fileID, 'file_vector<float>   noise_var;\n');
            fprintf(fileID, 'file_vector<int8_t>  soft_bits;\n');
            fprintf(fileID, 'file_vector<uint8_t> hard_bits;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, nSymbols, modScheme)
        %testvectorGenerationCases(TESTCASE, NSYMBOLS, MODSCHEME) Generates a test vector
        %   for the given number of symbols NSYMBOLS and modulation scheme and MODSCHEME.

            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeFloatFile
            import srsTest.helpers.writeComplexFloatFile
            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.channel_modulation.srsModulator

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % generate random test input as a bit sequence
            codeword = randi([0 1], nSymbols * modScheme{1}, 1);

            % call the symbol modulation MATLAB functions
            modulatedSymbols = srsModulator(codeword, modScheme{2});

            % create some noise samples with different variances (SNR in the range 0 -- 20 dB).
            normNoise = randn(nSymbols, 2) * [1; 1i] / sqrt(2);
            noiseStd = 0.1 + 0.9 * rand(nSymbols, 1);
            noiseVar = noiseStd.^2;

            % create noisy modulated symbols
            noisySymbols = modulatedSymbols + noiseStd .* normNoise;

            % write noise variances to a binary file
            testCase.saveDataFile('_test_noisevar', testID, @writeFloatFile, noiseVar);

            % write noisy symbols to a binary file
            testCase.saveDataFile('_test_input', testID, @writeComplexFloatFile, noisySymbols);

            % demodulate
            softBits = srsDemodulator(noisySymbols, modScheme{2}, noiseVar);

            % quantize
            softBitsQuant = quantize(softBits, modScheme{2});

            % write soft bits to a binary file
            testCase.saveDataFile('_test_soft_bits', testID, @writeInt8File, softBitsQuant);

            % hard decision
            hardBits = (1 - (softBitsQuant > 0)) / 2;

            % write hard bits into a binary file
            testCase.saveDataFile('_test_hard_bits', testID, @writeUint8File, hardBits);

            % generate the test case entry
            modSchemeString = ['modulation_scheme::', modScheme{3}];
            testCaseString = testCase.testCaseToString2(testID, {nSymbols, modSchemeString}, false, ...
                '_test_input', '_test_noisevar', '_test_soft_bits', '_test_hard_bits');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsDemodulationMapperUnittest

function softBitsQuant = quantize(softBits, mod)
    rangeLimitInt = 64;
    switch mod
        case {'BPSK', 'QPSK'}
            rangeLimitFloat = 200;
        case '16QAM'
            rangeLimitFloat = 100;
        otherwise % TODO decide range for 64QAM and 256QAM
            rangeLimitFloat = 50;
    end
    softBitsQuant = softBits;
    clipIdx = (abs(softBits) > rangeLimitFloat);
    softBitsQuant(clipIdx) = rangeLimitFloat * sign(softBitsQuant(clipIdx));
    softBitsQuant = round(softBitsQuant * rangeLimitInt / rangeLimitFloat);
end

