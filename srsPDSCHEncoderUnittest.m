%srsPDSCHEncoderUnittest Unit tests for PDSCH encoder functions.
%   This class implements unit tests for the PDSCH encoder functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPDSCHEncoderUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPDSCHEncoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdsch_encoder').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPDSCHEncoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHEncoderUnittest Properties (TestParameter):
%
%   SymbolAllocation        - Symbols allocated to the PDSCH transmission.
%   PRBAllocation           - PRBs allocated to the PDSCH transmission.
%   mcs                     - Modulation scheme index (0, 28).
%
%   srsPDSCHEncoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDSCHEncoderUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPDSCHEncoderUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdsch_encoder'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pdsch_encoder' tests will be erased).
        outputPath = {['testPDSCHEncoder', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Symbols allocated to the PDSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PDSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %PRBs allocated to the PDSCH transmission. Two PRB allocation cases are covered:
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
            fprintf(fileID, '  segmenter_config         config;\n');
            fprintf(fileID, '  file_vector<uint8_t>     transport_block;\n');
            fprintf(fileID, '  file_vector<uint8_t>     encoded;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, PRBAllocation, mcs)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   PRBAllocation and mcs. Other parameters (e.g., the HARQProcessID) are
        %   generated randomly.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigureDLSCHEncoder
            import srsMatlabWrappers.phy.helpers.srsConfigurePDSCH
            import srsMatlabWrappers.phy.helpers.srsExpandMCS
            import srsMatlabWrappers.phy.helpers.srsGetModulation
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File

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
            RV = 0;
            cwIdx = 0;

            % skip those invalid configuration cases
            isMCSConfigOK = (~strcmp(mcsTable, 'qam256') || mcs < 28);

            if ~isMCSConfigOK
                return;
            end

            % configure the carrier according to the test parameters
            carrier = srsConfigureCarrier(NSizeGrid, NStartGrid);

            % get the target code rate (R) and modulation order (Qm) corresponding to the current modulation and scheme configuration
            [R, Qm] = srsExpandMCS(mcs, mcsTable);
            TargetCodeRate = R/1024;
            Modulation = srsGetModulation(Qm);
            ModulationLoc = Modulation{1};

            % configure the PDSCH according to the test parameters
            pdsch = srsConfigurePDSCH(NStartBWP, NSizeBWP, ModulationLoc, NumLayersLoc, SymbolAllocation, PRBSet);

            % get the encoded TB length
            [PDSCHIndices, PDSCHInfo] = nrPDSCHIndices(carrier, pdsch);
            nofREs = length(PDSCHIndices);
            encodedTBLength = nofREs * Qm;

            % generate the TB to be encoded
            TBSize = nrTBS(ModulationLoc, NumLayersLoc, numel(PRBSet), PDSCHInfo.NREPerPRB, TargetCodeRate);
            TB = randi([0 1], TBSize, 1);

            % write the packed format of the TB to a binary file
            TBPkd = bitPack(TB);
            testCase.saveDataFile('_test_input', testID, @writeUint8File, TBPkd);

            % configure the PDSCH encoder
            DLSCHEncoder = srsConfigureDLSCHEncoder(MultipleHARQProcesses, TargetCodeRate);

            % add the generated TB to the encoder
            setTransportBlock(DLSCHEncoder, TB, cwIdx, HARQProcessID);

            % call the PDSCH encoding Matlab functions
            cw = DLSCHEncoder(ModulationLoc, NumLayersLoc, encodedTBLength, RV, HARQProcessID);

            % write the encoded TB to a binary file
            testCase.saveDataFile('_test_output', testID, @writeUint8File, cw);

            % obtain the related LDPC encoding parameters
            info = nrDLSCHInfo(TBSize, TargetCodeRate);

            % generate the test case entry
            Nref = DLSCHEncoder.LimitedBufferSize;
            % 25344 is the maximum coded length of a code block and implies no limit on the buffer size
            if Nref >= 25344
              Nref = 0;
            end
            testCaseString = testCase.testCaseToString(testID, ...
                {['ldpc_base_graph_type::BG', num2str(info.BGN)], RV, ...
                    ['modulation_scheme::', Modulation{2}], Nref, ...
                    NumLayersLoc, nofREs}, true, '_test_input', '_test_output');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHEncoderUnittest
