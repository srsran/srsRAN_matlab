%srsSSBProcessorUnittest Unit tests for SSB processor functions.
%   This class implements unit tests for the SSB processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsSSBProcessorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsSSBProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ssb_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsSSBProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsSSBProcessorUnittest Properties (TestParameter):
%
%   SSBpattern - SSB pattern ('A', 'B', 'C', 'D', 'E').
%   Lmax       - Maximum number of SSBs within a SSB set (4, 8 (default), 64).
%   betaPSS    - PSS scaling factor (0, -3).
%   SSBindex   - SSB index (0...63).
%   subframeIndex - Index of a SSB within the set transmitted in a given half-frame (0...3).
%   NCellID  - PHY-layer cell ID (0...1007).
%
%   srsSSBProcessorUnittest Methods (Test, TestTags = {'testvector'}):
%
%   testvectorGenerationCases  - Generates test vectors for a given SSB pattern, number of
%                                SSBs within a set, SSB index and half-frame, while using
%                                random NCellID and cw for each test.
%
%   srsSSBProcessorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

classdef srsSSBProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ssb_processor'

        %Type of the tested block, including layer.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ssb_processor' tests will be erased).
        outputPath = {['testSSBProcessor', datestr(now, 30)]}
    end

    properties (TestParameter)
        %SSB pattern ('A', 'B', 'C', 'D', 'E').
        SSBpattern = {'A', 'B', 'C', 'D', 'E'}

        %Maximum number of SSBs within a SSB set (4, 8 (default), 64).
        Lmax = {4, 8, 64}

        %PSS scaling factor in dB (0, -3).
        PSSscale = {0, -3}

        %SSB index (0...63).
        SSBindex = num2cell(0:63)

        %Index of the subframe with a SSB in a given half-frame (0, 5).
        subframeIndex = {0, 5}

        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %SFN (0...1023).
        SFN = num2cell(0:1023)
    end % of properties (TestParameter)

    properties (Constant, Hidden)
        randomizeTestvector = randperm(1008)
        randomizeSFN = randperm(1024)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDefinitionToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'ssb_processor::pdu_t config;\n');
            fprintf(fileID, ...
                'file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SSBpattern, Lmax, PSSscale, SSBindex, subframeIndex)
        %testvectorGenerationCases Generates 'ssb_processor' test vectors.
        %   testvectorGenerationCases(TESTCASE, SSBPATTERN, LMAX, PSSSCALE, SSBINDEX, SUBFRAMEINDEX)
        %   generates a 'ssb_processor' test vector for the given SSB pattern SSBPATTERN, number of
        %   SSBs within a set LMAX, SSB index SSBINDEX and half-frame SUBFRAMEINDEX, while using a
        %   random NCellID and a random codeword.

            import srsTest.helpers.cellarray2str
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsSSBgetNumerology
            import srsMatlabWrappers.phy.helpers.srsSSBgetFirstSymbolIndex
            import srsMatlabWrappers.phy.helpers.srsSSBgetFirstSubcarrierIndex
            import srsMatlabWrappers.phy.upper.signal_processors.srsPSS
            import srsMatlabWrappers.phy.upper.signal_processors.srsSSS
            import srsMatlabWrappers.phy.upper.signal_processors.srsPBCHdmrs
            import srsMatlabWrappers.phy.upper.channel_processors.srsPBCHencoder
            import srsMatlabWrappers.phy.upper.channel_processors.srsPBCHmodulator
            import srsTest.helpers.writeResourceGridEntryFile

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % use a unique NCellID, cw and port index for each test
            randomizedTestCase = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedTestCase};
            randomizedSFN = testCase.randomizeSFN(testID + 1);
            SFNLoc = testCase.SFN{randomizedSFN};
            portIdx = randi([0 63]);
            randomMIB = randi([0 1], 24, 1);

            % current fixed parameter values as required by the C code
            pointAoffset = 0;
            SSBoffset = 0;
            CyclicPrefix = 'normal';
            SSBportsStr = cellarray2str({portIdx}, true);

            % skip those invalid configuration cases
            isPatternOK = (Lmax < 64 || (strcmp(SSBpattern, 'D') && strcmp(SSBpattern, 'E')));
            isSSBindexOK = SSBindex < Lmax;

            if isPatternOK && isSSBindexOK
                % deduce the subcarrier spacing used by the SSB pattern
                numerology = srsSSBgetNumerology(SSBpattern);

                % configure the carrier according to the test parameters
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(SubcarrierSpacing, CyclicPrefix);

                % deduce derivative configuration parameters
                SSBfirstSymbolIndex = srsSSBgetFirstSymbolIndex(SSBpattern, SSBindex);
                slotInBurst = floor(SSBfirstSymbolIndex / carrier.SymbolsPerSlot);
                subframeInBurst = floor(slotInBurst / carrier.SlotsPerSubframe);
                slotInSubframe = mod(slotInBurst, carrier.SlotsPerSubframe);
                subframeIndexLoc = subframeIndex + subframeInBurst;
                nHF = floor(subframeIndexLoc / 5);
                SSBfirstSubcarrierIndex = srsSSBgetFirstSubcarrierIndex(numerology, pointAoffset, SSBoffset);
                SSBfirstSymbolIndexSlot = mod(SSBfirstSymbolIndex, carrier.SymbolsPerSlot);

                % the BCH payload comprises 24 MIB bits, 4 SFN LSBs, 1 nHF bit and 3 SSBindex MSBs (TS 138.212, Section 7.1.1)
                SFNbinStr = dec2bin(SFNLoc, 8);
                SFNbin = (SFNbinStr(end-3:end).' == '1');
                SSBindexbinStr = dec2bin(SSBindex, 8);
                SSBindexbin = (SSBindexbinStr(1:3).' == '1');
                payload = [randomMIB; SFNbin; nHF; SSBindexbin];

                % call the PBCH encoder MATLAB functions
                cw = srsPBCHencoder(randomMIB, NCellIDLoc, SSBindex, Lmax, SFNLoc, nHF, SSBoffset);

                % call the PSS generation MATLAB functions and adjust the SSB indexing offsets
                [PSSsymbols, PSSindices] = srsPSS(NCellIDLoc);
                PSSindices(:, 1) = PSSindices(:, 1) +  SSBfirstSubcarrierIndex;
                PSSindices(:, 2) = PSSindices(:, 2) +  SSBfirstSymbolIndexSlot;
                PSSindices(:, 3) = ones(length(PSSsymbols), 1) * portIdx;
                betaPSS = 10^(PSSscale / 20);
                PSSsymbols = betaPSS * PSSsymbols;

                % call the SSS generation MATLAB functions and adjust the SSB indexing offsets
                [SSSsymbols, SSSindices] = srsSSS(NCellIDLoc);
                SSSindices(:, 1) = SSSindices(:, 1) +  SSBfirstSubcarrierIndex;
                SSSindices(:, 2) = SSSindices(:, 2) +  SSBfirstSymbolIndexSlot;
                SSSindices(:, 3) = ones(length(SSSsymbols), 1) * portIdx;

                % call the PBCH symbol modulation MATLAB functions and adjust the SSB indexing offsets
                [PBCHsymbols, PBCHindices] = srsPBCHmodulator(cw, NCellIDLoc, SSBindex, Lmax);
                PBCHindices(:, 1) = PBCHindices(:, 1) +  SSBfirstSubcarrierIndex;
                PBCHindices(:, 2) = PBCHindices(:, 2) +  SSBfirstSymbolIndexSlot;
                PBCHindices(:, 3) = ones(length(PBCHsymbols), 1) * portIdx;

                % call the PBCH DMRS symbol processor MATLAB functions and adjust the SSB indexing offsets
                [PBCHdmrsSymbols, PBCHdmrsIndices] = srsPBCHdmrs(NCellIDLoc, SSBindex, Lmax, nHF);
                PBCHdmrsIndices(:, 1) = PBCHdmrsIndices(:, 1) +  SSBfirstSubcarrierIndex;
                PBCHdmrsIndices(:, 2) = PBCHdmrsIndices(:, 2) +  SSBfirstSymbolIndexSlot;
                PBCHdmrsIndices(:, 3) = ones(length(PBCHdmrsSymbols), 1) * portIdx;

                % combine all generated symbols and indices and write them to a binary file
                SSBsymbols = [PSSsymbols; SSSsymbols; PBCHsymbols; PBCHdmrsSymbols];
                SSBindices = [PSSindices; SSSindices; PBCHindices; PBCHdmrsIndices];
                testCase.saveDataFile('_test_output', testID, @writeResourceGridEntryFile, ...
                    SSBsymbols, SSBindices);

                % generate the test case entry
                SFNbinStr = dec2bin(SFNLoc, 8);
                SFNbin = (SFNbinStr(1:8).' == '1');
                testCaseString = testCase.testCaseToString(testID, ...
                    {{numerology, SFNLoc, subframeIndexLoc, slotInSubframe}, NCellIDLoc, ...
                        PSSscale, SSBindex, Lmax, SSBoffset, pointAoffset, ...
                        ['ssb_pattern_case::', upper(SSBpattern)], payload, ...
                        SSBportsStr}, true, '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsSSBProcessorUnittest
