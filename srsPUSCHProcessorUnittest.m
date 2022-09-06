%srsPUSCHProcessorUnittest Unit tests for PUSCH processor functions.
%   This class implements unit tests for the PUSCH symbol processor
%   functions using the matlab.unittest framework. The simplest use
%   consists in creating an object with 
%      testCase = srsPUSCHProcessorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUSCHProcessorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_deProcessor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUSCHProcessorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHProcessorUnittest Properties (TestParameter):
%
%   SymbolAllocation  - Symbols allocated to the PUSCH transmission.
%   Modulation        - Modulation scheme.
%
%   srsPUSCHProcessorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUSCHProcessorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPUSCHProcessorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pusch_deProcessor' tests will be erased).
        outputPath = {['testPUSCHProcessor']} %, datestr(now, 30)]}
    end

    properties (TestParameter)
        %Fix Reference Channel.
        FixReferenceChannel = {...
                {'G-FR1-A3-8', 5}, ... % TS38.104 Table 8.2.1.2-1 Row 1
            }
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pusch_processor.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            
            fprintf(fileID, 'using rg_entry = resource_grid_reader_spy::expected_entry_t;\n\n');
            fprintf(fileID, 'struct fix_reference_channel_description {\n');
            fprintf(fileID, '  std::string fix_reference_channel;\n');
            fprintf(fileID, '  unsigned    channel_bandwidth_MHz;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct fix_reference_channel_slot {\n');
            fprintf(fileID, '  pusch_processor::pdu_t config;\n');
            fprintf(fileID, '  file_vector<rg_entry>  data;\n');   
            fprintf(fileID, '  file_vector<rg_entry>  dmrs;\n');   
            fprintf(fileID, '  file_vector<uint8_t>   sch_data;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  fix_reference_channel_description       description;\n');
            fprintf(fileID, '  std::vector<fix_reference_channel_slot> slots;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, FixReferenceChannel)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme. Other parameters (e.g., the RNTI)
        %   are generated randomly.

            import srsMatlabWrappers.phy.helpers.srsIndexes0BasedSubscrit
            import srsMatlabWrappers.phy.upper.waveformGenerators.srsPUSCHReferenceChannel
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.bitPack
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID
            testID = testCase.generateTestID;

            % Generate PUSCH reference channel.
            [~, cfgULFRC, info] = srsPUSCHReferenceChannel(FixReferenceChannel{1}, FixReferenceChannel{2});

            % Create reference channel name.
            referenceChannel = sprintf('%s_%d', FixReferenceChannel{1}, FixReferenceChannel{2});

            % Create fix reference channel description.
            frcDescription = {...
                ['"' FixReferenceChannel{1} '"'], ... % fix_reference_channel
                FixReferenceChannel{2}, ...           % channel_bandwidth_MHz
                };

            % Extract BWP configuration.
            bwpConfig = cfgULFRC.BandwidthParts{1};

            % Convert cyclic prefix to string
            cyclicPrefixStr = ['cyclic_prefix::', upper(bwpConfig.CyclicPrefix)];

            % Extract PUSCH configuration.
            puschConfig = cfgULFRC.PUSCH{1};

            % Extract common information
            nSymb = 14;
            nSubC = bwpConfig.NSizeBWP * 12;

            % For each PUSCH transmision resource.
            allFrcSlots = {};
            puschTransmissions = info.WaveformResources.PUSCH.Resources;
            for pusch = puschTransmissions
                transportBlockFileName = ['_', referenceChannel, '_transport_block'];
                puschDataFileName = ['_', referenceChannel, '_pdsch_data_symbols'];
                puschDMRSFileName = ['_', referenceChannel, '_pdsch_dmrs_symbols'];

                if iscell(puschConfig.Modulation)
                    error('Unsupported');
                else
                    switch puschConfig.Modulation
                        case 'QPSK'
                            modString = 'modulation_scheme::QPSK';
                        case '16QAM'
                            modString = 'modulation_scheme::QAM16';
                        case '64QAM'
                            modString = 'modulation_scheme::QAM64';
                        case '256QAM'
                            modString = 'modulation_scheme::QAM256';
                    end
                end

                % Convert PUSCH data indices to 0based subscript
                puschDataIndices = srsIndexes0BasedSubscrit(pusch.ChannelIndices, nSubC, nSymb);

                % Convert PUSCH DM-RS indices to 0based subscript
                puschDMRSIndices = srsIndexes0BasedSubscrit(pusch.DMRSIndices, nSubC, nSymb);

                % write each complex data symbol into a binary file, and the associated indices to another
                testCase.saveDataFile(puschDataFileName, pusch.NSlot, ...
                    @writeResourceGridEntryFile, pusch.ChannelSymbols, puschDataIndices);

                % Write each complex DM-RS symbol into a binary file, and the associated indices to another
                testCase.saveDataFile(puschDMRSFileName, pusch.NSlot, ...
                    @writeResourceGridEntryFile, pusch.DMRSSymbols, puschDMRSIndices);

                % write the TB to a binary file in packed format
                transportBlockPacked = bitPack(pusch.TransportBlock);
                testCase.saveDataFile(transportBlockFileName, pusch.NSlot, @writeUint8File, transportBlockPacked);


                % Slot configuration.
                slotConfig = {log2(bwpConfig.SubcarrierSpacing/15), pusch.NSlot};

                % Generate DMRS symbol mask
                dmrsSymbolMask = symbolAllocationMask2string(puschDMRSIndices);

                % Reception port list
                portsString = '{0}';

                % Generate Resource Block allocation string
                RBAllocationString = rbAllocationIndexes2String(puschConfig.PRBSet);

                dmrsTypeString = sprintf('dmrs_type::TYPE%d', puschConfig.DMRS.DMRSConfigurationType);
                ULSCHInfo = nrULSCHInfo(length(pusch.TransportBlock), puschConfig.TargetCodeRate );
                baseGraphString = ['ldpc_base_graph_type::BG', num2str(ULSCHInfo.BGN)];
                codewordDescription = {...
                    pusch.RV, ...        % rv
                    baseGraphString, ... % ldpc_base_graph
                    'true', ...          % new_data
                    };

                pduDescription = {...
                    slotConfig, ...                               % slot
                    puschConfig.RNTI, ...                         % rnti
                    bwpConfig.NSizeBWP, ...                       % bwp_size_rb
                    bwpConfig.NStartBWP, ...                      % bwp_start_rb
                    cyclicPrefixStr, ...                          % cp
                    modString, ...                                % modulation
                    {codewordDescription}, ...                    % codeword
                    {}, ...                                       % uci
                    puschConfig.NID, ...                          % n_id
                    puschConfig.NumAntennaPorts, ...              % nof_tx_layers
                    portsString, ...                              % rx_ports
                    dmrsSymbolMask, ...                           % dmrs_symb_pos
                    dmrsTypeString, ...                           % dmrs_config_type
                    puschConfig.DMRS.NIDNSCID, ...                % scrambling_id
                    puschConfig.DMRS.NSCID, ...                   % n_scid
                    puschConfig.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                    RBAllocationString, ...                       % freq_alloc
                    puschConfig.SymbolAllocation(1), ...          % start_symbol_index
                    puschConfig.SymbolAllocation(2), ...          % nof_symbols
                    'ldpc::MAX_CODEBLOCK_SIZE / 8', ...           % tbs_lbrm_bytes
                    };
                                
                % Generate PUSCH transmission entry
                frcSlotString = testCase.testCaseToString(pusch.NSlot, pduDescription, true, ...
                    puschDataFileName, puschDMRSFileName, transportBlockFileName);

                % Remove comma and new line from the end of the string
                frcSlotString = strrep(frcSlotString, sprintf(',\n'), '');

                % Append PDSCH transmission to the list of PDSCH
                % transmissions.
                allFrcSlots = [allFrcSlots{:}, {frcSlotString}];
            end % for pusch = puschTransmissions

            % Build complete test model cell
            frcCell = {frcDescription, allFrcSlots};

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                sprintf("%s,\n", cellarray2str(frcCell, true)));

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHProcessorUnittest
