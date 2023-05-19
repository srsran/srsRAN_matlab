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
%   Modulation - Modulation scheme (see extended documentation for details).
%   nSymbols  - Number of modulated output symbols (257, 997).
%
%   srsModulationMapperUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given modulation
%                               scheme and number of symbols.
%
%   srsModulationMapperUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

%   Copyright 2021-2023 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

classdef srsModulationMapperUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'modulation_mapper'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_modulation'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'modulation_mapper' tests will be erased).
        outputPath = {['testModulationMapper', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Number of modulated output symbols (257, 997).
        nSymbols = {257, 997}

        %Modulation scheme.
        Modulation = {'BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'}
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
        function testvectorGenerationCases(testCase, nSymbols, Modulation)
        %testvectorGenerationCases(TESTCASE, NSYMBOLS, MODSCHEME) Generates a test vector
        %   for the given number of symbols NSYMBOLS and modulation scheme and MODSCHEME.

            import srsLib.phy.upper.channel_modulation.srsModulator
            import srsLib.phy.helpers.srsModulationFromMatlab
            import srsLib.phy.helpers.srsGetBitsSymbol
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID by looking at the number of files generated so far.
            testID = testCase.generateTestID;

            % Generate random test input as a bit sequence.
            bitsSymbol = srsGetBitsSymbol(Modulation);
            codeword = randi([0 1], nSymbols * bitsSymbol, 1);

            % Write the codeword to a binary file.
            testCase.saveDataFile('_test_input', testID, @writeUint8File, codeword);

            % Call the symbol modulation MATLAB functions.
            modulatedSymbols = srsModulator(codeword, Modulation);

            % Write complex symbols into a binary file.
            testCase.saveDataFile('_test_output', testID, ...
                @writeComplexFloatFile, modulatedSymbols);

            % Generate the test case entry.
            modSchemeString = srsModulationFromMatlab(Modulation, 'full');
            testCaseString = testCase.testCaseToString(testID, ...
                {nSymbols, modSchemeString}, false, '_test_input', ...
                '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsModulationMapperUnittest
