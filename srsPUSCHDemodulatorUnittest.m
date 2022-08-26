%srsPUSCHDemodulatorUnittest Unit tests for PUSCH symbol demodulator functions.
%   This class implements unit tests for the PUSCH symbol demodulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUSCHDemodulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUSCHDemodulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_dedemodulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/channel_processors').
%
%   srsPUSCHDemodulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHDemodulatorUnittest Properties (TestParameter):
%
%   SymbolAllocation  - Symbols allocated to the PUSCH transmission.
%   Modulation        - Modulation scheme.
%
%   srsPUSCHDemodulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUSCHDemodulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsPUSCHDemodulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'pusch_demodulator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/channel_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pusch_dedemodulator' tests will be erased).
        outputPath = {['testPUSCHDemodulator']} %, datestr(now, 30)]}
    end

    properties (TestParameter)
        %Symbols allocated to the PUSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PUSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 12]}

        %Modulation scheme ('QPSK', '16QAM', '64QAM', '256QAM').
        Modulation = {'QPSK', '16QAM', '64QAM', '256QAM'}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pusch_demodulator.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  pusch_demodulator::configuration                        config;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');   
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       noise_var;\n');
	    fprintf(fileID, '  file_vector<log_likelihood_ratio>                       sch_data;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       harq_ack;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       csi_part1;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       csi_part2;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, SymbolAllocation, Modulation)
        %testvectorGenerationCases Generates a test vector for the given SymbolAllocation,
        %   Modulation scheme. Other parameters (e.g., the RNTI)
        %   are generated randomly.

            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCHdmrs
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.upper.channel_processors.srsPUSCHmodulator
            import srsMatlabWrappers.phy.upper.signal_processors.srsPUSCHdmrs
	    import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsTest.helpers.array2str
            import srsTest.helpers.rbAllocationIndexes2String
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
	    import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeUint8File
	    import srsTest.helpers.writeFloatFile

            % Generate a unique test ID
            testID = testCase.generateTestID;

            % Generate default carrier configuration
            carrier = nrCarrierConfig;

            % configure the PUSCH according to the test parameters
            pusch = srsConfigurePUSCH(SymbolAllocation, Modulation);

            % Set randomized values
            pusch.NID = randi([1, 1023]);
            pusch.RNTI = randi([1, 65535]);

            if iscell(pusch.Modulation)
                error('Unsupported');
            else
                switch pusch.Modulation
                    case 'QPSK'
                        modOrder = 2;
                        modString = 'modulation_scheme::QPSK';
                    case '16QAM'
                        modOrder = 4;
                        modString = 'modulation_scheme::QAM16';
                    case '64QAM'
                        modOrder = 6;
                        modString = 'modulation_scheme::QAM64';
                    case '256QAM'
                        modOrder = 8;
                        modString = 'modulation_scheme::QAM256';
                end
            end


            % Calculate number of encoded bits
            nBits = length(nrPUSCHIndices(carrier, pusch)) * modOrder;

            % Generate codewords
            cws = randi([0,1], nBits, 1);

            % call the PUSCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = srsPUSCHmodulator(carrier, pusch, cws);
	    nSymbols = length(modulatedSymbols);

            % create some noise samples with different variances (SNR in the range 0 -- 20 dB).
            normNoise = randn(nSymbols, 2) * [1; 1i] / sqrt(2);
            noiseStd = 0.1 + 0.9 * rand(nSymbols, 1);
            noiseVar = noiseStd.^2;

            % create noisy modulated symbols
            noisySymbols = modulatedSymbols + noiseStd .* normNoise;
            
	    % write each complex symbol into a binary file, and the associated indices to another
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, noisySymbols, symbolIndices);

            % write noise variances to a binary file
            testCase.saveDataFile('_test_input_noisevar', testID, @writeFloatFile, noiseVar);


            % Convert modulated symbols into softbits
	    schSoftBits = srsDemodulator(modulatedSymbols, Modulation, noiseVar);

            % write soft bits to a binary file
            testCase.saveDataFile('_test_output_sch_soft_bits', testID, @writeInt8File, schSoftBits);


            % Generate DMRS symbol mask
            [~, symbolIndices] = srsPUSCHdmrs(carrier, pusch);
            dmrsSymbolMask = symbolAllocationMask2string(symbolIndices);

            % reception port list
            portsString = '{0}';

	    % generate a RB allocation mask string
	    rbAllocationMask = zeros(max(pusch.PRBSet),1);
            rbAllocationMask(pusch.PRBSet + 1) = 1;

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', pusch.DMRS.DMRSConfigurationType);

            puschCellConfig = {...
		    pusch.RNTI, ...                         % rnti
		    rbAllocationMask, ...                   % rb_mask
		    modString, ...                          % modulation
		    pusch.SymbolAllocation(1), ...          % start_symbol_index
		    pusch.SymbolAllocation(2), ...          % nof_symbols
		    dmrsSymbolMask, ...                     % dmrs_symb_pos
		    dmrsTypeString, ...                     % dmrs_config_type
		    pusch.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
		    pusch.NID, ...                          % n_id
		    pusch.NumAntennaPorts, ...               % nof_tx_layers
		    portsString, ...                        % rx_ports
		    };

            testCaseString = testCase.testCaseToString(testID, puschCellConfig, true, ...
                '_test_input_symbols', '_test_input_noisevar', '_test_output_sch_soft_bits', ...
		'_test_output_harq_ack_soft_bits', '_test_output_csi_part1_soft_bits', ...
		'_test_output_csi_part2_soft_bits');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHDemodulatorUnittest
