%srsPBCHdmrsUnittest Unit tests for PBCH DMRS processor functions.
%   This class implements unit tests for the PBCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPBCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPBCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pbch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors/ssb').
%
%   srsPBCHdmrsUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPBCHdmrsUnittest Properties (TestParameter):
%
%   SSBindex - SSB index (0...7).
%   Lmax     - Maximum number of SSBs within a SSB set (4, 8, 64).
%   NCellID  - PHY-layer cell ID (0...1007).
%   nHF      - Half-frame indicator (0, 1).
%
%   srsPBCHdmrsUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases   - Generates test vectors for the given SSBindex,
%                                 Lmax and nHF, while using a random NCellID.
%
%   srsPBCHdmrsUnittest Methods (Access = protected):
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

classdef srsPBCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pbch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors/ssb'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pbch_processor' tests will be erased).
        outputPath = {['testPBCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %SSB index (0...7).
        SSBindex = {0, 1, 2, 3, 4, 6, 16, 32, 48}

        %Maximum number of SSBs within a SSB set (4, 8, 64).
        Lmax = {4, 8, 64}

        %Half-frame indicato (0, 1)
        nHF = {0, 1}
    end % of properties (TestParameter)

    properties (Hidden)
        randomizeTestvector
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SSBindex, Lmax, nHF)
        %testvectorGenerationCases Generates test vectors for the given SSBindex,
        %   Lmax and nHF, while using a random NCellID.

            import srsTest.helpers.cellarray2str
            import srsLib.phy.upper.signal_processors.srsPBCHdmrs
            import srsTest.helpers.writeResourceGridEntryFile

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % use a unique NCellID for each test
            randomizedTestCase = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedTestCase};

            % current fixed parameter values
            numPorts = 1;
            SSBfirstSubcarrier = 0;
            SSBfirstSymbol = 0;
            SSBamplitude = 1;
            SSBports = zeros(numPorts, 1);
            SSBportsStr = cellarray2str({SSBports}, true);

            % check if the current SSBindex value is possible with the current Lmax
            if Lmax > SSBindex
                % call the PBCH DMRS symbol processor MATLAB functions
                [DMRSsymbols, symbolIndices] = srsPBCHdmrs(NCellIDLoc, SSBindex, Lmax, nHF);

                % write each complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, DMRSsymbols, symbolIndices);

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, ...
                    {NCellIDLoc, SSBindex, Lmax, SSBfirstSubcarrier, SSBfirstSymbol, ...
                        nHF, SSBamplitude, SSBportsStr}, true, '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPBCHdmrsUnittest
