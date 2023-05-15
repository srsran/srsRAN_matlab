%srsUCIDecoderUnittest Unit tests for UCI decoder functions.
%   This class implements unit tests for Uplink Control Information (UCI) decoder
%   functions using the matlab.unittest framework. The simplest use consists in
%   creating an object with testCase = srsUCIDecoderUnittest and then running all
%   the tests with
%      testResults = testCase.run
%
%   srsUCIDecoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'uci_decoder').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsUCIDecoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsUCIDecoderUnittest Properties (TestParameter):
%
%   A                       - Length in bits of the UCI message.
%   Modulation               - Modulation scheme.
%
%   srsUCIDecoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsUCIDecoderUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrPUSCHDecode.
classdef srsUCIDecoderUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'uci_decoder'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'uci_decoder' tests will be erased).
        outputPath = {['testUCIDecoder', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Length in bits of the UCI message. Four different cases are covered: single
        %   UCI bit (1), two UCI bits (2), length between 3 and 11 UCI bits (3-11)
        %   and length between 12 and 1706 UCI bits (12-1706).
        A = [num2cell(1:12) {19, 20, 200, 500, 1000, 1706}]

        %Modulation scheme.
        Modulation = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/uci_decoder.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/log_likelihood_ratio.h"\n');
            fprintf(fileID, '#include "srsran/ran/modulation_scheme.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  unsigned                          message_length = 0;\n');
            fprintf(fileID, '  unsigned                          llr_length     = 0;\n');
            fprintf(fileID, '  uci_decoder::configuration        config;\n');
            fprintf(fileID, '  file_vector<uint8_t>              message;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> llr;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, A, Modulation)
        %testvectorGenerationCases Generates a test vector for the given A and
        %   Modulation. Other parameters (e.g., E) are generated randomly.

            import srsMatlabWrappers.phy.helpers.srsGetBitsSymbol
            import srsMatlabWrappers.phy.helpers.srsModulationFromMatlab
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeInt8File

            % The current srsRAN implementation only supports UCI messages
            % up to 11 bits.
            isASupported = A < 12;
            if (~isASupported)
                return;
            end

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Set randomized values.
            UCIbits = randi([0 1], A, 1);
            % The length of the rate-matched UCI codeword, E, depends on A and on
            % the modulation scheme (maximum length = 8192).
            minE = A + 1;
            % For sequences larger than 12 bits there will be 11 CRC bits.
            if A >= 12
                minE = A + 11;
            end
            bitsSymbol = srsGetBitsSymbol(Modulation);
            maxE = max([floor(8192 / bitsSymbol), minE]);
            E = bitsSymbol * randi([minE maxE], 1, 1);

            % Current fixed parameter values (e.g., SNR).
            snrdB = 20;

            % Encode the UCI bits.
            UCICodeWord = nrUCIEncode(UCIbits, E, Modulation);

            % Replace placeholders -1 (x) and -2 (y) as part of the descrambling.
            UCICodeWord(UCICodeWord == -1) = 1;
            UCICodeWord(UCICodeWord == -2) = UCICodeWord(find(UCICodeWord == -2) - 1);

            % Estimate the LLR soft bits.
            modulatedUCI = nrSymbolModulate(UCICodeWord, Modulation);
            rxSignal = awgn(modulatedUCI, snrdB);
            LLRSoftBits = nrSymbolDemodulate(rxSignal, Modulation);

            % Decode the received UCI LLR soft bits.
            decodedUCIBits = nrUCIDecode(LLRSoftBits, A, Modulation);

            % Clip and quantize the LLRs.
            LLRSoftBits(LLRSoftBits > 20) = 20;
            LLRSoftBits(LLRSoftBits < -20) = -20;
            LLRSoftBits = round(LLRSoftBits * 6); % this is LLRSoftBits * 120 / 20
            % Write the LLRs to a binary file.
            testCase.saveDataFile('_test_input', testID, @writeInt8File, LLRSoftBits(:));

            % Write the decoded UCI message to a binary file.
            testCase.saveDataFile('_test_output', testID, @writeUint8File, decodedUCIBits);

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, ...
                {A, E, {srsModulationFromMatlab(Modulation, 'full')}}, ...
                false, '_test_output', '_test_input');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsUCIDecoderUnittest
