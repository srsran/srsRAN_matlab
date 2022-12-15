%srsPUCCHProcessorFormat1Unittest Unit tests for PUCCH Format 1 processor function.
%   This class implements unit tests for the PUCCH Format 1 processor function using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHProcessorFormat1Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHProcessorFormat1Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_processor').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHProcessorFormat1Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHProcessorFormat1Unittest Properties (TestParameter):
%
%   numerology           - Subcarrier numerology (0, 1).
%   intraSlotFreqHopping - Intra-slot frequency hopping. Set to true if
%                          enabled.
%   SymbolAllocation     - PUCCH Format 1 time allocation as array
%                          containing the start symbol index and the number
%                          of symbols.
%   ackSize              - Number of HARQ-ACK bits (0, 1, 2).
%   srSize               - Number of SR bits (0, 1).
%
%   srsPUCCHProcessorFormat1Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat1Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrPUCCHDMRS.

classdef srsPUCCHProcessorFormat1Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format1'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format1' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat1', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier numeorlogy (0, 1).
        numerology = {0, 1}

        %Intra-slot frequency hopping usage (inter-slot hopping is not tested).
        intraSlotFreqHopping = {false, true}

        %Relevant combinations of start symbol index {0, ..., 10} and number of symbols {4, ..., 14}. 
        SymbolAllocation = {[0, 14], [1, 13], [5, 5], [10, 4]}

        %Number of HARQ-ACK bits (0, 1, 2).
        ackSize = {0, 1, 2}
    end % of properties (TestParameter)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  pucch_processor::format1_configuration                  config;\n');
            fprintf(fileID, '  std::vector<uint8_t>                                    ack_bits;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (TestClassSetup)
        function classSetup(testCase)
            orig = rng;
            testCase.addTeardown(@rng,orig)
            rng('default');
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, intraSlotFreqHopping, SymbolAllocation, ackSize)
        %testvectorGenerationCases Generates a test vector for the given numerology, format and frequency hopping,
        %  while using a random NCellID, random NSlot and random symbol and PRB length.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUCCH
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.matlab2srsCyclicPrefix

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            % Use a unique NCellIDLoc, NSlotLoc for each test.
            NCellIDLoc = randi([0, 1007]);

            % Use a random slot number from the allowed range.
            NSlotLoc = randi([0, 10 * pow2(numerology) - 1]);

            % Fixed parameter values.
            NStartBWP = 1;
            NSizeBWP = 51;
            NSizeGrid = NStartBWP + NSizeBWP;
            NStartGrid = 0;
            CyclicPrefix = 'normal';
            GroupHopping = 'neither';
            FrequencyHopping = 'neither';
            SecondHopStartPRB = 0;

            % Random frame number.
            NFrame = randi([0, 1023]);

            % Random initial cyclic shift.
            InitialCyclicShift = randi([0, 11]);
            
            % Random start PRB index and length in number of PRBs.
            PRBSet  = randi([0, NSizeBWP - 1]);

            % When intraslot frequency hopping is disabled, the OCCI value
            % must be less than the floor of half of the number of OFDM
            % symbols allocated for the PUCCH.
            if ~intraSlotFreqHopping
                OCCI = randi([0, (floor(SymbolAllocation(2) / 2) - 1)]);
            else
                % When intraslot frequency hopping is enabled, the OCCI
                % value must be less than the floor of one-fourth of the
                % number of OFDM symbols allocated for the PUCCH. 
                maxOCCindex = floor(SymbolAllocation(2) / 4) - 1;
                if maxOCCindex == 0
                    OCCI = 0;
                else
                    OCCI = randi([0, maxOCCindex]);
                end
            end

            % Randomly select SecondHopStartPRB if intra-slot frequency
            % hopping is enabled.
            if intraSlotFreqHopping
                SecondHopStartPRB = randi([0, NSizeBWP - 1]);
                % Set respective MATLAB parameter.
                FrequencyHopping   = 'intraSlot';
            end

            % Configure the carrier according to the test parameters.
            SubcarrierSpacing = 15 * (2 .^ numerology);
            carrier = srsConfigureCarrier(NCellIDLoc, ...
                SubcarrierSpacing, NSizeGrid, NStartGrid, ...
                NSlotLoc, NFrame, CyclicPrefix);

            % Configure the PUCCH according to the test parameters.
            pucch = srsConfigurePUCCH(1, SymbolAllocation, PRBSet,...
                FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
                InitialCyclicShift, OCCI, NStartBWP, NSizeBWP);
            
            % Create resource grid.
            grid = nrResourceGrid(carrier, "OutputDataType", "single");
            gridDims = size(grid);

            ack = randi([0, 1], ackSize, 1);
            sr = [];

            if ackSize == 0
                sr = 1;
            end

             % Get the PUCCH control data indices.
            pucchDataIdices = nrPUCCHIndices(carrier, pucch);

            % Modulate PUCCH Format 1.
            FrequencyHopping = 'disabled';
            if strcmp(pucch.FrequencyHopping, 'intraSlot')
                FrequencyHopping = 'enabled';
            end

            grid(pucchDataIdices) = nrPUCCH1(ack, sr, pucch.SymbolAllocation, ...
                carrier.CyclicPrefix, carrier.NSlot, carrier.NCellID, ...
                pucch.GroupHopping, pucch.InitialCyclicShift, FrequencyHopping, ...
                pucch.OCCI, "OutputDataType", "single");

            % Get the DM-RS indices.
            pucchDmrsIndices = nrPUCCHDMRSIndices(carrier, pucch);
            
            % Generate and map the DM-RS sequence.
            grid(pucchDmrsIndices) = nrPUCCHDMRS(carrier, pucch, "OutputDataType", "single");

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-snrdB / 20);

            % Create some noise samples.
            normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

            % Generate channel estimates as a phase rotation in the frequency
            % domain.
            estimates = exp(1i * linspace(0, 2 * pi, gridDims(1))') * ones(1, gridDims(2));

            % Create noisy modulated symbols.
            rxGrid = estimates .* grid + (noiseStdDev * normNoise);

             % Extract the elements of interest from the grid.
             rxGridSymbols = [rxGrid(pucchDataIdices); rxGrid(pucchDmrsIndices)];
             rxGridIndexes = [nrPUCCHIndices(carrier, pucch, 'IndexStyle','subscript', 'IndexBase','0based'); ...
                nrPUCCHDMRSIndices(carrier, pucch, 'IndexStyle','subscript', 'IndexBase','0based')];

            % Write each complex symbol, along with its associated index,
            % into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndexes);

            % Generate a 'slot_point' configuration.
            slotPointConfig = {...
                numerology, ...                                             % numerology
                carrier.NFrame * carrier.SlotsPerFrame + carrier.NSlot, ... % system slot number
                };

            % Generate a 'cyclic_prefix' configuration.
            cyclicPrefixConfig = matlab2srsCyclicPrefix(CyclicPrefix);

            secondHopConfig = {};
            if intraSlotFreqHopping
                secondHopConfig = {pucch.SecondHopStartPRB};
            end

            % Generate PUCCH common configuration.
            pucchConfig = {...
                slotPointConfig, ...           % slot
                NSizeBWP, ...                  % bwp_size_rb
                NStartBWP, ...                 % bwp_start_rb
                cyclicPrefixConfig, ...        % cp
                pucch.PRBSet, ...              % starting_prb
                secondHopConfig, ...           % second_hop_prb
                carrier.NCellID, ...           % n_id
                length(ack), ...               % nof_harq_ack
                num2cell(0), ...               % ports
                pucch.InitialCyclicShift, ...  % initial_cyclic_shift
                pucch.SymbolAllocation(2), ... % nof_symbols
                pucch.SymbolAllocation(1), ... % start_symbol_index
                pucch.OCCI, ...                % time_domain_occ
                };

            % Generate test case cell.
            testCaseCell = {...
                pucchConfig, ...   % config
                num2cell(ack), ... % ack_bits
                };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, ...
                testCaseCell, false, '_test_input_symbols');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHProcessorFormat1Unittest