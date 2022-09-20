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
%   modScheme               - Modulation scheme (see extended documentation for details).
%
%   srsUCIDecoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
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
        outputPath = {['testUCIDecoder', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Length in bits of the UCI message. Four different cases are covered: single
        %   UCI bit (1), two UCI bits (2), length between 3 and 11 UCI bits (3-11)
        %   and length between 12 and 1706 UCI bits (12-1706).
        A = {1, 2, randi([3 11], 1, 1), randi([12 1706], 1, 1)}

        %Modulation scheme, described as a three-entry cell array. The first
        %entry is the modulation order, the second and the third are the
        %corresponding labels for MATLAB and SRSGNB, respectively.
        %Example: modScheme = {4, '16QAM', 'QAM16'}
        modScheme = {{1, 'pi/2-BPSK', 'BPSK'}, {2, 'QPSK', 'QPSK'}, {4, '16QAM', 'QAM16'}, ...
            {6, '64QAM', 'QAM64'}, {8, '256QAM', 'QAM256'}}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            %fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');

        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  uci_decoder::configuration        config;\n');
            fprintf(fileID, '  file_vector<uint8_t>              message;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio> llr;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, A, modScheme)
        %testvectorGenerationCases Generates a test vector for the given A and
        %   modScheme. Other parameters (e.g., E) are generated randomly.

            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeInt8File

            % the current srsGNB implementation only supports UCI messages
            % up to 11 bits
            isASupported = A < 12;

            if (isASupported)
                % Generate a unique test ID
                testID = testCase.generateTestID;
    
                % set randomized values
                UCIbits = randi([0 1], A, 1);
                % the length of the rate-matched UCI codeword, E, depends on A and on
                %     the modulation scheme (maximum length = 8192)
                minE = A + 1;
                % for sequences larger than 12 bits there will be 11 CRC bits
                if A >= 12
                    minE = A + 11;
                end;
                maxE = floor(8192 / modScheme{1});
                if maxE < minE
                    maxE = minE;
                end;
                E = modScheme{1} * randi([minE maxE], 1, 1);
    
                % current fixed parameter values (e.g., SNR)
                snrdB = 20;
    
                % encode the UCI bits
                UCICodeWord = nrUCIEncode(UCIbits, E, modScheme{2});
    
                % replace placeholders -1 (x) and -2 (y) as part of the descrambling.
                UCICodeWord(UCICodeWord == -1) = 1;
                UCICodeWord(UCICodeWord == -2) = UCICodeWord(find(UCICodeWord == -2) - 1);
    
                % estimate the LLR soft bits
                modulatedUCI = nrSymbolModulate(UCICodeWord, modScheme{2});
                rxSignal = awgn(modulatedUCI, snrdB);
                LLRSoftBits = nrSymbolDemodulate(rxSignal, modScheme{2});
    
                % decode the received UCI LLR soft bits
                decodedUCIBits = nrUCIDecode(LLRSoftBits, A, modScheme{2});
    
                % clip and quantize the LLRs
                LLRSoftBits(LLRSoftBits > 20) = 20;
                LLRSoftBits(LLRSoftBits < -20) = -20;
                LLRSoftBits = round(LLRSoftBits * 6); % this is codeblocks * 120 / 20
                % write the LLRs to a binary file
                testCase.saveDataFile('_test_input', testID, @writeInt8File, LLRSoftBits(:));
    
                % write the decoded UCI message to a binary file
                testCase.saveDataFile('_test_output', testID, @writeUint8File, decodedUCIBits);
    
                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, ...
                    {['modulation_scheme::', modScheme{3}], A, E}, ...
                    true, '_test_output', '_test_input');
    
                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsUCIDecoderUnittest
