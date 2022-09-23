classdef srsPUCCHDetectorFormat1Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_detector'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_detector' tests will be erased).
        outputPath = {['testPUCCHdetector', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Numerology index (0, 1).
        %   Note: Higher numerologies are currently not considered.
        numerology = {0, 1}

        %Symbol allocation.
        %   The symbol allocation is described by a two-element row array with,
        %   in order, the first allocated symbol and the number of allocated
        %   symbols.
        SymbolAllocation = {[0, 14], [1, 13], [5, 5], [10, 4]}

        %Frequency hopping type ('neither', 'intraSlot').
        %   Note: Interslot frequency hopping is currently not considered.
        FrequencyHopping = {'neither', 'intraSlot'}

        %Number of HARQ-ACK bits (0, 1, 2).
        ackSize = {0, 1, 2}

        %Number of SR bits (0, 1).
        srSize = {0, 1}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.

            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsgnb/ran/cyclic_prefix.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'pucch_processor::format1_configuration cfg       = {};\n');
            fprintf(fileID, 'float                                  noise_var = 0;\n');
            fprintf(fileID, 'file_vector<uint32_t>                  received_symbols;\n');
            fprintf(fileID, 'file_vector<uint32_t>                  ch_estimates;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, numerology, SymbolAllocation, ...
                FrequencyHopping, ackSize, srSize)

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUCCH
            import srsMatlabWrappers.phy.upper.channel_processors.srsPUCCH1
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID.
            testID = obj.generateTestID;

            % Generate random cell ID and slot number.
            NCellID = randi([0, 1007]);

            if numerology == 0
                NSlot = randi([0, 9]);
            else
                NSlot = randi([0, 19]);
            end

            % Fix BWP size and start as well as the frame number, since they
            % are irrelevant for the test.
            NSizeGrid = 52;
            NStartGrid = 1;
            NFrame = 0;

            % Cyclic prefix can only be normal in the supported numerologies.
            CyclicPrefix = 'normal';

            % Configure the carrier according to the test parameters.
            SubcarrierSpacing = 15 * (2 .^ numerology);
            carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, NSizeGrid, ...
                NStartGrid, NSlot, NFrame, CyclicPrefix);

            % PRB assigned to PUCCH Format 1 within the BWP.
            PRBSet  = randi([0, NSizeGrid - 1]);

            if strcmp(FrequencyHopping, 'intraSlot')
                % When intraslot frequency hopping is enabled, the OCCI value must be less
                % than one fourth of the number of OFDM symbols allocated for the PUCCH.
                maxOCCindex = max([floor(SymbolAllocation(2) / 4) - 1, 0]);
                SecondHopStartPRB = randi([1, NSizeGrid - 1]);
                secondHopConfig = {SecondHopStartPRB};
            else
                % When intraslot frequency hopping is enabled, the OCCI value must be less
                % than one half of the number of OFDM symbols allocated for the PUCCH.
                maxOCCindex = max([floor(SymbolAllocation(2) / 2) - 1, 0]);
                SecondHopStartPRB = 0;
                secondHopConfig = {};
            end % of if strcmp(FrequencyHopping, 'intraSlot')

            OCCI = randi([0, maxOCCindex]);

            % We don't test group hopping or sequence hopping.
            GroupHopping = 'neither';

            % The initial cyclic shift can be set randomly.
            InitialCyclicShift = randi([0, 11]);

            % Configure the PUCCH.
            pucch = srsConfigurePUCCH(1, SymbolAllocation, PRBSet,...
                FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
                InitialCyclicShift, OCCI);

            ack = randi([0, 1], ackSize, 1);
            sr = randi([0, 1], srSize, 1);

            % Generate PUCCH Format 1 symbols.
            [symbols, indices] = srsPUCCH1(carrier, pucch, ack, sr);

            channelCoefs = randn(length(symbols), 2) * [1; 1j] / sqrt(2);
            snrdB = 20;
            noiseVar = 10^(-snrdB/10);
            noiseSymbols = randn(length(symbols), 2) * [1; 1j] * sqrt(noiseVar / 2);

            rxSymbols = symbols .* channelCoefs + noiseSymbols;

            obj.saveDataFile('_test_received_symbols', testID, ...
                @writeResourceGridEntryFile, rxSymbols, indices);

            obj.saveDataFile('_test_ch_estimates', testID, ...
                @writeResourceGridEntryFile, channelCoefs, indices);

            % Currently, we assume a single port with random index in (0, 7).
            ports = randi([0, 7]);
            portsStr = cellarray2str({ports}, true);

            cyclicPrefixConfig = matlab2srsCyclicPrefix(CyclicPrefix);

            % Generate PUCCH common configuration.
            commonPucchConfig = {...
                {numerology, NSlot}, ... % slot
                NSizeGrid, ...           % bwp_size_rb
                NStartGrid, ...          % bwp_start_rb
                cyclicPrefixConfig, ...  % cp
                PRBSet, ...              % starting_prb
                secondHopConfig, ...     % second_hop_prb
                ... carrier.NCellID, ...     % n_id
                ... carrier.NCellID, ...     % n_id_0
                length(sr), ...          % nof_sr
                length(ack), ...         % nof_harq_ack
                0, ...                   % nof_csi_part1
                0, ...                   % nof_csi_part2
                ... portsStr, ...            % ports
                };

            % Generate PUCCH Format 1 dedicated configuration.
            dedicatedPucchConfig = {...
                commonPucchConfig, ...         % common
                pucch.InitialCyclicShift, ...  % initial_cyclic_shift
                pucch.SymbolAllocation(2), ... % nof_symbols
                pucch.SymbolAllocation(1), ... % start_symbol_index
                pucch.OCCI, ...                % time_domain_occ
                };

            % Generate the test case entry.
            testCaseString = obj.testCaseToString(testID, {dedicatedPucchConfig, noiseVar}, ...
                false, '_test_received_symbols', '_test_ch_estimates');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases(...)
    end % of methods (Test, TestTags = {'testvector'})

end % of srsPUCCHDetectorFormat1Unittest < srsTest.srsBlockUnittest
