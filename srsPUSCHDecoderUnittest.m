%srsPUSCHDecoderUnittest Unit tests for PUSCH decoder functions.
%   This class implements unit tests for the PUSCH decoder functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUSCHDecoderUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUSCHDecoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_decoder').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUSCHDecoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHDecoderUnittest Properties (TestParameter):
%
%   SymbolAllocation        - Symbols allocated to the PUSCH transmission.
%   PRBAllocation           - PRBs allocated to the PUSCH transmission.
%   mcs                     - Modulation scheme index (0, 28).
%
%   srsPUSCHDecoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsPUSCHDecoderUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrPUSCHDecode.
classdef srsPUSCHDecoderUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_decoder'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pusch_decoder' tests will be erased).
        outputPath = {['testPUSCHDecoder', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Symbols allocated to the PUSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PUSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %PRBs allocated to the PUSCH transmission. Two PRB allocation cases are covered:
        %   full usage (0) and partial usage (1).
        PRBAllocation = {0, 1}

        %Modulation and coding scheme index.
        mcs = num2cell(0:28)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/codeblock_metadata.h"\n');

        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  segmenter_config                       config;\n');
            fprintf(fileID, '  std::vector<unsigned>                  rv_sequence;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>      llrs;\n');
            fprintf(fileID, '  file_vector<uint8_t>                   transport_block;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, PRBAllocation, mcs)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   PRBAllocation and mcs. Other parameters (e.g., the HARQProcessID) are
        %   generated randomly.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigureULSCHEncoder
            import srsMatlabWrappers.phy.helpers.srsConfigureULSCHDecoder
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.helpers.srsExpandMCS
            import srsMatlabWrappers.phy.helpers.srsGetModulation
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeInt8File

            % Generate a unique test ID
            testID = testCase.generateTestID;

            % Set randomized values
            if PRBAllocation == 0
                PRBstart = 0;
                PRBend = 24;
            else
                PRBstart = randi([0, 12]);
                PRBend = randi([13, 24]);
            end
            HARQProcessID = randi([1, 8]);

            % current fixed parameter values (e.g., single layer = single TB/codeword, no retransmissions)
            NSizeGrid = 25;
            NStartGrid = 0;
            NumLayersLoc = 1;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            PRBSet = PRBstart:PRBend;
            mcsTable = 'qam256';
            MultipleHARQProcesses = true;
            RVsequence = [0, 2, 3, 1];

            % skip those invalid configuration cases
            isMCSConfigOK = (~strcmp(mcsTable, 'qam256') || mcs < 28);

            if ~isMCSConfigOK
                return;
            end

            % configure the carrier according to the test parameters
            carrier = srsConfigureCarrier(NSizeGrid, NStartGrid);

            % get the target code rate (R) and modulation order (Qm) corresponding
            % to the current modulation and scheme configuration
            [R, Qm] = srsExpandMCS(mcs, mcsTable);
            TargetCodeRate = R/1024;
            Modulation = srsGetModulation(Qm);
            ModulationLoc = Modulation{1};

            % configure the PUSCH according to the test parameters
            pusch = srsConfigurePUSCH(NStartBWP, NSizeBWP, ModulationLoc, ...
                NumLayersLoc, SymbolAllocation, PRBSet);

            % get the encoded TB length
            [PUSCHIndices, PUSCHInfo] = nrPUSCHIndices(carrier, pusch);
            nofREs = length(PUSCHIndices);
            encodedTBLength = nofREs * Qm;

            % generate the TB to be encoded
            TransportBlockLength = nrTBS(ModulationLoc, NumLayersLoc, ...
                numel(PRBSet), PUSCHInfo.NREPerPRB, TargetCodeRate);
            TB = randi([0 1], TransportBlockLength, 1);

            % configure the PUSCH encoder and decoder
            ULSCHEncoder = srsConfigureULSCHEncoder(MultipleHARQProcesses, TargetCodeRate);
            ULSCHDecoder = srsConfigureULSCHDecoder(MultipleHARQProcesses, ...
                TargetCodeRate, TransportBlockLength);

            % add the generated TB to the encoder
            setTransportBlock(ULSCHEncoder, TB, HARQProcessID);

            nRVs = numel(RVsequence);
            cw = nan(encodedTBLength, nRVs);
            cwLLRs = nan(encodedTBLength, nRVs);

            for iRV = 1:nRVs
                RV = RVsequence(iRV);

                % call the PUSCH encoding MATLAB functions
                cw(:, iRV) = ULSCHEncoder(ModulationLoc, NumLayersLoc, encodedTBLength, RV, HARQProcessID);

                % Even though we could have different modulations, for the purposes of this
                % simulation, real-valued BPSK is enough to generate meaningul LLRs.
                cwLLRs(:, iRV) = 10 - 20 * cw(:, iRV);
                % add some (very little) noise
                snr = 20; % dB
                cwLLRs(:, iRV) = cwLLRs(:, iRV) + 10 * randn(encodedTBLength, 1) * 10^(-snr / 20);

            end
            % Decode the first transmission (it doesn't make sense to decode all
            % of them since MATLAB flushes the decoder buffer if the CRC is OK).
            rxTB = ULSCHDecoder(cwLLRs(:, 1), ModulationLoc, NumLayersLoc, RVsequence(1), HARQProcessID);
            % Check that there were no errors (expected, since the SNR is very high).
            assert(all(rxTB == TB), 'Decoding errors.');

            % clip and quantize
            cwLLRs(cwLLRs > 20) = 20;
            cwLLRs(cwLLRs < -20) = -20;
            cwLLRs = round(cwLLRs * 6); % this is codeblocks * 120 / 20
            % write the LLRs to a binary file
            testCase.saveDataFile('_test_input', testID, @writeInt8File, cwLLRs(:));

            % write the TBs to a binary file in packed format
            TBPkd = bitPack(TB);
            testCase.saveDataFile('_test_output', testID, @writeUint8File, TBPkd);

            % obtain the related LDPC encoding parameters
            info = nrULSCHInfo(pusch, TargetCodeRate, TransportBlockLength, 0, 0, 0);
            % generate the test case entry
            Nref = ULSCHEncoder.LimitedBufferSize;
            % 25344 is the maximum coded length of a code block and implies no limit on the buffer size
            if Nref >= 25344
              Nref = 0;
            end
            testCaseString = testCase.testCaseToString(testID, ...
                {{['ldpc::base_graph_t::BG', num2str(info.BGN)], 0, ...
                    ['modulation_scheme::', Modulation{2}], Nref, ...
                    NumLayersLoc, nofREs}, RVsequence}, false, '_test_input', '_test_output');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHDecoderUnittest
