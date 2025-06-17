%srsPDSCHModulatorUnittest Unit tests for PDSCH symbol modulator functions.
%   This class implements unit tests for the PDSCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPDSCHModulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPDSCHModulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdsch_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors/pdsch').
%
%   srsPDSCHModulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHModulatorUnittest Properties (TestParameter):
%
%   SymbolAllocation  - Symbols allocated to the PDSCH transmission.
%   Modulation        - Modulation scheme.
%   NumLayers         - Number of transmission layers.
%
%   srsPDSCHModulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPDSCHModulatorUnittest Methods (Access = protected):
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

classdef srsPDSCHModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdsch_modulator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors/pdsch'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pdsch_modulator' tests will be erased).
        outputPath = {['testPDSCHModulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Symbols allocated to the PDSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PDSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %Modulation scheme ('QPSK', '16QAM', '64QAM', '256QAM').
        Modulation = {'QPSK', '16QAM', '64QAM', '256QAM'}

        %Number of transmission layers (1, 2, 4).
        NumLayers = {1, 2, 4}

        %Virtual to physical resource block interleaved mapping bundle
        %size. Zero means no interleaving.
        VRBBundleSize = {0, 2, 4}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "../../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pdsch/pdsch_modulator.h"\n');
            fprintf(fileID, '#include "srsran/ran/precoding/precoding_codebooks.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end
        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYchproc(obj, fileID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, Modulation, NumLayers, VRBBundleSize)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme and number of layers. Other parameters (e.g.,
        %   the RNTI) are generated randomly.

            import srsLib.phy.helpers.srsGetBitsSymbol
            import srsLib.phy.helpers.srsModulationFromMatlab
            import srsLib.phy.upper.channel_processors.srsPDSCHmodulator
            import srsLib.phy.upper.signal_processors.srsPDSCHdmrs
            import srsTest.helpers.array2str
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeUint8File

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate default carrier configuration.
            carrier = nrCarrierConfig();

            % Set randomized values.
            NSizeBWP = randi([carrier.NSizeGrid / 2, carrier.NSizeGrid]);
            NStartBWP = randi([0, carrier.NSizeGrid - NSizeBWP]);
            NID = randi([1, 1023]);
            RNTI = randi([1, 65535]);
            startPRB = randi([0, NSizeBWP - 2]);
            endPRB = randi([startPRB + 1, NSizeBWP - 1]);

            VRBToPRBInterleaving = (VRBBundleSize ~= 0);
            VRBBundleSize = max([2, VRBBundleSize]);

            % Configure the PDSCH according to the test parameters.
            pdsch = nrPDSCHConfig( ...
                NSizeBWP=NSizeBWP, ...
                NStartBWP=NStartBWP, ...
                Modulation=Modulation, ...
                NumLayers=NumLayers, ...
                SymbolAllocation=SymbolAllocation, ...
                PRBSet=startPRB:endPRB, ...
                VRBToPRBInterleaving=VRBToPRBInterleaving, ...
                VRBBundleSize=VRBBundleSize, ...
                NID=NID, ...
                RNTI=RNTI ...
                );

            modOrder1 = srsGetBitsSymbol(pdsch.Modulation);
            modString1 = srsModulationFromMatlab(pdsch.Modulation, 'full');

            % Calculate number of encoded bits.
            nBits = length(nrPDSCHIndices(carrier, pdsch, "IndexStyle", "subscript")) * modOrder1;

            % Generate codewords.
            cws = randi([0,1], nBits, 1);

            % Write the DLSCH cw to a binary file.
            testCase.saveDataFile('_test_input', testID, @writeUint8File, cws);

            % Call the PDSCH symbol modulation Matlab functions.
            [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws);

            % Write each complex symbol into a binary file, and the associated indices to another.
            testCase.saveDataFile('_test_output', testID, ...
                @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            % Generate DMRS symbol mask.
            [~, symbolIndices] = srsPDSCHdmrs(carrier, pdsch);
            dmrsSymbolMask = symbolAllocationMask2string(symbolIndices);

            % Generate the test case entry.
            reservedString = '{}';

            if VRBToPRBInterleaving
                RBAllocationString = sprintf('rb_allocation::make_type1(%d, %d, create_interleaved_other(%d, %d, vrb_to_prb::mapping_type::interleaved_n%d))', startPRB, length(pdsch.PRBSet), NStartBWP, NSizeBWP, VRBBundleSize);
            else
                RBAllocationString = sprintf('rb_allocation::make_type1(%d, %d, vrb_to_prb::create_non_interleaved_other())', startPRB, length(pdsch.PRBSet));
            end
            DMRSTypeString = sprintf('dmrs_type::TYPE%d', pdsch.DMRS.DMRSConfigurationType);

            precodingString = ['precoding_configuration::make_wideband(make_identity(' num2str(NumLayers) '))'];

            bwpConfig = {NStartBWP, NStartBWP + NSizeBWP};
            timeAlloc= {pdsch.SymbolAllocation(1), sum(pdsch.SymbolAllocation)};

            configCell = {...
                pdsch.RNTI,...                          % rnti
                bwpConfig, ...                          % bwp
                modString1, ...                         % modulation1
                modString1, ...                         % modulation2
                RBAllocationString, ...                 % freq_allocation
                timeAlloc, ...                          % time_alloc
                dmrsSymbolMask, ...                     % dmrs_symb_pos
                DMRSTypeString, ...                     % dmrs_config_type
                pdsch.DMRS.NumCDMGroupsWithoutData, ... % nof_cmd_groups_without_data 
                pdsch.NID, ...                          % n_id
                1.0, ...                                % scaling
                reservedString, ...                     % reserved
                precodingString...                      % precoding
                };

            testCaseString = testCase.testCaseToString(testID, ...
                configCell, true, '_test_input', '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHModulatorUnittest
