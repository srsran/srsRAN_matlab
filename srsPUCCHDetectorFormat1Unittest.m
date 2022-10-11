classdef srsPUCCHDetectorFormat1Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_detector'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_detector' tests will be erased).
        outputPath = {['testPUCCHdetector', char(datetime('now', 'Format', 'yyyyMMddHH''T''mmss'))]}
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

            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pucch_detector.h"\n');
            fprintf(fileID, '#include "srsgnb/ran/cyclic_prefix.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'pucch_detector::format1_configuration                    cfg       = {};\n');
            fprintf(fileID, 'float                                                    noise_var = 0;\n');
            fprintf(fileID, 'std::vector<uint8_t>                                     sr_bit;\n');
            fprintf(fileID, 'std::vector<uint8_t>                                     ack_bits;\n');
            fprintf(fileID, 'file_vector<resource_grid_reader_spy::expected_entry_t>  received_symbols;\n');
            fprintf(fileID, 'file_vector<resource_grid_reader_spy::expected_entry_t>  ch_estimates;\n');
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

            if (ackSize + srSize == 0)
                return;
            end

            % Generate a unique test ID.
            testID = obj.generateTestID('_test_received_symbols');

            % Generate random cell ID and slot number.
            NCellID = randi([0, 1007]);

            if numerology == 0
                NSlot = randi([0, 9]);
            else
                NSlot = randi([0, 19]);
            end

            % Fix BWP size and start as well as the frame number, since they
            % are irrelevant for the test.
            NSizeBWP = 51;
            NStartBWP = 1;
            NSizeGrid = NSizeBWP + NStartBWP;
            NStartGrid = 0;
            NFrame = 0;

            % Cyclic prefix can only be normal in the supported numerologies.
            CyclicPrefix = 'normal';

            % Configure the carrier according to the test parameters.
            SubcarrierSpacing = 15 * (2 .^ numerology);
            carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, NSizeGrid, ...
                NStartGrid, NSlot, NFrame, CyclicPrefix);

            % PRB assigned to PUCCH Format 1 within the BWP.
            PRBSet  = randi([0, NSizeBWP - 1]);

            if strcmp(FrequencyHopping, 'intraSlot')
                % When intraslot frequency hopping is enabled, the OCCI value must be less
                % than one fourth of the number of OFDM symbols allocated for the PUCCH.
                maxOCCindex = max([floor(SymbolAllocation(2) / 4) - 1, 0]);
                SecondHopStartPRB = randi([1, NSizeBWP - 1]);
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
            possibleShifts = 0:3:9;
            InitialCyclicShift = possibleShifts(randi([1, 4]));

            % Configure the PUCCH.
            pucch = srsConfigurePUCCH(1, SymbolAllocation, PRBSet,...
                FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
                InitialCyclicShift, OCCI);

            ack = randi([0, 1], ackSize, 1);
            sr = randi([0, 1], srSize, 1);

            % Generate PUCCH Format 1 symbols.
            [symbols, indices] = srsPUCCH1(carrier, pucch, ack, sr);

            if isempty(symbols)
                symbols = complex(zeros(size(indices,1), 1));
            end

            channelCoefs = randn(length(symbols), 2) * [1; 1j] / sqrt(2);
            % Ensure no channel is very small.
            channelCoefsAbs = abs(channelCoefs);
            mask = (channelCoefsAbs < 0.1);
            channelCoefs(mask) = channelCoefs(mask) ./ channelCoefsAbs(mask) * 0.1;

            % AWGN.
            snrdB = 20;
            noiseVar = 10^(-snrdB/10);
            noiseSymbols = randn(length(symbols), 2) * [1; 1j] * sqrt(noiseVar / 2);

            rxSymbols = symbols .* channelCoefs + noiseSymbols;

            obj.saveDataFile('_test_received_symbols', testID, ...
                @writeResourceGridEntryFile, rxSymbols, indices);

            obj.saveDataFile('_test_ch_estimates', testID, ...
                @writeResourceGridEntryFile, channelCoefs, indices);

            cyclicPrefixConfig = matlab2srsCyclicPrefix(CyclicPrefix);

            port = 0;
            betaPUCCH = 1;

            % Generate PUCCH Format 1 configuration.
            pucchF1Config = {...
                {numerology, NSlot},       ... % slot
                cyclicPrefixConfig,        ... % cp
                PRBSet,                    ... % starting_prb
                secondHopConfig,           ... % second_hop_prb
                pucch.SymbolAllocation(1), ... % start_symbol_index
                pucch.SymbolAllocation(2), ... % nof_symbols
                port,                      ... % antenna port
                betaPUCCH,                 ... % amplitude scaling factor
                pucch.OCCI, ...                % time_domain_occ
                pucch.InitialCyclicShift,  ... % initial_cyclic_shift
                NCellID,                   ... % pseudorandom initializer
                srSize,                    ... % number of SR bits
                ackSize,                   ... % number of ACK bits
                };

            % Generate the test case entry.
            testCaseString = obj.testCaseToString(testID, {pucchF1Config, noiseVar, num2cell(sr), num2cell(ack)}, ...
                false, '_test_received_symbols', '_test_ch_estimates');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases(...)
    end % of methods (Test, TestTags = {'testvector'})

end % of srsPUCCHDetectorFormat1Unittest < srsTest.srsBlockUnittest
