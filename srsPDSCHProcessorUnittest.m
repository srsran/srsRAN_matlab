%srsPDSCHProcessorUnittest Vector tests for PDSCH processor functions.
%   This class implements vector tests for the PDSCH processor functions
%   using the matlab.unittest framework. The simplest use consists in
%   creating an object with
%      testCase = srsPDSCHProcessorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPDSCHProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pdsch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper').
%
%   srsPDSCHProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPDSCHProcessorUnittest Properties (TestParameter):
%
%   BWPConfig          - BWP configuration.
%   Modulation         - Modulation scheme.
%   SymbolAllocation   - PDSCH start symbol index and number of symbols.
%   DMRSReferencePoint - PDSCH DM-RS subcarrier reference point.
%   MaxNumLayers       - Maximum number of transmission layers.
%
%   srsPDSCHProcessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsPDSCHProcessorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

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

classdef srsPDSCHProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pdsch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'

        %Maximum number of layers.
        MaxNumLayers = 4

        %Symbols allocated to the PDSCH transmission.
        %   The symbol allocation is described by a two-element array with the starting
        %   symbol (0...13) and the length (1...14) of the PDSCH transmission.
        %   Example: [0, 14].
        SymbolAllocation = [2, 12]
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pdsch_processor' tests will be erased).
        outputPath = {['testPDSCHProcessor', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)     
        %BWP configuration.
        %   The bandwidth part is described by a two-element array with the starting
        %   PRB and the total number of PRBs (1...275).
        %   Example: [0, 25].
        BWPConfig = {[1, 25], [2, 52], [0, 106]}
                
        %Modulation {QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'QPSK', '16QAM', '64QAM', '256QAM'}
        
        %PDSCH DM-RS subcarrier reference point.
        %    It can be either CRB 0 or PRB 0 within the BWP.
        DMRSReferencePoint = {'CRB0', 'PRB0'};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "../../support/resource_grid_test_doubles.h"\n'...
                '#include "srsran/phy/upper/channel_processors/pdsch_processor.h"\n'...
                '#include "srsran/ran/precoding/precoding_codebooks.h"\n'...
                '#include "srsran/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                '/// Resource Grid entry.\n'...
                'using rg_entry = resource_grid_writer_spy::expected_entry_t;\n'...
                '\n'...
                'struct test_case_context {\n'...
                '  unsigned               rg_nof_rb;\n'...
                '  unsigned               rg_nof_symb;\n'...
                '  pdsch_processor::pdu_t pdu;\n'...
                '};\n'...
                '\n'...
                'struct test_case_t {\n'...
                '  test_case_context     context;\n'...
                '  file_vector<uint8_t>  sch_data;\n'...
                '  file_vector<rg_entry> grid_expected;\n'...
                '};\n\n'...
                ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, BWPConfig, Modulation, ...
                DMRSReferencePoint)
        %testvectorGenerationCases Generates a test vector for the given
        %   BWP, modulation scheme, and DM-RS reference point settings. 
        %   Other parameters, such as subcarrier spacing, PDSCH frequency
        %   allocation, slot number, RNTI, scrambling identifiers, target
        %   code rate and DM-RS additional positions are randomly
        %   generated.

            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsCSIRSValidateConfig
            import srsLib.phy.helpers.srsCSIRS2ReservedCell
            import srsLib.phy.helpers.srsModulationFromMatlab
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.bitPack

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Random parameters.
            NCellID = randi([0, 1007]);
            NumLayers = randi([1, testCase.MaxNumLayers]);
            
            % BWP allocation, referenced to CRB0.
            NStartBWP = BWPConfig(1);
            NSizeBWP = BWPConfig(2);

            % Grid starts at CRB0.
            NStartGrid = 0;

            % Grid size must be large enough to hold the BWP.
            NSizeGrid = NStartBWP + NSizeBWP;
            
            % Generate carrier configuration.
            carrier = srsConfigureCarrier(NCellID, NSizeGrid, NStartGrid);

            % Redundancy Version 0.
            rv = 0;

            % Target code rate, between 0.1 and 0.8;
            targetCodeRate = 0.1 + rand() * 0.7;

            % Minimum number of PRB.
            MinNumPrb = 1;

            % Random parameters.
            RNTI = randi([1, 65535]);
            NID = randi([0, 1023]);
            NIDNSCID = randi([0, 65535]);
            NSCID = randi([0, 1]);
            
            % 15 or 30 kHz subcarrier spacing.
            carrier.SubcarrierSpacing = 15 * randi([1, 2]);
            NSlot = randi([0, carrier.SlotsPerFrame]);

            % PDSCH frequency allocation within the BWP, referenced to PRB 0 of the BWP.
            PdschStartRB = randi([0, NSizeBWP - MinNumPrb]);
            PdschNumRB = randi([MinNumPrb, NSizeBWP - PdschStartRB]);

            % Additional DM-RS positions.
            DMRSAdditionalPosition = randi([0, 3]);
            
            % Set carrier paramters.
            carrier.NStartGrid = NStartGrid;
            carrier.NSizeGrid = NSizeGrid;
            carrier.NCellID = NCellID;
            carrier.NSlot = NSlot;
            
            % Create and set PDSCH config.
            pdsch = nrPDSCHConfig;
            pdsch.RNTI = RNTI;
            pdsch.NID = NID;
            pdsch.Modulation = Modulation;
            pdsch.SymbolAllocation = testCase.SymbolAllocation;
            pdsch.NStartBWP = NStartBWP;
            pdsch.NSizeBWP = NSizeBWP;
            pdsch.PRBSet = PdschStartRB + (0:PdschNumRB - 1);
            pdsch.DMRS.DMRSAdditionalPosition = DMRSAdditionalPosition;
            pdsch.DMRS.NIDNSCID = NIDNSCID;
            pdsch.DMRS.NSCID = NSCID;
            pdsch.DMRS.DMRSReferencePoint = DMRSReferencePoint;
            pdsch.NumLayers = NumLayers;

            % Create a ZP-CSI-RS resource, occupying the first symbol.
            csirs1 = nrCSIRSConfig;
            csirs1.CSIRSType = 'zp';
            csirs1.CSIRSPeriod = 'on';
            csirs1.RowNumber = 1;
            csirs1.Density = 'three';
            csirs1.SymbolLocations = {3};
            csirs1.SubcarrierLocations = {0};
            csirs1.NumRB = NSizeBWP;
            csirs1.RBOffset = NStartBWP;
            csirs1.NID = NID;
        
            % Create a second ZP-CSI-RS resource with differnt RE
            % allocations.
            csirs2 = nrCSIRSConfig;
            csirs2.CSIRSType = 'zp';
            csirs2.CSIRSPeriod = 'on';
            csirs2.RowNumber = 2;
            csirs2.Density = 'dot5odd';
            csirs2.SymbolLocations = {4};
            csirs2.SubcarrierLocations = {randi([0, 11])};
            csirs2.NumRB = NSizeBWP;
            csirs2.RBOffset = NStartBWP;
            csirs2.NID = NID;

            % Create a third ZP-CSI-RS resource spanning two antenna
            % ports.
            csirs3 = nrCSIRSConfig;
            csirs3.CSIRSType = 'zp';
            csirs3.CSIRSPeriod = 'on';
            csirs3.RowNumber = 3;
            csirs3.Density = 'dot5even';
            csirs3.SymbolLocations = {12};
            csirs3.SubcarrierLocations = {randi([0, 10])};
            csirs3.NumRB = NSizeBWP;
            csirs3.RBOffset = NStartBWP;
            csirs3.NID = NID;
          
            % Validate the CSI-RS resources.
            if ((~srsCSIRSValidateConfig(carrier, csirs1)) || ...
                    (~srsCSIRSValidateConfig(carrier, csirs2)) || ...
                    (~srsCSIRSValidateConfig(carrier, csirs3)))
                error('invalid CSIRS configuration');
            end

            % Generate RE patterns from the CSI-RS resources.
            rvdREPatternList = srsCSIRS2ReservedCell(carrier, {csirs1, csirs2, csirs3});
            
            % Add the CSI-RS indices to the PDSCH reserved RE list.
            CSIRSIndices = [nrCSIRSIndices(carrier, csirs1, 'IndexStyle','subscript', 'IndexBase', '0based'); ...
               nrCSIRSIndices(carrier, csirs2, 'IndexStyle','subscript', 'IndexBase', '0based'); ...
               nrCSIRSIndices(carrier, csirs3, 'IndexStyle','subscript', 'IndexBase', '0based')];

            % Flatten the index format.
            CSIRSIndices = CSIRSIndices(:, 1) + 12 * NSizeBWP * CSIRSIndices(:, 2);

            % Change the RE reference point from CRB0 to the BWP Start.
            pdsch.ReservedRE = CSIRSIndices - 12 * NStartBWP;

            % Generate PDSCH resource grid indices.
            [pdschDataIndices, pdschInfo] = nrPDSCHIndices(carrier, pdsch, 'IndexStyle','subscript', 'IndexBase','0based');

            % Generate PDSCH DM-RS resource grid indices.
            pdschDMRSIndices = nrPDSCHDMRSIndices(carrier, pdsch, 'IndexStyle','subscript', 'IndexBase','0based');

            % Select a valid TBS.
            tbs = nrTBS(pdsch.Modulation, pdsch.NumLayers, length(pdsch.PRBSet), pdschInfo.NREPerPRB, targetCodeRate);
           
            % Get DL-SCH information.
            dlschInfo = nrDLSCHInfo(tbs, targetCodeRate);

            % Generate random data.
            schTransportBlock = randi([0, 1], tbs, 1);

            % Encode data.
            encDL = nrDLSCH;
            encDL.TargetCodeRate = targetCodeRate;
            setTransportBlock(encDL, schTransportBlock);
            schCodeword = encDL(Modulation, pdsch.NumLayers, pdschInfo.G, rv);

            % Generate DL-SCH symbols.
            betaDatadB = 0;
            schSymbols = nrPDSCH(carrier, pdsch, schCodeword) * 10 ^ (betaDatadB / 20);

            % Generate DM-RS symbols.
            betaDMRSdB = 0;
            DMRSSymbols = nrPDSCHDMRS(carrier, pdsch) * 10 ^ (betaDMRSdB / 20);

            transportBlockFileName = '_test_input_transport_block';
            pdschGridFileName = '_test_output_grid';

            % Write the bit-packed DL-SCH transport block to a binary file.
            testCase.saveDataFile(transportBlockFileName, testID, @writeUint8File, bitPack(schTransportBlock));

            % Concatenate data and DM-RS symbols.
            allIndices = [pdschDataIndices; pdschDMRSIndices];
            allSymbols = [schSymbols(:); DMRSSymbols(:)];

            % Write PDSCH Data complex symbols and indices into a binary file as resource grid entries.
            testCase.saveDataFile(pdschGridFileName, testID, @writeResourceGridEntryFile, allSymbols, allIndices);
                
            % Generate DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(...
                nrPDSCHDMRSIndices(carrier, pdsch, 'IndexStyle', ...
                'subscript', 'IndexBase', '0based'));

            % Generate the test case entry.
            slotConfig = {log2(carrier.SubcarrierSpacing/15), carrier.NSlot};
            dmrsTypeString = sprintf('dmrs_type::TYPE%d', pdsch.DMRS.DMRSConfigurationType);
            refPointStr = ['pdsch_processor::pdu_t::', pdsch.DMRS.DMRSReferencePoint];
            numCDMGroupsWithoutData = pdsch.DMRS.NumCDMGroupsWithoutData;
            baseGraphString = ['ldpc_base_graph_type::BG', num2str(dlschInfo.BGN)];
      
            % Transport block size limited buffer rate match.
            TBSLBRM = nrTBS('256QAM', 4, 273, 156, 948 / 1024) / 8;
            TBSLBRMStr = ['units::bytes(' num2str(TBSLBRM) ')'];

            % Generate Resource Block allocation string, referenced to the
            % starting PRB of the BWP.
            RBAllocationString = rbAllocationIndexes2String(pdsch.PRBSet);

            % Convert cyclic prefix to string.
            cyclicPrefixStr = ['cyclic_prefix::', upper(carrier.CyclicPrefix)];

            % Convert modulation type to string.
            modString1 = srsModulationFromMatlab(pdsch.Modulation, 'full');

            precodingString = ['precoding_configuration::make_wideband(make_identity(' num2str(NumLayers) '))'];

            % Prepare PDSCH configuration.
            pduDescription = {...
                'nullopt', ...                 % context
                slotConfig, ...                % slot
                pdsch.RNTI, ...                % rnti
                pdsch.NSizeBWP, ...            % bwp_size_rb
                pdsch.NStartBWP, ...           % bwp_start_rb
                cyclicPrefixStr, ...           % cp
                {{modString1, rv}}, ...        % codewords
                pdsch.NID, ...                 % n_id
                refPointStr, ...               % ref_point
                dmrsSymbolMask, ...            % dmrs_symbol_mask
                dmrsTypeString, ...            % dmrs
                NIDNSCID, ...                  % scrambling_id
                NSCID, ...                     % n_scid
                numCDMGroupsWithoutData, ...   % nof_cdm_groups_without_data
                RBAllocationString, ...        % freq_alloc
                pdsch.SymbolAllocation(1), ... % start_symbol_index
                pdsch.SymbolAllocation(2), ... % nof_symbols
                baseGraphString, ...           % ldpc_base_graph
                TBSLBRMStr, ...                % tbs_lbrm
                rvdREPatternList, ...          % reserved
                betaDMRSdB, ...                % ratio_pdsch_dmrs_to_sss_dB
                betaDatadB, ...                % ratio_pdsch_data_to_sss_dB
                precodingString                % precoding
                };

            contextDescription = {...
                carrier.NSizeGrid, ...      % rg_nof_rb
                carrier.SymbolsPerSlot, ... % rg_nof_symbols
                pduDescription, ...
                };

            % Generate PDSCH transmission entry.
            testCaseString = testCase.testCaseToString(testID, contextDescription, true, ...
                transportBlockFileName, pdschGridFileName);
        
            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPDSCHProcessorUnittest
