%srsDLProcessorUnittest Vector tests for downlink processor functions.
%   This class implements vector tests for the downlink processor functions
%   using the matlab.unittest framework. The simplest use consists in
%   creating an object with
%      testCase = srsDLProcessorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsDLProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dl_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper').
%
%   srsDLProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsDLProcessorUnittest Properties (TestParameter):
%
%   referenceChannel - Determines the reference channel to generate.
%
%   srsDLProcessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsDLProcessorUittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsDLProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dl_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dl_processor' tests will be erased).
        outputPath = {['DLProcessor', datestr(now, 30)]}
    end

    properties (TestParameter)
        %List of NR supported reference channels.
        %   See also srsMatlabWrappers.phy.upper.waveformGenerators.srsDLReferenceChannel
        referenceChannel = {...
            'R.PDSCH.1-1.1',...
            'R.PDSCH.1-1.2',...
            'R.PDSCH.1-4.1',...
            'R.PDSCH.1-2.1',...
            'R.PDSCH.1-8.1',...
            };
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "../support/resource_grid_test_doubles.h"\n'...
                '#include "srsgnb/phy/upper/channel_processors/pdsch_processor.h"\n'...
                '#include "srsgnb/phy/upper/channel_processors/pdcch_processor.h"\n'...
                '#include "srsgnb/support/file_vector.h"\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                '/// Describes a Resource Grid entry (shorts the type).\n'...
                'using rg_entry = resource_grid_writer_spy::expected_entry_t;\n'...
                '\n'...
                'struct test_model_description {\n'...
                '  std::string test_model;\n'...
                '  std::string description;\n'...
                '  std::string bandwidth;\n'...
                '  std::string subcarrier_spacing;\n'...
                '  std::string duplex_mode;\n'...
                '  std::string standard_version;\n'...
                '};\n'...
                '\n'...
                'struct pdsch_transmission {\n'...
                '  pdsch_processor::pdu_t pdu;\n'...
                '  file_vector<uint8_t>  transport_block;\n'...
                '  file_vector<rg_entry> data_symbols;\n'...
                '  file_vector<rg_entry> dmrs_symbols;\n'...
                '};\n'...
                '\n'...
                'struct pdcch_transmission {\n'...
                '  pdcch_processor::pdu_t pdu;\n'...
                '  file_vector<rg_entry> data_symbols;\n'...
                '  file_vector<rg_entry> dmrs_symbols;\n'...
                '};\n'...
                '\n'...
                'struct test_case_t {\n'...
                '  test_model_description test_model;\n'...
                '  std::vector<pdcch_transmission> pdcch;\n'...
                '  std::vector<pdsch_transmission> pdsch;\n'...
                '};\n'...
                ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, referenceChannel)
        %testvectorGenerationCases Generates a test case for each reference
        %   channel.

            import srsMatlabWrappers.phy.helpers.srsIndexes0BasedSubscrit
            import srsMatlabWrappers.phy.helpers.srsCSIRS2ReservedCell
            import srsMatlabWrappers.phy.upper.waveformGenerators.srsDLReferenceChannel
            import srsMatlabWrappers.ran.pdcch.srsPDCCHCandidatesUE
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.rbAllocationIndexes2String

            % Generate DL Reference channel
            [description, configuration, info] = srsDLReferenceChannel(referenceChannel);

            % Extract configuration
            bwpConfig = configuration.BandwidthParts{1};
            pdschConfig = configuration.PDSCH{1};
            pdcchConfig = configuration.PDCCH{1};
            ssConfig = configuration.SearchSpaces{pdcchConfig.SearchSpaceID};
            coresetConfig = configuration.CORESET{ssConfig.CORESETID};

            % Convert cyclic prefix to string
            cyclicPrefixStr = ['cyclic_prefix::', upper(bwpConfig.CyclicPrefix)];

            % Generate reference channel description
            testModelCell = {...
                ['"' referenceChannel '"'], ...
                ['"' description.summary '"'], ...
                ['"' num2str(description.bandwidth) 'MHz"'], ...
                ['"' num2str(description.subcarrierSpacing) 'kHz"'], ...
                ['"' description.duplexMode '"'], ...
                };

            % Extract common information
            nSymb = 14;
            nSubC = bwpConfig.NSizeBWP * 12;

            allPdcchConfigCell = {};
            pdcchTransmissions = info.WaveformResources.PDCCH.Resources;
            for pdcch = pdcchTransmissions
                % Skip slots that collide with SSB
                if pdcch.NSlot == 0
                    continue;
                end

                pdcchDataFileName = ['_', referenceChannel, '_pdcch_data_symbols'];
                pdcchDMRSFileName = ['_', referenceChannel, '_pdcch_dmrs_symbols'];

                % Convert PDCCH data indices to 0based subscript
                pdcchDataIndices = srsIndexes0BasedSubscrit(pdcch.ChannelIndices, nSubC, nSymb);

                % Convert PDCCH DMRS indices to 0based subscript
                pdcchDMRSIndices = srsIndexes0BasedSubscrit(pdcch.DMRSIndices, nSubC, nSymb);

                % Write PDCCH Data complex symbols and indices into a binary file as resource grid entries.
                testCase.saveDataFile(pdcchDataFileName, pdcch.NSlot, @writeResourceGridEntryFile, pdcch.ChannelSymbols, pdcchDataIndices);

                % Write PDCCH DMRS complex symbols and indices into a binary file as resource grid entries.
                testCase.saveDataFile(pdcchDMRSFileName, pdcch.NSlot, @writeResourceGridEntryFile, pdcch.DMRSSymbols, pdcchDMRSIndices);

                % Generate the test case entry
                slotConfig = {log2(bwpConfig.SubcarrierSpacing/15), pdcch.NSlot};

                nSlotFrame = mod(pdcch.NSlot, bwpConfig.SubcarrierSpacing/15 * 10);

                candidates = srsPDCCHCandidatesUE(sum(coresetConfig.FrequencyResources) * coresetConfig.Duration, ...
                    ssConfig.NumCandidates(log2(pdcchConfig.AggregationLevel) + 1), ...
                    pdcchConfig.AggregationLevel, ...
                    ssConfig.CORESETID, ...
                    pdcchConfig.RNTI, ...
                    nSlotFrame);

                cceIndex = candidates(pdcchConfig.AllocatedCandidate);
                if isequal(coresetConfig.CCEREGMapping, 'noninterleaved')
                    coresetRegToCceMappingStr = 'pdcch_processor::coreset_description::NON_INTERLEAVED';
                else
                    coresetRegToCceMappingStr = 'pdcch_processor::coreset_description::INTERLEAVED';
                end

                % Prepare DCI description
                dciDescription = {...
                    pdcchConfig.RNTI,...             % rnti
                    pdcchConfig.DMRSScramblingID,... % n_id_pdcch_dmrs
                    pdcchConfig.DMRSScramblingID,... % n_id_pdcch_data
                    pdcchConfig.RNTI,...             % n_rnti
                    cceIndex,...                     % cce_index
                    pdcchConfig.AggregationLevel,... % aggregation_level
                    0.0,...                          % dmrs_power_offset_dB
                    0.0,...                          % data_power_offset_dB
                    pdcch.DCIBits,...                % payload
                    '{0}',...                        % ports
                    };

                % Prepare CORESET description
                coresetDescription = {...
                    bwpConfig.NSizeBWP,...                % bwp_size_rb
                    bwpConfig.NStartBWP,...               % bwp_start_rb
                    ssConfig.StartSymbolWithinSlot,...    % start_symbol_index
                    coresetConfig.Duration,...            % duration
                    coresetConfig.FrequencyResources, ... % frequency_resources
                    coresetRegToCceMappingStr,...         % cce_to_reg_mapping_type
                    coresetConfig.REGBundleSize, ...      % reg_bundle_size
                    coresetConfig.InterleaverSize, ...    % interleaver_size
                    coresetConfig.ShiftIndex, ...         % shoft_index
                    };

                % Prepare PDCCH PDU
                pduDescription = {...
                    slotConfig,...         % slot
                    cyclicPrefixStr,...    % cp
                    coresetDescription,... % coreset
                    {dciDescription},...   % dci_list
                    };

                % Generate PDSCH transmission entry
                pdcchString = testCase.testCaseToString(pdcch.NSlot, pduDescription, true, ...
                    pdcchDataFileName, pdcchDMRSFileName);

                % Remove comma and new line from the end of the string
                pdcchString = strrep(pdcchString, sprintf(',\n'), '');

                % Append PDSCH transmission to the list of PDSCH
                % transmissions.
                allPdcchConfigCell = [allPdcchConfigCell{:}, {pdcchString}];
            end % of for pdcch = pdcchTransmissions

            allPdschConfigCell = {};
            pdschTransmissions = info.WaveformResources.PDSCH.Resources;
            for pdsch = pdschTransmissions
                % Skip slots that collide with SSB
                if pdsch.NSlot == 0
                    continue;
                end

                transportBlockFileName = ['_', referenceChannel, '_transport_block'];
                pdschDataFileName = ['_', referenceChannel, '_pdsch_data_symbols'];
                pdschDMRSFileName = ['_', referenceChannel, '_pdsch_dmrs_symbols'];

                % Convert modulation type to string
                if iscell(pdschConfig.Modulation)
                    error('Unsupported');
                else
                    switch pdschConfig.Modulation
                        case 'QPSK'
                            modString1 = 'modulation_scheme::QPSK';
                        case '16QAM'
                            modString1 = 'modulation_scheme::QAM16';
                        case '64QAM'
                            modString1 = 'modulation_scheme::QAM64';
                        case '256QAM'
                            modString1 = 'modulation_scheme::QAM256';
                    end
                end

                % Convert PDSCH data indices to 0based subscript
                pdschDataIndices = srsIndexes0BasedSubscrit(pdsch.ChannelIndices, nSubC, nSymb);

                % Convert PDSCH DMRS indices to 0based subscript
                pdschDMRSIndices = srsIndexes0BasedSubscrit(pdsch.DMRSIndices, nSubC, nSymb);

                % Write the DLSCH transport block to a binary file
                testCase.saveDataFile(transportBlockFileName, pdsch.NSlot, @writeUint8File, pdsch.TransportBlock(:,1));

                % Write PDSCH Data complex symbols and indices into a binary file as resource grid entries.
                testCase.saveDataFile(pdschDataFileName, pdsch.NSlot, @writeResourceGridEntryFile, pdsch.ChannelSymbols, pdschDataIndices);

                % Write PDSCH DMRS complex symbols and indices into a binary file as resource grid entries.
                testCase.saveDataFile(pdschDMRSFileName, pdsch.NSlot, @writeResourceGridEntryFile, pdsch.DMRSSymbols, pdschDMRSIndices);

                % Generate DMRS symbol mask
                dmrsSymbolMask = zeros(1,14);
                dmrsSymbolMask(pdsch.DMRSSymbolSet + 1) = 1;

                % Generate the test case entry
                slotConfig = {log2(bwpConfig.SubcarrierSpacing/15), pdsch.NSlot};
                portsString = '{0}';
                dmrsTypeString = sprintf('dmrs_type::TYPE%d', pdschConfig.DMRS.DMRSConfigurationType);
                refPointStr = ['pdsch_processor::pdu_t::', pdschConfig.DMRS.DMRSReferencePoint  ];
                numCDMGroupsWithoutData = pdschConfig.DMRS.NumCDMGroupsWithoutData;
                startSymbol = pdschConfig.SymbolAllocation(1);
                numberOfSymbols = pdschConfig.SymbolAllocation(2);
                DLSCHInfo = nrDLSCHInfo(length(pdsch.TransportBlock(:,1)), pdschConfig.TargetCodeRate );
                baseGraphString = ['ldpc_base_graph_type::BG', num2str(DLSCHInfo.BGN)];
                TBSLBRMBytes = 25344 / 8;
                reservedList = srsCSIRS2ReservedCell(configuration, pdsch.CSIRSResources);
                dataPower = 0;
                dmrsPower = pdschConfig.DMRSPower;

                % Generate Resource Block allocation string
                RBAllocationString = rbAllocationIndexes2String(pdschConfig.PRBSet);

                % Prepare PDSCH configuration
                pdschPDUCell = {...
                    slotConfig, ...               % Slot
                    pdschConfig.RNTI, ...         % RNTI
                    bwpConfig.NSizeBWP, ...       % BWP size
                    bwpConfig.NStartBWP, ...      % BWP Start
                    cyclicPrefixStr, ...          % CP
                    {{modString1, pdsch.RV}}, ... % Codeword 0
                    pdschConfig.NID, ...          % N_id
                    portsString, ...              % Ports
                    refPointStr,...               % Reference point
                    dmrsSymbolMask,...            % DMRS symbol mask
                    dmrsTypeString,...            % DMRS type
                    configuration.NCellID,...     % DMRS scrambling ID
                    false,...                     % n_scid
                    numCDMGroupsWithoutData,...   % Number of CDM gro...
                    RBAllocationString,...        % RB allocation
                    startSymbol,...               % Start symbol
                    numberOfSymbols,...           % Number of symbols
                    baseGraphString,...           % Base graph
                    TBSLBRMBytes,...              % RM buffer size limit
                    reservedList,...              % Reserved RE
                    dmrsPower,...                 % DMRS power
                    dataPower,...                 % Data power
                    };

                % Generate PDSCH transmission entry
                pdschString = testCase.testCaseToString(pdsch.NSlot, pdschPDUCell, true, ...
                    transportBlockFileName, pdschDataFileName, pdschDMRSFileName);

                % Remove comma and new line from the end of the string
                pdschString = strrep(pdschString, sprintf(',\n'), '');

                % Append PDSCH transmission to the list of PDSCH
                % transmissions.
                allPdschConfigCell = [allPdschConfigCell{:}, {pdschString}];
            end % of for pdsch = pdschTransmissions

            % Build complete test model cell
            completeTestModelCell = {testModelCell, allPdcchConfigCell, allPdschConfigCell};

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                sprintf("%s,\n", cellarray2str(completeTestModelCell, true)));

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsDLProcessorUnittest
