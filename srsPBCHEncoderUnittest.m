%srsPBCHEncoderUnittest Unit tests for PBCH encoder functions.
%   This class implements unit tests for the PBCH encoder functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPBCHEncoderUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPBCHEncoderUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pbch_encoder').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPBCHEncoderUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPBCHEncoderUnittest Properties (TestParameter):
%
%   SSBindex - SSB index (0, ..., 63).
%   Lmax     - Maximum number of SSBs within a SSB set (4, 8, 64).
%   NCellID  - PHY-layer cell ID (0, ..., 1007).
%   payload  - PBCH payload provided by higher layers (24 bits).
%   SFN      - system frame number (0, ..., 1023).
%   kSSB     - subcarrier offset (0, ..., 31).
%   hrf      - half frame bit in SS/PBCH block transmissions (0, 1).
%
%   srsPBCHEncoderUnittest Methods (Test, TestTags = {'testvector'}):
%
%   testvectorGenerationCases  - Generates test vectors for a given SSB index,
%                                Lmax and hrf, using random NCellID SFN, kSSB and
%                                payload for each test.
%
%   srsPBCHModulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

classdef srsPBCHEncoderUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pbch_encoder'

        %Type of the tested block, including layer.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pbch_encoder' tests will be erased).
        outputPath = {['testPBCHencoder', datestr(now, 30)]}
    end

    properties (TestParameter)
        %SSB index (0...63).
        SSBindex = num2cell(0:7)

        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %Maximum number of SSBs within a SSB set (4, 8 (default), 64).
        %Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8
        %are equivalent at this stage.
        Lmax = {4, 8, 64}

        %SFN (0...1023).
        SFN = num2cell(0:1:1023)

        %Subcarrier offset (0...31)
        kSSB = num2cell(0:1:31)

        %Half frame bit in SS/PBCH block transmissions (0, 1).
        hrf = {0, 1}
    end % of properties (TestParameter)

    properties (Constant, Hidden)
        randomizeTestvector = randperm(1008)
        randomizeSFN = randperm(1024)
        randomizeKssb = randi([1, 32], 1, 382)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDefinitionToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYchproc(obj, fileID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SSBindex, Lmax, hrf)
        %testvectorGenerationCases Generates 'pbch_encoder' test vectors.
        %   testvectorGenerationCases(TESTCASE, SSBINDEX, LMAX) generates a 'pbch_encoder'
        %   test vector for the given SSB index SSBINDEX, the given LMAX, and the given
        %   HRF using a random NCellID, a random SFN, a random KSSB and a random payload.

            import srsTest.helpers.cellarray2str
            import srsTest.helpers.writeUint8File
            import srsMatlabWrappers.phy.upper.channel_processors.srsPBCHencoder

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % use a unique NCellID, SFN, KSSB and payload for each test
            randomizedTestCase = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedTestCase};
            randomizedSFN = testCase.randomizeSFN(testID + 1);
            SFNLoc = testCase.SFN{randomizedSFN};
            randomizedKssb = testCase.randomizeKssb(testID + 1);
            kSSBLoc = testCase.kSSB{randomizedKssb};
            payload = randi([0 1], 24, 1);

            % skip PBCH encoding for invalid configurations
            isSSBindexOK = Lmax > SSBindex;

            if isSSBindexOK
                % call the PBCH encoder MATLAB functions
                cw = srsPBCHencoder(payload, NCellIDLoc, SSBindex, Lmax, SFNLoc, hrf, kSSBLoc);

                % write the encoded codeword to a binary file
                testCase.saveDataFile('_test_output', testID, @writeUint8File, cw);

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, false, {NCellIDLoc, SSBindex, Lmax, hrf, ...
                    payload, SFNLoc, kSSBLoc}, true);

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPBCHEncoderUnittest
