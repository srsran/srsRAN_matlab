%srsModulationMapperUnittest Unit tests for the modulation mapper functions.
%   This class implements unit tests for the modulation mapper functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsModulationMapperUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsModulationMapperUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'modulation_mapper').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_modulation').
%
%   srsModulationMapperUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsModulationMapperUnittest Properties (TestParameter):
%
%   modScheme - Modulation scheme (see extended documentation for details).
%   nSymbols  - Number of modulated output symbols (257, 997).
%
%   srsModulationMapperUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors for the given modulation
%                               scheme and number of symbols.
%
%   srsModulationMapperUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.

classdef srsModulationMapperUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'modulation_mapper'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_modulation'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'modulation_mapper' tests will be erased).
        outputPath = {['testModulationMapper', datestr(now, 30)]}
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
            addTestDefinitionToHeaderFilePHYchmod(obj, fileID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, nSymbols, modScheme)
        %testvectorGenerationCases(TESTCASE, NSYMBOLS, MODSCHEME) Generates a test vector
        %   for the given number of symbols NSYMBOLS and modulation scheme and MODSCHEME.

            import srsTest.helpers.writeUint8File
            import srsMatlabWrappers.phy.upper.channel_modulation.srsModulator
            import srsTest.helpers.writeComplexFloatFile

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % generate random test input as a bit sequence
            codeword = randi([0 1], nSymbols * modScheme{1}, 1);

            % write the codeword to a binary file
            testCase.saveDataFile('_test_input', testID, @writeUint8File, codeword);

            % call the symbol modulation MATLAB functions
            modulatedSymbols = srsModulator(codeword, modScheme{2});

            % write complex symbols into a binary file
            testCase.saveDataFile('_test_output', testID, ...
                @writeComplexFloatFile, modulatedSymbols);

            % generate the test case entry
            modSchemeString = ['modulation_scheme::', modScheme{3}];
            testCaseString = testCase.testCaseToString(testID, true, ...
                {nSymbols, modSchemeString}, false);

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsModulationMapperUnittest
