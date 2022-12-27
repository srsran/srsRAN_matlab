%srsPUCCHDemodulatorFormat2Unittest Unit tests for PUCCH Format 2 symbol demodulator functions.
%   This class implements unit tests for the PUCCH Format 2 symbol demodulator functions using
%   the matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUCCHDemodulatorFormat2Unittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUCCHDemodulatorFormat2Unittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pucch_demodulator_format2').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUCCHDemodulatorFormat2Unittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHDemodulatorFormat2Unittest Properties (TestParameter):
%
%   SymbolAllocation  - Symbols allocated to the PUCCH transmission.
%
%   PRBNum - Number of contiguous PRB allocated to PUCCH Format 2.
%
%   srsPUCCHDemodulatorFormat2Unittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHDemodulatorFormat2Unittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPUCCHDemodulatorFormat2Unittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pucch_demodulator_format2'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pucch_demodulator_format2' tests will be erased).
        outputPath = {['testPUCCHDemodulatorFormat2', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)

        %Symbols allocated to the PUCCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PUCCH transmission. Example: [13, 1].
        SymbolAllocation = {[0, 1], [6, 2], [12, 2]};

        %Number of contiguous PRB allocated to PUCCH Format 2 (1...16).
        PRBNum = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};   
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
           
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pucch_demodulator.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
           
            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  unsigned                                 grid_nof_prb;\n');
            fprintf(fileID, '  unsigned                                 grid_nof_symbols;\n');
            fprintf(fileID, '  float                                    noise_var;\n');
            fprintf(fileID, '  pucch_demodulator::format2_configuration config;\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                               context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '  file_vector<cf_t>                                       estimates;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       uci_codeword;\n');
            fprintf(fileID, '};\n');

        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, PRBNum)
        %testvectorGenerationCases Generates a test vector for the given 
        % Fixed Reference Channel.

            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeComplexFloatFile
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUCCH
            import srsMatlabWrappers.phy.upper.channel_processors.srsPUCCH2

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate random cell ID.
            NCellID = randi([0, 1007]);

            % Generate a random NID.
            NID = randi([0, 1023]);

            % Generate a random RNTI.
            RNTI = randi([1, 65535]);

            % Maximum resource grid size.
            MaxGridSize = 275;

            % Resource grid starts at CRB0.
            NStartGrid = 0;                    

            % BWP start relative to CRB0.
            NStartBWP = randi([0, MaxGridSize - PRBNum - 1]);

            % BWP size. 
            % PUCCH Format 2 frequency allocation must fit inside the BWP.
            NSizeBWP = randi([PRBNum, MaxGridSize - NStartBWP]);

            % PUCCH PRB Start relative to the BWP.
            PRBStart = randi([0, NSizeBWP - PRBNum]);

            % Fit resource grid size to the BWP.
            NSizeGrid = NStartBWP + NSizeBWP;
            
            % PRB set assigned to PUCCH Format 2 within the BWP.
            % Each element within the PRB set indicates the location of a
            % Resource Block relative to the BWP starting PRB.
            PRBSet = PRBStart : PRBStart + PRBNum - 1;
           
            % Normal cyclic prefix.
            CyclicPrefix = 'normal';

            % Configure the carrier according to the test parameters.
            carrier = srsConfigureCarrier(NCellID, NSizeGrid, ...
                NStartGrid, CyclicPrefix);

            % Resource grid dimensions.
            nofGridSubcs = NSizeGrid * 12;
            nofGridSymbols = carrier.SymbolsPerSlot;

            % No frequency hopping.
            FrequencyHopping = 'neither';

            % Configure the PUCCH.
            pucch = srsConfigurePUCCH(2, NStartBWP, NSizeBWP, SymbolAllocation, ... 
                 PRBSet, FrequencyHopping, NID, RNTI);         

            % QPSK modulation has 2 bit per symbol.
            modulationOrder = 2;
            
            % Number of PUCCH Subcarriers.
            nofPUCCHSubcs = PRBNum * 12;

            % Number of PUCC Subcarriers used for DM-RS.
            % DM-RS is mapped to subcarriers 1, 4, 7, 10 of each PRB.
            nofPUCCHDMRSSubcs = 4 * PRBNum;

            nofPUCCHDataSubcs = nofPUCCHSubcs - nofPUCCHDMRSSubcs;

            % Number of PUCCH data RE in a single slot.
            nofPUCCHDataRE = nofPUCCHDataSubcs * SymbolAllocation(2);

            % Number of bits that can be mapped to the available radio
            % resources.
            [~, info] = nrPUCCHIndices(carrier, pucch);
            uciCWLength = info.G;
            
            % Generate a random UCI codeword that fills the available PUCCH resources.
            uciCW = randi([0, 1], uciCWLength, 1);

            % Modulate PUCCH Format 2.
            [modulatedSymbols, dataSymbolIndices] = srsPUCCH2(carrier, pucch, uciCW);

            if (length(dataSymbolIndices) ~= nofPUCCHDataRE)
                error("Inconsistent UCI Codeword and PUCCH index list lengths");
            end

            % Create some noise samples with different variances. Round standard 
            % deviation to reduce double to float error in the soft-demodulator.
            normNoise = (randn(nofPUCCHDataRE, 1) + 1i * randn(nofPUCCHDataRE, 1)) / sqrt(2);
            noiseStd = round(0.1 + 0.9 * rand(), 1);
            noiseVar = noiseStd.^2;

            % Create random channel estimates with a single Rx port and Tx layer.
            % Create a full resource grid of estimates.            
            estimates = (0.1 + 0.9 * rand(nofGridSubcs, nofGridSymbols)) + 1i * (0.1 + 0.9 * rand(nofGridSubcs, nofGridSymbols)); 
            estimates = estimates / sqrt(2);

            % Extract channel estimation coefficients corresponding to 
            % PUCCH control data RE.
            dataChEsts = estimates(sub2ind(size(estimates), dataSymbolIndices(:, 1) + 1, dataSymbolIndices(:, 2) + 1));
            
            % Create noisy modulated symbols.
            channelSymbols = dataChEsts .* modulatedSymbols + (noiseStd * normNoise);

            % Equalize channel symbols.
            [eqSymbols, eqNoiseVars] = srsChannelEqualizer(channelSymbols, dataChEsts, 'ZF', noiseVar, 1);

            % Write each complex symbol and their associated indices into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, channelSymbols, dataSymbolIndices);

            % Write channel estimates to a binary file.
            testCase.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, estimates(:));

            % Convert equalized symbols into softbits.
            schSoftBits = srsDemodulator(eqSymbols(:), 'QPSK', eqNoiseVars(:));

            % Scrambling sequence for PUCCH.
            [scSequence, ~] = nrPUCCHPRBS(NID, RNTI, length(schSoftBits));
            
            % Encode the scrambling sequence into the sign, so it can be
            % used with soft bits.
            scSequence = -(scSequence * 2) + 1;

            % Apply descrambling.
            schSoftBits = schSoftBits .* scSequence;

            % Write soft bits to a binary file.
            testCase.saveDataFile('_test_output_sch_soft_bits', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = '{0}';

            % First PRB within the resource grid allocated to PUCCH.
            firstPRB = NStartBWP + PRBStart;

            pucchF2Config = {...
                portsString, ...         % rx_ports                
                firstPRB, ...            % first_prb
                PRBNum, ...              % nof_prb
                SymbolAllocation(1), ... % start_symbol_index
                SymbolAllocation(2), ... % nof_symbols
                RNTI, ...                % rnti
                NID, ...                 % n_id
		    };

            testCaseContext = { ...
                NSizeGrid, ...      % grid_nof_prb
                nofGridSymbols, ... % grid_nof_symbols
                noiseVar, ...       % noise_var
                pucchF2Config, ...  % config
		    };

            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_input_estimates', '_test_output_sch_soft_bits');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHDemodulatorFormat2Unittest
