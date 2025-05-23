%srsPBCHModulatorUnittest Unit tests for PBCH symbol modulator functions.
%   This class implements unit tests for the PBCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPBCHModulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPBCHModulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pbch_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors/ssb').
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
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

%   Copyright 2021-2025 Software Radio Systems Limited
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

classdef srsPBCHModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pbch_modulator'

        %Type of the tested block, including layer.
        srsBlockType = 'phy/upper/channel_processors/ssb'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pbch_modulator' tests will be erased).
        outputPath = {['testPBCHmodulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %SSB index (0...7).
        SSBindex = num2cell(0:7)

        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %Maximum number of SSBs within a SSB set (4, 8 (default), 64).
        %Lmax = 4 is not currently supported, and Lmax = 64 and Lmax = 8
        %are equivalent at this stage.
        Lmax = {8}
    end % of properties (TestParameter)

    properties (Hidden)
        randomizeTestvector
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, [...
                '#include "../../../support/resource_grid_test_doubles.h"\n'...
                '#include "srsran/phy/upper/channel_processors/ssb/pbch_modulator.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDefinitionToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYchproc(obj, fileID);
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SSBindex, Lmax)
        %testvectorGenerationCases Generates 'pbch_modulator' test vectors.
        %   testvectorGenerationCases(TESTCASE, SSBINDEX, LMAX) generates a 'pbch_modulator'
        %   test vector for the given SSB index SSBINDEX and the given LMAX,
        %   using a random NCellID and a random codeword.

            import srsTest.helpers.cellarray2str
            import srsTest.helpers.writeUint8File
            import srsLib.phy.upper.channel_processors.ssb.srsPBCHmodulator
            import srsTest.helpers.writeResourceGridEntryFile

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

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
            SSBportsStr = cellarray2str({SSBports}, true);

            % write the BCH cw to a binary file
            testCase.saveDataFile('_test_input', testID, @writeUint8File, cw);

            % call the PBCH symbol modulation MATLAB functions
            [modulatedSymbols, symbolIndices] = srsPBCHmodulator(cw, NCellIDLoc, SSBindex, Lmax);

            % write each complex symbol and the associated indices to a binary file
            testCase.saveDataFile('_test_output', testID, @writeResourceGridEntryFile, ...
                modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = testCase.testCaseToString(testID, ...
                {NCellIDLoc, SSBindex, SSBfirstSubcarrier, SSBfirstSymbol, ...
                    SSBamplitude, SSBportsStr}, true, '_test_input', '_test_output');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPBCHModulatorUnittest
