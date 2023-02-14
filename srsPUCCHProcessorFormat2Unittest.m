%srsPUCCHProcessorFormat2Unittest Unit tests for PUCCH Format 2 processor function.
%   This class implements unit tests for the PUCCH Format 2 processor function using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHProcessorFormat2Unittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHProcessorFormat2Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_processor_format2').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHProcessorFormat2Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHProcessorFormat2Unittest Properties (TestParameter):
%
%   SymbolAllocation - PUCCH Format 2 time allocation as array containing
%                      the start symbol index and the number of symbols.
%   nofHarqAck       - Number of bits of the HARQ-ACK payload.
%   nofSR            - Number of bits of the SR payload.
%   nofCSIPart1      - Number of bits of the CSI Part 1 payload.
%   nofCSIPart2      - Number of bits of the CSI Part 2 payload.
%   maxCodeRate      - Maximum code rate.
%
%   srsPUCCHProcessorFormat2Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHProcessorFormat2Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.
classdef srsPUCCHProcessorFormat2Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_processor_format2'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_processor_format2' tests will be erased).
        outputPath = {['testPUCCHProcessorFormat2', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)

        %Symbols allocated to the PUCCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PUCCH transmission.
        SymbolAllocation = {[0, 1], [12, 2]};

        %Number of bits of the HARQ-ACK payload (1...7).
        nofHarqAck = {3, 6};

        %Number of bits of the SR payload (0...4).
        nofSR = {0, 1};
        
        %Number of bits of the CSI Part 1 payload.
        nofCSIPart1 = {0, 4};
        
        %Number of bits of the CSI Part 2 payload.
        nofCSIPart2 = {0};
        
        %Maximum code rate, from TS38.311 Section 6.3.2, PUCCH-config
        %   information element (0.08, 0.15, 0.25, 0.35, 0.45, 0.6, 0.8).
        maxCodeRate = {0.08, 0.15, 0.25, 0.35, 0.45, 0.6};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
           
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pucch_processor.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
           
            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  unsigned                               grid_nof_prb;\n');
            fprintf(fileID, '  unsigned                               grid_nof_symbols;\n');
            fprintf(fileID, '  pucch_processor::format2_configuration config;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                               context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> grid;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    harq_ack;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    sr;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    csi_part_1;\n');
            fprintf(fileID, '  file_vector<uint8_t>                                    csi_part_2;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, ...
                nofHarqAck, nofSR, nofCSIPart1, nofCSIPart2, maxCodeRate)
        %testvectorGenerationCases Generates a test vector for the given
        %   Symbol allocation, HARQ-ACK, SR, CSI Part 1 and CSI Part 2 payload
        %   sizes in number of bits, and the maximum code rate. the Cell ID,
        %   NID, NID0 and RNTI are randomly generated. The number of allocated
        %   PRB is determined based on the UCI payload size and maximum code
        %   rate.

            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.writeUint8File
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUCCH
            import srsTest.helpers.matlab2srsCyclicPrefix
            import srsTest.helpers.writeResourceGridEntryFile

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate random cell ID.
            NCellID = randi([0, 1007]);

            % Generate a random NID.
            NID = randi([0, 1023]);

            % Generate a random NID0 for DM-RS scrambling.
            NID0 = randi([0, 65535]);

            % Generate a random RNTI.
            RNTI = randi([1, 65535]);

            % Normal cyclic prefix.
            CyclicPrefix = 'normal';

            % No frequency hopping.
            FrequencyHopping = 'neither';        

            % QPSK modulation has 2 bit per symbol.
            modulationOrder = 2;

            % Number of RE within a PUCCH Format 2 RB used for control data.
            dataREFormat2 = 8;

            % UCI payload size.
            nofUCIBits = nofHarqAck + nofSR + nofCSIPart1 + nofCSIPart2;
            
            % Generate UCI payload.
            harqAckPayload = randi([0, 1], nofHarqAck, 1);
            SRPayload = randi([0, 1], nofSR, 1);
            CSI1Payload = randi([0, 1], nofCSIPart1, 1);
            CSI2Payload = randi([0, 1], nofCSIPart2, 1);

            % For now, UCI multiplexing, applicable to UCI payloads contaning
            % CSI reports of two parts, is not considered. Therefore, all
            % UCI fields are appended into a single UCI segment.
            UCIPayload = [harqAckPayload; SRPayload; CSI1Payload; CSI2Payload];

            assert(length(UCIPayload) == nofUCIBits, ...
                'srsgnb_matlab:srsPUCCHProcessorFormat2Unittest', 'Wrong UCI payload length');
            
            % CRC bits added before coding.
            nofCRCBits = 0;
            if (nofUCIBits >= 12 && nofUCIBits < 20)
                nofCRCBits = 6;
            elseif (nofUCIBits >= 20)
                nofCRCBits = 11;
            end

            % Number of bits of the code block.
            nofCodeBlockBits = nofUCIBits + nofCRCBits;
            
            % Number of PRB used. It is obtained by computing the number
            % of bits in a codeword if the maximum code rate is used. The
            % obtained codeword length is used to derive the minimum number
            % of PRB required to fit the codeword into the PUCCH Format 2
            % resource.
            PRBNum = ceil(nofCodeBlockBits / ...
                (maxCodeRate * modulationOrder * dataREFormat2 * SymbolAllocation(2)));
            
            % Skip test cases where the UCI codeword does not fit into the
            % PUCCH Format 2 resources.
            if (PRBNum > 16)
                return;
            end

            % Maximum resource grid size.
            MaxGridSize = 275;

            % Resource grid starts at CRB0.
            NStartGrid = 0;                    

            % BWP start relative to CRB0.
            NStartBWP = randi([0, MaxGridSize - PRBNum]);

            % BWP size. PUCCH Format 2 frequency allocation must fit inside
            % the BWP.
            NSizeBWP = randi([PRBNum, MaxGridSize - NStartBWP]);

            % PUCCH PRB Start relative to the BWP.
            PRBStart = randi([0, NSizeBWP - PRBNum]);

            % Fit resource grid size to the BWP.
            NSizeGrid = NStartBWP + NSizeBWP;
            
            % PRB set assigned to PUCCH Format 2 within the BWP.
            % Each element within the PRB set indicates the location of a
            % Resource Block relative to the BWP starting PRB.
            PRBSet = PRBStart : (PRBStart + PRBNum - 1);  

            % Configure the carrier according to the test parameters.
            carrier = srsConfigureCarrier(NCellID, NSizeGrid, ...
                NStartGrid, CyclicPrefix);

            % Create resource grid.
            grid = nrResourceGrid(carrier, "OutputDataType", "single");
            gridDims = size(grid);
          
            % Configure the PUCCH Format 2
            pucch = srsConfigurePUCCH(2, NStartBWP, NSizeBWP, SymbolAllocation, ... 
                 PRBSet, FrequencyHopping, NID, NID0, RNTI);         

            % Get the PUCCH control data indices.
            [pucchDataIdices, info] = nrPUCCHIndices(carrier, pucch);

            % Derive the actual UCI codeword length from the radio
            % resources. This is used for rate matching.
            CodeWordLength = info.G;

            % Encode UCI payload.
            uciCW = nrUCIEncode(UCIPayload, CodeWordLength);

            % Modulate PUCCH Format 2.
            grid(pucchDataIdices) = nrPUCCH2(uciCW, NID, RNTI, "OutputDataType", "single");

            assert(length(pucchDataIdices) * modulationOrder == CodeWordLength, ...
                'srsgnb_matlab:srsPUCCHProcessorFormat2Unittest', ...
                'UCI codeword length and number of PUCCH F2 RE are not consistent');
         
            % Get the DM-RS indices.
            pucchDmrsIndices = nrPUCCHDMRSIndices(carrier, pucch);
            
            % Generate and map the DM-RS sequence.
            grid(pucchDmrsIndices) = nrPUCCHDMRS(carrier, pucch, "OutputDataType", "single");

            % Noise variance.
            snrdB = 30;
            noiseStdDev = 10 ^ (-snrdB / 20);
            noiseVar = noiseStdDev.^2;

            % Create some noise samples.
            normNoise = (randn(gridDims) + 1i * randn(gridDims)) / sqrt(2);

            % Generate channel estimates as a phase rotation in the
            % frequency domain.
            estimates = exp(1i * linspace(0, 2 * pi, gridDims(1))') * ones(1, gridDims(2));
            
            % Create noisy modulated symbols.
            rxGrid = estimates .* grid + (noiseStdDev * normNoise);
            
            % Extract PUCCH symbols from the received grid.
            rxSymbols = rxGrid(pucchDataIdices); 

            % Extract perfect channel estimates corresponding to the PUCCH.
            dataChEsts = estimates(pucchDataIdices);

            % Equalize channel symbols.
            [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, dataChEsts, 'ZF', noiseVar, 1);

            % Convert equalized symbols into softbits.
            schSoftBits = srsDemodulator(eqSymbols(:), 'QPSK', eqNoiseVars(:));

            % Scrambling sequence for PUCCH.
            [scSequence, ~] = nrPUCCHPRBS(NID, RNTI, length(schSoftBits));
            
            % Encode the scrambling sequence into the sign, so it can be
            % used with soft bits.
            scSequence = -(scSequence * 2) + 1;

            % Apply descrambling.
            schSoftBits = schSoftBits .* scSequence;

            % Decode UCI message to check for errors.
            rxUCIPayload = nrUCIDecode(schSoftBits, nofUCIBits);

            assert(isequal(rxUCIPayload, UCIPayload), ...
                'srsgnb_matlab:srsPUCCHProcessorFormat2Unittest', ...
                'Decoded UCI payload has errors');

            % Extract the elements of interest from the grid.
            rxGridSymbols = [rxGrid(pucchDataIdices); rxGrid(pucchDmrsIndices)];
            rxGridIndexes = [nrPUCCHIndices(carrier, pucch, 'IndexStyle','subscript', 'IndexBase','0based'); ...
                nrPUCCHDMRSIndices(carrier, pucch, 'IndexStyle','subscript', 'IndexBase','0based')];

            % Write the entire resource grid in a file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxGridSymbols, rxGridIndexes);


            % Write HARQ-ACK payload to a binary file.
            testCase.saveDataFile('_test_harq', testID, @writeUint8File, harqAckPayload);

            % Write SR payload to a binary file.
            testCase.saveDataFile('_test_sr', testID, @writeUint8File, SRPayload);

            % Write CSI Part 1 payload to a binary file.
            testCase.saveDataFile('_test_csi1', testID, @writeUint8File, CSI1Payload);

            % Write CSI Part 2 payload to a binary file.
            testCase.saveDataFile('_test_csi2', testID, @writeUint8File, CSI2Payload);

            % Reception port list.
            portsString = '{0}';
            
            % Slot configuration.
            slotConfig = {log2(carrier.SubcarrierSpacing/15), carrier.NSlot};

            % Convert cyclic prefix to string.
            cyclicPrefixStr = matlab2srsCyclicPrefix(carrier.CyclicPrefix);

            % Generate PUCCH Format 2 configuration.
            pucchF2Config = {...
                'nullopt', ...           % context
                slotConfig, ...          % slot
                cyclicPrefixStr, ...     % cp
                portsString, ...         % rx_ports
                NSizeBWP, ...            % bwp_size_rb
                NStartBWP, ...           % bwp_start_rb
                PRBStart, ...            % starting_prb
                {}, ...                  % second_hop_prb
                PRBNum, ...              % nof_prb
                SymbolAllocation(1), ... % start_symbol_index
                SymbolAllocation(2), ... % nof_symbols
                RNTI, ...                % rnti
                NID, ...                 % n_id
                NID0, ...                % n_id_0
                nofHarqAck, ...          % nof_harq_ack
                nofSR, ...               % nof_sr
                nofCSIPart1, ...         % nof_csi_part1
                nofCSIPart2, ...         % nof_csi_part2
		    };

            % Generate test case context.
            testCaseContext = { ...
                NSizeGrid, ...              % grid_nof_prb
                carrier.SymbolsPerSlot, ... % grid_nof_symbols
                pucchF2Config, ...          % config
		    };

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_harq', '_test_sr', '_test_csi1', '_test_csi2');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHProcessorFormat2Unittest
