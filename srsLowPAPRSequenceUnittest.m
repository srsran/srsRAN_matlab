%srsLowPAPRSequenceUnittest Unit tests for Low PAPR Sequence generator.
%   This class implements unit tests for the low PAPR sequence generator
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with
%       testCase = srsLowPAPRSequenceUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsLowPAPRSequenceUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'low_papr_sequence_generator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/sequence_generators').
%
%   srsLowPAPRSequenceUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsLowPAPRSequenceUnittest Properties (TestParameter):
%
%   SequenceLength      - Length of the sequence.
%   MaxCyclicShift      - Maximum number of sequence cyclic shifts.
%
%   srsLowPAPRSequenceUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the
%                               provided parameters.
%
%   srsLowPAPRSequenceUnittest Methods (Access = protected):
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

classdef srsLowPAPRSequenceUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'low_papr_sequence_generator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/sequence_generators'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'low_papr_sequence_generator' tests will be erased).
        outputPath = {['testLowPAPRSequence', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Sequence lengths. Derived from TS38.211 Table 6.4.1.4.3-1.
        SequenceLength = {12, 24, 36, 48, 60, 72, 84, 96, 108, 120, ...
            132, 144, 156, 168, 180, 192, 204, 216, 228, 240, 252, 264, ...
            276, 288, 312, 324, 336, 360, 384, 396, 408, 432, 456, 480, ...
            504, 528, 552, 576, 624, 648, 672, 720, 768, 792, 816, 864, ...
            912, 960, 1008, 1056, 1104, 1152, 1248, 1296, 1344, 1440, ...
            1536, 1584, 1632}

        %Carrier bandwidth in PRB.
        MaxCyclicShift = {8, 12}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "srsran/phy/upper/sequence_generators/low_papr_sequence_generator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_context {\n');
            fprintf(fileID, '  unsigned u;\n');
            fprintf(fileID, '  unsigned v;\n');
            fprintf(fileID, '  unsigned n_cs;\n');
            fprintf(fileID, '  unsigned n_cs_max;\n');
            fprintf(fileID, '  unsigned M_zc;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  test_context      context;\n');
            fprintf(fileID, '  file_vector<cf_t> sequence;\n');
            fprintf(fileID, '};\n');
        end

    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SequenceLength, MaxCyclicShift)
        %testvectorGenerationCases Generates a test vector for the given 
        %SequenceLength and MaxCyclicShift. The sequence group, base and 
        %cyclic shift is selected randomly.

            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID
            TestID = testCase.generateTestID;
            
            % Select sequence group.
            u = randi([0 29]);

            % Select sequence base.
            v = 0;
            if SequenceLength >= 72
                v = randi([0 1]);
            end

            % Select cyclic shift.
            cyclicShift = randi([0 (MaxCyclicShift - 1)]);

            % Calculate actual cyclic shift.
            alpha = 2 * pi * cyclicShift / MaxCyclicShift;

            % Generate sequence.
            sequence = nrLowPAPRS(u, v, alpha, SequenceLength);

            % Write the sequence into a binary file.
            testCase.saveDataFile('_test_output', TestID, ...
                @writeComplexFloatFile, sequence);

            % Create cell with the sequence generation context.
            contextCell = {...
                u, ...              % u
                v, ...              % v
                cyclicShift, ...    % n_cs
                MaxCyclicShift, ... % n_cs_max
                SequenceLength, ... % M_zc
                };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(TestID, ...
                contextCell, true, '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsLowPAPRSequenceUnittest
