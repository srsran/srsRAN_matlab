%srsNZPCSIRSGeneratorUnittest Unit tests for NZP-CSI-RS processor functions.
%   This class implements unit tests for the NZP-CSI-RS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsNZPCSIRSGeneratorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsNZPCSIRSGeneratorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'csi_rs_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsNZPCSIRSGeneratorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsNZPCSIRSGeneratorUnittest Properties (TestParameter):
%
%   RowNumber     - CSI-RS table row number (0, 1, ..., 12).
%   Numerology    - Defines the subcarrier spacing (0, 1, 2, 3, 4).
%   CyclicPrefix  - Carrier Cyclic Prefix formats.
%   Density       - Defines the resource density of the mapping.
%   k_0           - Frequency domain location reference 0.
%   l_0           - Time domain location reference 0.
%
%   srsNZPCSIRSGeneratorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsNZPCSIRSGeneratorUnittest Methods (Access = protected):
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

classdef srsNZPCSIRSGeneratorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'nzp_csi_rs_generator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'csi_rs_processor' tests will be erased).
        outputPath = {['testCSIRS', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)

        %CSI-RS mapping format, as specified by the row RowNumber in
        %   TS38.211, Table 7.4.1.5.3-1 (0, 1, ..., 12).
        RowNumber = num2cell(1:5)
        
        %Defines the subcarrier spacing (0, 1, 2, 3, 4).
        Numerology = {0 2}

        %Carrier Cyclic Prefix options.
        CyclicPrefix = {'normal' 'extended'}

        %Resource Element density for the CSI-RS mapping.
        %  Only the valid densities will be tested, according to the
        %  specified mapping table row.
        Density = {'three' 'dot5odd' 'dot5even' 'one'}
   
        %Frequency domain location 0 within the PRB. Values that map 
        %   elements outside the PRB boundaries will be skipped. Successive
        %   k_i values are generated by incrementing k_0 in steps of 2.
        k_0 = {0 6}

        %Time domain location 0 within the PRB. Values that map elements
        %   outside the PRB boundaries will be skipped.
        l_0 = {0 8}

    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "srsran/ran/precoding/precoding_codebooks.h"\n');
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
        end

    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, RowNumber, Numerology, Density, CyclicPrefix, k_0, l_0)
        %testvectorGenerationCases Generates a test vector for the given RowNumber,
        %   Numerology, Density, k_0, and l_0. 
        %   NCellID, NSlot and PRB occupation are randomly generated.
        %   Scrambling ID and symbol amplitude are also random.

            import srsTest.helpers.cellarray2str
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.matlab2srsCyclicPrefix

            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsConfigureCSIRS
            import srsLib.phy.upper.signal_processors.srsCSIRSnzp
            import srsLib.phy.helpers.srsCSIRSGetNofFreqRefs
            import srsLib.phy.helpers.srsCSIRSValidateConfig

            % Current fixed parameter values.
            NSizeGrid = 272;
            NStartGrid = 0;

            % The l_1 symbol location reference is not used in any of the
            % currently supported mapping options.
            l_1 = 0;
          
            % Set NZP-CSI-RS in all slots.
            CSIRSType = 'nzp';           
            CSIRSPeriod = 'on';
                                   
            % Generate a unique test ID
            TestID = testCase.generateTestID;
            
            % Use a random NCellID, NFrame, NSlot, scrambling ID, PRB allocation and amplitude
            % for each test.
            NCellID = randi([0, 1007]);
            NFrame = randi([0, 1023]);
            
            switch(Numerology)
                case 0
                    NSlot = randi([0, 9]);                    
                case 1
                    NSlot = randi([0, 19]);
                case 2 
                    NSlot = randi([0, 39]);
                case 3
                    NSlot = randi([0, 79]);
                case 4
                    NSlot = randi([0, 159]);
                otherwise
                    return;
            end                                   
            
            NumRB = randi([4, floor(NSizeGrid)]);
            RBOffset = randi([0, NSizeGrid - NumRB]);                       
            NID = randi([0, 1023]);
            amplitude = 0.1 * randi([1, 100]);

            % Generate the remaining location references.
            nofKiRefs = srsCSIRSGetNofFreqRefs(RowNumber);
            
            SubcarrierLocations = zeros(nofKiRefs, 1);
            for i = 1 : nofKiRefs
                SubcarrierLocations(i) = k_0 + 2 * (i - 1);
            end           

            SubcarrierLocations = {SubcarrierLocations};
            SymbolLocations = {l_0};

            SubcarrierSpacing = 15 * (2 .^ Numerology);
            
            % Configure the carrier according to the test parameters.
            Carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, ...
                NSizeGrid, NStartGrid, NSlot, NFrame, CyclicPrefix);

            if (isempty(Carrier))
                return;
            end

            % Create the CSIRS configuration for the MATLAB processor.            
            CSIRS = srsConfigureCSIRS(Density, RowNumber, SymbolLocations, ...
                SubcarrierLocations, NumRB, NID, RBOffset, CSIRSType, CSIRSPeriod);
       
            if (isempty(CSIRS))
                return;
            end

            % Invalid test case configurations are skipped.
            if (~srsCSIRSValidateConfig(Carrier, CSIRS))
                return;
            end

            % Call the CSI-RS processor MATLAB functions.
            [CSIRSsymbols, symbolIndices] = srsCSIRSnzp(Carrier, CSIRS, amplitude);

            % Write the generated NZP-CSI-RS sequence into a binary file.
            testCase.saveDataFile('_test_output', TestID, ...
                @writeResourceGridEntryFile, CSIRSsymbols, symbolIndices);

            % Generate a 'slot_point' configuration string.
            slotPointConfig = cellarray2str({Numerology, NFrame, ...
                floor(NSlot / Carrier.SlotsPerSubframe), ...
                rem(NSlot, Carrier.SlotsPerSubframe)}, true);             

            % Generate the CP string for the test header file.
            CyclicPrefixStr = matlab2srsCyclicPrefix(CyclicPrefix);

            % Generate the Density string for the test header file.
            DensityStr = matlab2srsCSIRSDensity(Density);

            % Generate the CDM type string for the test header file.
            CDMStr = matlab2srsCDMType(CSIRS.CDMType);
           
            % Generate the Subcarrier indices string.
            SubcarrierRefStr = cellarray2str(SubcarrierLocations, true);

            % Precoding configuration that maps layers to ports one to one.
            precodingString = ['precoding_configuration::make_wideband(make_identity(' num2str(CSIRS.NumCSIRSPorts) '))'];

            configCell = {...
                slotPointConfig, ...  % slot
                CyclicPrefixStr, ...  % cp
                RBOffset, ...         % start_rb
                NumRB, ...            % nof_rb
                RowNumber, ...        % csi_rs_mapping_table_row
                SubcarrierRefStr, ... % freq_allocation_ref_idx
                l_0, ...              % symbol_l0
                l_1, ...              % symbol_l1
                CDMStr, ...           % cdm
                DensityStr, ...       % freq_density
                NID, ...              % scrambling_id
                amplitude, ...        % amplitude
                precodingString...    % precoding
                };


            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(TestID, ...
                configCell, true, '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsCSIRSUnittest

function DensityStr = matlab2srsCSIRSDensity (Density)
% matlab2srsCSIRSDensity Generates the Density string to be used in the test header file.
    DensityStr = 'csi_rs_freq_density_type::';
    if (strcmp(Density, 'one'))
        DensityStr = [DensityStr 'one'];
    elseif (strcmp(Density, 'dot5odd'))
        DensityStr = [DensityStr 'dot5_odd_RB'];
    elseif (strcmp(Density, 'dot5even'))
        DensityStr = [DensityStr 'dot5_even_RB'];
    elseif (strcmp(Density, 'three'))
        DensityStr = [DensityStr 'three'];
    end
end

function CDMStr = matlab2srsCDMType(CDMType)
 % matlab2srsCDMType Generates the CDM string to be used in the test header file.
    if (strcmp(CDMType, 'FD-CDM2'))
        CDMStr = 'csi_rs_cdm_type::fd_CDM2';
    elseif (strcmp(CDMType, 'noCDM'))
        CDMStr = 'csi_rs_cdm_type::no_CDM';
    elseif (strcmp(CDMType, 'CDM4'))
        CDMStr = 'csi_rs_cdm_type::cdm4_FD2_TD2';
    else
        CDMStr = 'csi_rs_cdm_type::cdm8_FD2_TD4';
    end
end
