%srsTPMISelectUnittest Unit tests for TPMI selection.
%   This class implements unit tests for the Transmit Precoding Matrix 
%   Indicator (TPMI) using the matlab.unittest framework. The simplest use
%   consists in creating an object with 
%      testCase = srsTPMISelectUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsTPMISelectUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_tpmi_select').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'ran/pusch').
%
%   srsTPMISelectUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsTPMISelectUnittest Properties (TestParameter):
%
%   NumTxPorts - Number of transmission ports.
%   NumRxPorts - Number of receive ports.
%   Repetition - Number of test cases with the same channel topology.
%
%   srsULSCHInfoUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsTPMISelectUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrULSCHInfo.

%   Copyright 2021-2024 Software Radio Systems Limited
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

classdef srsTPMISelectUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_tpmi_select'

        %Type of the tested block.
        srsBlockType = 'ran/pusch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ulsch_info' tests will be erased).
        outputPath = {['testTPMISelect', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Number of transmission ports.
        NumTxPorts = {2, 4}

        %Number of receive ports.
        NumRxPorts = {1, 2, 4}

        %Repetition.
        Repetition = num2cell(1:16);
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "srsran/ran/pusch/pusch_tpmi_select.h"\n');
            fprintf(fileID, '#include "srsran/ran/srs/srs_channel_matrix.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  srs_channel_matrix     channel_matrix;\n');
            fprintf(fileID, '  float                  noise_variance;\n');
            fprintf(fileID, '  pusch_tpmi_select_info info;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, NumTxPorts, ...
                NumRxPorts, Repetition)
        %testvectorGenerationCases Generates a test vector given the
        %   combinations of NumTxPorts, NumRxPorts and Repetition.

            import srsLib.ran.pusch.srsTPMISelect
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.array2str

            % Create random channel coefficients.
            H = randn(NumRxPorts, NumTxPorts) + 1i * randn(NumRxPorts, NumTxPorts);

            % Create a random noise variance in range (0, +inf).
            NoiseVar = -10 * log10(rand());

            % Select TPMI.
            TpmiInfo = srsTPMISelect(H, NoiseVar);

            % Prepare TPMI information string.
            TpmiInfoStr = ['{' num2str(struct2array((TpmiInfo)), '{%d, %f},') '}'];

            % Convert channel matrix to string.
            channelStr = ['srs_channel_matrix({' array2str(H(:)) '}, ' ...
                num2str(NumRxPorts) ', ' num2str(NumTxPorts) ')'];

            % Create test case entry.
            testCaseCell = {...
                channelStr, ...  % channel_matrix
                NoiseVar, ...    % noise_variance
                TpmiInfoStr, ... % info
                };

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                sprintf("%s,\n", cellarray2str(testCaseCell, true)));

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHProcessorUnittest
