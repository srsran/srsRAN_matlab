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
%   srsPUSCHDecoderUnittest Methods (TestTags = {'testmex'}):
%
%   mexTest  - Tests the mex wrapper of the SRSRAN PUSCH decoder.
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
        outputPath = {['testPUSCHDecoder', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
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

    properties (Constant, Hidden)
        % Currently fixed parameter values (e.g., single layer = single TB/codeword, no retransmissions)
        % Resuource grid size and first RB.
        NSizeGrid = 25
        NStartGrid = 0
        % Number of transmission layers.
        NumLayers = 1
        % Bandwidth part start PRB and size.
        NStartBWP = 0
        NSizeBWP = srsPUSCHDecoderUnittest.NSizeGrid
        % MCS table.
        mcsTable = 'qam64'
        % Multiple HARQ processes flag: true if active, false is only one process allowed.
        MultipleHARQProcesses = true
        % Redundancy version sequence.
        RVsequence = [0, 2, 3, 1]
    end % of properties (Constant, Hidden)

    properties (Hidden)
        %Transport block size.
        TransportBlockSize
        %Target code rate.
        TargetCodeRate
        %ID of the HARQ process.
        HARQProcessID
        %Length of the encoded transport block.
        encodedTBLength
        %Modulation scheme
        Modulation
        %UL-SCH and UCI coding information.
        ulschInfo
        %Total number of allocated resource elements.
        nofREs
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/codeblock_metadata.h"\n');

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

    methods (TestClassSetup)
        function classSetup(obj)
            orig = rng;
            obj.addTeardown(@rng,orig)
            rng('default');
        end
    end % of methods (TestClassSetup)

    methods (Access = private)
        function setupsimulation(obj, SymbolAllocation, PRBAllocation, mcs)
        % Sets secondary simulation variables.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.helpers.srsExpandMCS
            import srsMatlabWrappers.phy.helpers.srsGetModulation

            if PRBAllocation == 0
                % Allocate the entire BWP.
                PRBstart = 0;
                PRBend = 24;
            else
                % Random allocation (at least 2 PRBs).
                PRBstart = randi([0, 12]);
                PRBend = randi([13, 24]);
            end

            PRBSet = PRBstart:PRBend;

            % Random HARQ ID.
            obj.HARQProcessID = randi([1, 8]);

            % Configure the carrier according to the test parameters.
            NSizeGridLoc = obj.NSizeGrid;
            NStartGridLoc = obj.NStartGrid;
            carrier = srsConfigureCarrier(NSizeGridLoc, NStartGridLoc);

            % Get the target code rate (R) and modulation order (Qm) corresponding
            % to the current modulation and scheme configuration.
            [R, Qm] = srsExpandMCS(mcs, obj.mcsTable);
            obj.TargetCodeRate = R/1024;
            ModulationLoc = srsGetModulation(Qm);
            obj.Modulation = ModulationLoc;

            % Configure the PUSCH according to the test parameters.
            NStartBWPLoc = obj.NStartBWP;
            NSizeBWPLoc = obj.NSizeBWP;
            NumLayersLoc = obj.NumLayers;
            pusch = srsConfigurePUSCH(NStartBWPLoc, NSizeBWPLoc, ModulationLoc, ...
                NumLayersLoc, SymbolAllocation, PRBSet);

            % Get the encoded TB length.
            [~, PUSCHInfo] = nrPUSCHIndices(carrier, pusch);
            obj.nofREs = PUSCHInfo.Gd;
            obj.encodedTBLength = PUSCHInfo.G;

            % Compute the transport block size.
            obj.TransportBlockSize = nrTBS(ModulationLoc, obj.NumLayers, ...
                numel(PRBSet), PUSCHInfo.NREPerPRB, obj.TargetCodeRate);

            % Get UL-SCH coding information.
            obj.ulschInfo = nrULSCHInfo(pusch, obj.TargetCodeRate, obj.TransportBlockSize, 0, 0, 0);
        end % of function setupsimulation(obj, SymbolAllocation, PRBAllocation, mcs)
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, SymbolAllocation, PRBAllocation, mcs)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   PRBAllocation and mcs. Other parameters (e.g., the HARQProcessID) are
        %   generated randomly.

            import srsMatlabWrappers.phy.helpers.srsConfigureULSCHEncoder
            import srsMatlabWrappers.phy.helpers.srsConfigureULSCHDecoder
            import srsMatlabWrappers.phy.helpers.srsModulationFromMatlab
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeInt8File

            % Generate a unique test ID.
            testID = obj.generateTestID;

            setupsimulation(obj, SymbolAllocation, PRBAllocation, mcs);

            % Fill a transport block with random bits.
            TB = randi([0 1], obj.TransportBlockSize, 1);

            % Configure the PUSCH encoder and decoder.
            MultipleHARQProcessesLoc = obj.MultipleHARQProcesses;
            TargetCodeRateLoc = obj.TargetCodeRate;
            TransportBlockLength = obj.TransportBlockSize;
            ULSCHEncoder = srsConfigureULSCHEncoder(MultipleHARQProcessesLoc, TargetCodeRateLoc);
            ULSCHDecoder = srsConfigureULSCHDecoder(MultipleHARQProcessesLoc, ...
                TargetCodeRateLoc, TransportBlockLength);

            % Add the generated TB to the encoder.
            setTransportBlock(ULSCHEncoder, TB, obj.HARQProcessID);

            % Allocate arrays for the codeblocks.
            nRVs = numel(obj.RVsequence);
            cw = nan(obj.encodedTBLength, nRVs);
            cwLLRs = nan(obj.encodedTBLength, nRVs);

            for iRV = 1:nRVs
                RV = obj.RVsequence(iRV);

                % Call the PUSCH encoding MATLAB functions.
                cw(:, iRV) = ULSCHEncoder(obj.Modulation, obj.NumLayers, ...
                    obj.encodedTBLength, RV, obj.HARQProcessID);

                % Even though we could have different modulations, for the purposes of this
                % simulation, real-valued BPSK is enough to generate meaningul LLRs.
                cwLLRs(:, iRV) = 10 - 20 * cw(:, iRV);
                % Add some (very little) noise.
                snr = 20; % dB
                cwLLRs(:, iRV) = cwLLRs(:, iRV) + 10 * randn(obj.encodedTBLength, 1) * 10^(-snr / 20);

            end
            % Decode the first transmission (it doesn't make sense to decode all
            % of them since MATLAB flushes the decoder buffer if the CRC is OK).
            rxTB = ULSCHDecoder(cwLLRs(:, 1), obj.Modulation, obj.NumLayers, ...
                obj.RVsequence(1), obj.HARQProcessID);
            % Check that there were no errors (expected, since the SNR is very high).
            assert(all(rxTB == TB), 'Decoding errors.');

            % Clip and quantize the log-likelihood ratios.
            cwLLRs(cwLLRs > 20) = 20;
            cwLLRs(cwLLRs < -20) = -20;
            cwLLRs = round(cwLLRs * 6); % this is codeblocks * 120 / 20
            % Write the LLRs to a binary file.
            obj.saveDataFile('_test_input', testID, @writeInt8File, cwLLRs(:));

            % Write the TBs to a binary file in packed format.
            TBPkd = bitPack(TB);
            obj.saveDataFile('_test_output', testID, @writeUint8File, TBPkd);

            % Generate the test case entry.
            Nref = ULSCHEncoder.LimitedBufferSize;
            % 25344 is the maximum coded length of a code block and implies no limit on the buffer size.
            if Nref >= 25344
              Nref = 0;
            end
            testCaseString = obj.testCaseToString(testID, ...
                {{['ldpc_base_graph_type::BG', num2str(obj.ulschInfo.BGN)], 0, ...
                    srsModulationFromMatlab(obj.Modulation, 'full'), Nref, ...
                    obj.NumLayers, obj.nofREs}, obj.RVsequence}, false, '_test_input', '_test_output');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, SymbolAllocation, PRBAllocation, mcs)
        %mexTest  Tests the mex wrapper of the SRSRAN PUSCH decoder.
        %   mexTest(OBJ, SYMBOLALLOCATION, PRBALLOCATION, MCS) runs a short simulation with
        %   a PUSCH transmission over the OFDM symbols in SYMBOLALLOCATION and the PRBs in
        %   PRBALLOCATION, using the modulation-coding scheme in MCS. The PUSCH is then
        %   decoded using the mex wrapper of the SRSRAN C++ component. The test is considered
        %   as passed if the transmitted and received transport blocks are equal.

            import srsMatlabWrappers.phy.helpers.srsConfigureULSCHEncoder
            import srsMEX.phy.srsPUSCHDecoder
            import srsTest.helpers.bitPack

            setupsimulation(obj, SymbolAllocation, PRBAllocation, mcs);

            % Fill a transport block with random bits.
            TB = randi([0 1], obj.TransportBlockSize, 1);

            % Configure the PUSCH encoder.
            MultipleHARQProcessesLoc = obj.MultipleHARQProcesses;
            TargetCodeRateLoc = obj.TargetCodeRate;
            TransportBlockLength = obj.TransportBlockSize;
            ULSCHEncoder = srsConfigureULSCHEncoder(MultipleHARQProcessesLoc, TargetCodeRateLoc);

            Nref = ULSCHEncoder.LimitedBufferSize;
            % 25344 is the maximum coded length of a code block and implies no limit on the buffer size.
            if Nref >= 25344
              Nref = 0;
            end

            % Configure the SRS PUSCH decoder mex.
            ULSCHDecoder = srsPUSCHDecoder('maxCodeblockSize', obj.ulschInfo.N, ...
                'maxSoftbuffers', 2, 'maxCodeblocks', obj.ulschInfo.C);

            % Add the generated TB to the encoder.
            setTransportBlock(ULSCHEncoder, TB, obj.HARQProcessID);

            % Fill segment configuration for the decoder.
            segmentCfg = srsPUSCHDecoder.configureSegment(obj.NumLayers, obj.nofREs, ...
                TransportBlockLength, TargetCodeRateLoc, obj.Modulation, 0, Nref);

            % Fill the HARQ buffer ID.
            HARQBufID.rnti = 1;
            HARQBufID.harq_ack_id = obj.HARQProcessID;
            HARQBufID.nof_codeblocks = segmentCfg.nof_codeblocks;

            % Pack the transport block for comparison.
            TBpacked = uint8(bitPack(TB));

            % Nominal SNR value to add some noise.
            snr = 20; % dB

            nRVs = numel(obj.RVsequence);
            for iRV = 1:nRVs
                RV = obj.RVsequence(iRV);

                % Call the PUSCH encoding MATLAB functions.
                cw = ULSCHEncoder(obj.Modulation, obj.NumLayers, ...
                    obj.encodedTBLength, RV, obj.HARQProcessID);

                % Even though we could have different modulations, for the purposes of this
                % simulation, real-valued BPSK is enough to generate meaningul LLRs.
                cwLLRs = 10 - 20 * double(cw);
                % Add some (very little) noise.
                cwLLRs = cwLLRs + 10 * randn(obj.encodedTBLength, 1) * 10^(-snr / 20);

                % Clip and quantize the log-likelihood ratios.
                cwLLRs(cwLLRs > 20) = 20;
                cwLLRs(cwLLRs < -20) = -20;
                cwLLRs = round(cwLLRs * 6); % this is codeblocks * 120 / 20

                segmentCfg.RV = RV;
                isNewData = (RV == obj.RVsequence(1));

                % Decode the first transmission (it doesn't make sense to decode all
                % of them since MATLAB flushes the decoder buffer if the CRC is OK).
                rxTB = ULSCHDecoder(int8(cwLLRs), isNewData, segmentCfg, HARQBufID);
                % Check that there were no errors (expected, since the SNR is very high).
                obj.assertEqual(rxTB, TBpacked, 'Decoding errors.');
            end

        end % of function mextest
    end % of methods (Test, TestTags = {'testmex'})
end % of classdef srsPUSCHDecoderUnittest
