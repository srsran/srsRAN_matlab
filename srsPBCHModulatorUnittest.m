%srsPBCHModulatorUnittest Unit tests for PBCH symbol modulator functions.
%   This class implements unit tests for the PBCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPBCHModulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPBCHModulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block ('pbch_modulator').
%   srsBlockType  - The type of the tested block ('channel_processors').
%   srsBlockLayer - The layer of the tested block ('phy/upper').
%
%   srsPBCHModulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPBCHModulatorUnittest Properties (TestParameter):
%
%   SSBindex - SSB index (0...7).
%   Lmax     - Maximum number of SSBs within a SSB set (4, 8 (default), 64).
%   NCellID  - PHY-layer cell ID (0...1007).
%
%   srsPBCHModulatorUnittest Methods (Test, TestTags = {'testvector'}):
%
%   testvectorGenerationCases  - Generates test vectors for a given SSB index
%                                and Lmax using random NCellID and cw for each test.
%
%   srsPBCHModulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile  - Adds include directives to the test header file.
%   addTestDetailsToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                  to the test header file.
%
%   See also matlab.unittest.

classdef srsPBCHModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pbch_modulator'

        %Type of the tested block.
        srsBlockType = 'channel_processors'

        %Layer of the tested block.
        srsBlockLayer = 'phy/upper'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pbch_modulator' tests will be erased).
        outputPath = {['testPBCHmodulator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %SSB index (0...7).
        SSBindex = num2cell(0:7)

        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        % Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8
        % are equivalent at this stage.
        Lmax = {8}
    end

    properties (Constant, Hidden)
        randomizeTestvector = randperm(1008)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchproc(obj, testvectorHeaderFileID, unitUnderTest);
        end

        function addTestDetailsToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDetailsToHeaderFilePHYchproc(obj, testvectorHeaderFileID, unitUnderTest);
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SSBindex, Lmax)
        %testvectorGenerationCases Generates test vectors for a given SSB index and Lmax
        %   using random NCellID and cw for each test.

            % generate a unique test ID by looking at the number of files generated so far
            baseFilename = testCase.srsBlock;
            filenameTemplate = sprintf('%s/%s_test_input*', testCase.tmpOutputPath, baseFilename);
            testID = numel(dir(filenameTemplate));

            % use a unique NCellID and cw for each test
            randomizedTestCase = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedTestCase};
            cw = randi([0 1], 864, 1);

            % current fixed parameter values as required by the C code
            numPorts = 1;
            SSBfirstSubcarrier = 0;
            SSBfirstSymbol = 0;
            SSBamplitude = 1;
            SSBports = zeros(numPorts, 1);
            import srsTest.helpers.cellarray2str;
            SSBportsStr = cellarray2str({SSBports}, true);

            % write the BCH cw to a binary file
            import srsTest.helpers.writeUint8File;
            testCase.saveDataFile(baseFilename, '_test_input', testID, ...
                testCase.tmpOutputPath, @writeUint8File, cw);

            % call the PBCH symbol modulation MATLAB functions
            import srsMatlabWrappers.phy.upper.channel_processors.srsPBCHmodulator
            [modulatedSymbols, symbolIndices] = srsPBCHmodulator(cw, NCellIDLoc, SSBindex, Lmax);

            % write each complex symbol and the associated indices to a binary file
            import srsTest.helpers.writeResourceGridEntryFile
            testCase.saveDataFile(baseFilename, '_test_output', testID, testCase.tmpOutputPath, ...
                @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = testCase.testCaseToString(baseFilename, testID, true, ...
                {NCellIDLoc, SSBindex, SSBfirstSubcarrier, SSBfirstSymbol, ...
                    SSBamplitude, SSBportsStr}, true);

            % add the test to the file header
            testCase.addTestToHeaderFile(testCaseString, baseFilename, testCase.tmpOutputPath);
        end
    end

end
