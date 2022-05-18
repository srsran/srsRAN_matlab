%srsDLProcessor vector tests for downlink processor functions.
%   This class implements vector tests for the downlink processor functions
%   using the matlab.unittest framework. The simplest use consists in
%   creating an object with
%      testCase = srsDLProcessor
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsDLProcessor Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dl_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper').
%
%   srsDLProcessor Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsDLProcessor Properties (TestParameter):
%
%   referenceChannel - Determines the reference channel to generate.
%
%   srsDLProcessor Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vectors according to the provided
%                               parameters.
%
%   srsDLProcessor Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsDLProcessor < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dl_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/'
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
                '#include "../resource_grid_test_doubles.h"\n'...
                '#include "srsgnb/phy/upper/channel_processors/pdsch_processor.h"\n'...
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
                'struct test_case_t {\n'...
                '  test_model_description test_model;\n'...
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
            import srsTest.helpers.writeUint8File
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.array2str
            import srsTest.helpers.cellarray2str

            % Generate DL Reference channel
            [description, configuration, info] = srsDLReferenceChannel(referenceChannel);

            % Extract configuration
            bandwidthPart = configuration.BandwidthParts{1};
            pdschConfig = configuration.PDSCH{1};

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
            nSubC = bandwidthPart.NSizeBWP * 12;

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

                % Write each PDSCH Data complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile(pdschDataFileName, pdsch.NSlot, @writeResourceGridEntryFile, pdsch.ChannelSymbols, pdschDataIndices);

                % Write each PDSCH DMRS complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile(pdschDMRSFileName, pdsch.NSlot, @writeResourceGridEntryFile, pdsch.DMRSSymbols, pdschDMRSIndices);

                % Convert cyclic prefix to TagoRAN type
                cyclicPrefixStr = ['cyclic_prefix::', upper(bandwidthPart.CyclicPrefix)];

                % Generate DMRS symbol mask
                dmrsSymbolMask = zeros(1,14);
                dmrsSymbolMask(pdsch.DMRSSymbolSet + 1) = 1;

                % Generate the test case entry
                slotConfig = {log2(bandwidthPart.SubcarrierSpacing/15), pdsch.NSlot};
                portsString = '{0}';
                dmrsTypeString = sprintf('dmrs_type::TYPE%d', pdschConfig.DMRS.DMRSConfigurationType);
                refPointStr = ['pdsch_processor::pdu_t::', pdschConfig.DMRS.DMRSReferencePoint  ];
                numCDMGroupsWithoutData = pdschConfig.DMRS.NumCDMGroupsWithoutData;
                startSymbol = pdschConfig.SymbolAllocation(1);
                numberOfSymbols = pdschConfig.SymbolAllocation(2);
                DLSCHInfo = nrDLSCHInfo(length(pdsch.TransportBlock(:,1)), pdschConfig.TargetCodeRate );
                baseGraphString = ['ldpc::base_graph_t::BG', num2str(DLSCHInfo.BGN)];
                TBSLBRMBytes = 25344 / 8;
                reservedList = srsCSIRS2ReservedCell(configuration, pdsch.CSIRSResources);
                dataPower = 0;
                dmrsPower = pdschConfig.DMRSPower;

                % Generate Resource Block allocation string
                firstRB = pdschConfig.PRBSet(1);
                lastRB = pdschConfig.PRBSet(end);
                countRB = lastRB - firstRB + 1;
                if length(pdschConfig.PRBSet) == countRB
                    % Contiguous non-interleaved
                    RBAllocationString = sprintf(...
                        'rb_allocation(%d, %d, vrb_to_prb_mapping_type::NON_INTERLEAVED)', ...
                        firstRB, countRB);
                else
                    % Non-contiguous and non-interleaved
                    RBAllocationString = ['rb_allocation({', array2str(pdschConfig.PRBSet), '}, vrb_to_prb_mapping_type::NON_INTERLEAVED)'];
                end


                % Prepare PDSCH configuration
                pdschPDUCell = {...
                    slotConfig, ...               % Slot
                    pdschConfig.RNTI, ...         % RNTI
                    bandwidthPart.NSizeBWP, ...   % BWP size
                    bandwidthPart.NStartBWP, ...  % BWP Start
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
            completeTestModelCell = {testModelCell, allPdschConfigCell};

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, ...
                sprintf("%s,\n", cellarray2str(completeTestModelCell, true)));

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsDLProcessor
