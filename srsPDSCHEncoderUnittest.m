%srsPDSCHEncoderUnittest Unit tests for PDSCH encoder functions.
%   This class implements unit tests for the PDSCH symbol encoderr functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPDSCHEncoderUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPDSCHEncoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdsch_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPDSCHEncoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHEncoderUnittest Properties (TestParameter):
%
%   NumLayers               - Number of transmission layers (1, 2, 4, 8).
%   SymbolAllocation        - Symbols allocated to the PDSCH transmission.
%   PRBAllocation           - PRBs allocated to the PDSCH transmission.
%   mcs                     - Modulation scheme index (0, 28).
%
%   srsPDSCHEncoderUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
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
        %Path to results folder (old 'pdsch_modulator' tests will be erased).
        outputPath = {['testPDSCHModulator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Number of transmission layers (1, 2, 4, 8).
        NumLayers = {1, 2, 4, 8}

        %Symbols allocated to the PDSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PDSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %PRBs allocated to the PDSCH transmission. Two PRB allocation cases are covered:
        %   full usage (0) and partial usage (1).
        PRBAllocation = {0, 1}

        %Modulation and coding scheme index
        mcs = num2cell(0:28)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            %addTestIncludesToHeaderFilePHYchproc(obj, fileID);
            % for very specific header types, we'll skip the generic 'srsBlockUnittest' function
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/codeblock_metadata.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            %addTestDefinitionToHeaderFilePHYchproc(obj, fileID);
            % for very specific header types, we'll skip the generic 'srsBlockUnittest' function
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  segment_config           config;\n', obj.srsBlock);
            fprintf(fileID, '  file_vector<uint8_t>     transport_block;\n');
            fprintf(fileID, '  file_vector<uint8_t>     encoded;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, PRBAllocation, mcs)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme. Other parameters (e.g., the RNTI)
        %   are generated randomly.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigureDLSCHEncoder
            import srsMatlabWrappers.phy.helpers.srsConfigurePDSCH
            import srsMatlabWrappers.phy.helpers.srsGetTargetCodeRate
            import srsMatlabWrappers.phy.helpers.srsGetModulation
            import srsMatlabWrappers.phy.helpers.srsFormatModulation
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

            if isMCSConfigOK
                % configure the carrier according to the test parameters
                carrier = srsConfigureCarrier(NSizeGrid, NStartGrid);

                % get the target code rate (R) and modulation order (Qm) corresponding to the current modulation and scheme configuration
                [R, Qm] = srsGetTargetCodeRate(mcsTable, mcs);
                TargetCodeRate = R/1024;
                Modulation = srsGetModulation(Qm);

                % configure the PDSCH according to the test parameters
                pdsch = srsConfigurePDSCH(NStartBWP, NSizeBWP, Modulation, NumLayersLoc, SymbolAllocation, PRBSet);

                % configure the PDSCH encoder
                DLSCHEncoder = srsConfigureDLSCHEncoder(MultipleHARQProcesses, TargetCodeRate);

                % get the encoded TB length
                [PDSCHIndices, PDSCHInfo] = nrPDSCHIndices(carrier, pdsch);
                nofREs = length(PDSCHIndices);
                encodedTBLength = nofREs * Qm;

                % generate the TB to be encoded
                TBSize = nrTBS(Modulation, NumLayersLoc, numel(PRBSet), PDSCHInfo.NREPerPRB, TargetCodeRate);
                TB = randi([0 1], TBSize, 1);

                % write the packed format of the TB to a binary file
                TBPkd = reshape(TB, 8, [])' * 2.^(7:-1:0)';
                testCase.saveDataFile('_test_input', testID, @writeUint8File, TBPkd);

                % add the generated TB to the encoder
                setTransportBlock(DLSCHEncoder, TB, cwIdx, HARQProcessID);

                % call the PDSCH encoding Matlab functions
                cw = DLSCHEncoder(Modulation, NumLayersLoc, encodedTBLength, RV, HARQProcessID);

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
                testCaseString = testCase.testCaseToString(testID, true, ...
                    {['ldpc::base_graph_t::BG', num2str(info.BGN)], RV, ...
                        ['modulation_scheme::', srsFormatModulation(Modulation)], Nref, ...
                        NumLayersLoc, nofREs}, true);

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHEncoderUnittest
