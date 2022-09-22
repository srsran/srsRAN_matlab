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
%   ReferenceChannel - Fixed Reference Channels (FRC) used to generate the test
%                      symbols and PUSCH configuration. Specified in 
%                      TS-38.104 Annex A. 
%
%   SymbolAllocation  - Symbols allocated to the PUSCH transmission. This
%                       configuration overrides the default PUSCH
%                       allocation of the generated FRC signals.                        
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
        % Fixed Reference Channels.
        ReferenceChannel = {...
                {'G-FR1-A3-8', 5}, ... % TS38.104 Table 8.2.1.2-1 Row 1
                {'G-FR1-A4-8', 5}, ... % TS38.104 Table 8.2.1.2-1 Row 2
                {'G-FR1-A5-8', 5}, ... % TS38.104 Table 8.2.1.2-1 Row 3
            }

        %Symbols allocated to the PUSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0...13) and the length (1...14)
        %   of the PUSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 10]}
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
            
            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  float noise_var;\n');
            fprintf(fileID, '  pusch_demodulator::configuration                        config;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');   
            fprintf(fileID, '  file_vector<cf_t>                                       estimates;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       sch_data;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       harq_ack;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       csi_part1;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                       csi_part2;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, ReferenceChannel, SymbolAllocation)
        %testvectorGenerationCases Generates a test vector for the given 
        % Fixed Reference Channel.

            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer
            import srsMatlabWrappers.phy.upper.waveformGenerators.srsPUSCHReferenceChannel
            import srsMatlabWrappers.phy.helpers.srsIndexes0BasedSubscrit
            import srsTest.helpers.indices2SymbolMask
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Generate a PUSCH configuration object with the custom symbol
            % allocation.
            puschCustomConfig.SymbolAllocation = SymbolAllocation;
            
            % PUSCH mapping type A only supports OFDM symbol allocations
            % that start with symbol 0.
            if (SymbolAllocation(1) ~= 0)
                puschCustomConfig.MappingType = 'B';
            end

            % Generate the PUSCH Reference signal.
            [~, cfgULFRC, info] = srsPUSCHReferenceChannel(ReferenceChannel{1}, ReferenceChannel{2}, puschCustomConfig);

            % Extract PUSCH configuration.
            puschConfig = cfgULFRC.PUSCH{1};

            % Extract PUSCH resources.
            puschTransmission = info.WaveformResources.PUSCH.Resources;

            modulatedSymbols = puschTransmission.ChannelSymbols;
            dataSymbolIndices = puschTransmission.ChannelIndices;
            dmrsIndices = puschTransmission.DMRSIndices;

            % Number of subcarriers in an OFDM symbol.
            nofSubcs = length(puschConfig.PRBSet) * 12;

            % Number of OFDM symbols in a slot.
            nofOFDMSymbols = 14;

            % OFDM symbol where the PUSCH allocation starts.
            puschStartSymbol = puschConfig.SymbolAllocation(1);

            % Total number of PUSCH symbols, including the DM-RS.
            nofPUSCHSymbols = puschConfig.SymbolAllocation(2);

            % Total number of PUSCH data Resource Elements.
            nofDataResources = length(modulatedSymbols);

            % Convert PUSCH data indices to 0-based subscript.
            dataSymbolIndices = srsIndexes0BasedSubscrit(dataSymbolIndices, nofSubcs, nofOFDMSymbols);

            % Convert PUSCH DM-RS indices to 0-based subscript.
            dmrsIndices = srsIndexes0BasedSubscrit(dmrsIndices, nofSubcs, nofOFDMSymbols);
            
            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = indices2SymbolMask(dmrsIndices);

            % Number of PUSCH data symbols, excluding the DM-RS.
            nofDataSymbols = nofPUSCHSymbols - sum(dmrsSymbolMask);

            if (nofDataResources ~= nofSubcs * nofDataSymbols)
                error('Inconsistent PUSCH data dimensions');
            end
            
            % Rearrange the PUSCH data symbols into a two-dimensional
            % array indexed by OFDM subcarrier and OFDM symbol.
            modulatedSymbols = reshape(modulatedSymbols, [nofSubcs, nofDataSymbols]);

            % Create some noise samples with different variances (SNR in the range 0 -- 20 dB). Round standard 
            % deviation to reduce double to float error in the soft-demodulator.
            normNoise = (randn(size(modulatedSymbols)) + 1i * randn(size(modulatedSymbols))) / sqrt(2);
            noiseStd = round(0.1 + 0.9 * rand(), 1);
            noiseVar = noiseStd.^2;

            % Create noisy modulated symbols.
            noisySymbols = modulatedSymbols + (noiseStd * normNoise);

            puschScaling = 10 ^ (puschConfig.Power / 20);
            dmrsScaling = 10 ^ (puschConfig.DMRSPower / 20);

            % Amplitude ratio between PUSCH-EPRE and DM-RS EPRE, 
            % specified in TS 38.214 Table 6.2.2-1.
            pusch_dmrs_scaling = puschScaling / dmrsScaling;

            % Create random channel estimates with a single Rx port and Tx layer.
            % Create as many estimates as resource elements, including the DM-RS.
            estimates = (0.1 + 0.9 * rand(nofSubcs, nofPUSCHSymbols)) + 1i * (0.1 + 0.9 * rand(nofSubcs, nofPUSCHSymbols));
            estimates = pusch_dmrs_scaling * estimates / sqrt(2);

            
            eqSymbols = nan(size(noisySymbols));
            eqNoiseVars = nan(size(noisySymbols));

            % Equalize the PUSCH data symbols with their corresponding estimates
            % using the DM-RS symbol mask.
            iDataSymbol = 1;
            for iPuschSymbol = 1 : nofPUSCHSymbols
                
                % Skip the DM-RS symbols. 
                if (dmrsSymbolMask(iPuschSymbol + puschStartSymbol) == 0)

                    % Apply Equalization.
                    [eqSymbols(:, iDataSymbol), eqNoiseVars(:, iDataSymbol)] = ...
                        srsChannelEqualizer(noisySymbols(:, iDataSymbol), ...
                        estimates(:, iPuschSymbol), 'ZF', noiseVar, pusch_dmrs_scaling);

                    iDataSymbol = iDataSymbol + 1;
                end
            end            

            % Write each complex symbol and their associated indices into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, noisySymbols, dataSymbolIndices);


            % Write channel estimates to a binary file.
            testCase.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, estimates(:));

            % Convert equalized symbols into softbits.
            schSoftBits = srsDemodulator(eqSymbols(:), puschConfig.Modulation, eqNoiseVars(:));

            % Descramble softbits.
            schSoftBits = nrPUSCHDescramble(schSoftBits, puschConfig.NID, puschConfig.RNTI);

            % Write soft bits to a binary file.
            testCase.saveDataFile('_test_output_sch_soft_bits', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = '{0}';

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = zeros(max(puschConfig.PRBSet),1);
            rbAllocationMask(puschConfig.PRBSet + 1) = 1;

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', puschConfig.DMRS.DMRSConfigurationType);

            % Generate a QAM modulation string.
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

            % Generate DMRS symbol mask.
            dmrsSymbolMaskStr = symbolAllocationMask2string(dmrsIndices);

            puschCellConfig = {...
                puschConfig.RNTI, ...                         % rnti
                rbAllocationMask, ...                         % rb_mask
                modString, ...                                % modulation
                puschConfig.SymbolAllocation(1), ...          % start_symbol_index
                puschConfig.SymbolAllocation(2), ...          % nof_symbols
                dmrsSymbolMaskStr, ...                        % dmrs_symb_pos
                dmrsTypeString, ...                           % dmrs_config_type
                puschConfig.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                puschConfig.NID, ...                          % n_id
                puschConfig.NumAntennaPorts, ...              % nof_tx_layers
                portsString, ...                              % rx_ports
		    };

            testCaseContext = { ...
                noiseVar, ...        % noise_var
                puschCellConfig, ... % config
		    };

            testCaseString = testCase.testCaseToString(testID, testCaseContext, true, ...
                '_test_input_symbols', '_test_input_estimates', '_test_output_sch_soft_bits', ...
                '_test_output_harq_ack_soft_bits', '_test_output_csi_part1_soft_bits', ...
                '_test_output_csi_part2_soft_bits');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHDemodulatorUnittest
