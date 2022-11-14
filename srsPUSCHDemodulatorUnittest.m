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
        outputPath = {['testPUSCHDemodulator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %DM-RS Configuration types {1, 2}.
        DMRSConfigurationType = {1, 2};

        %Modulation {pi/2-BPSK, QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};

        %Symbols allocated to the PUSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol {0, ..., 13} and the length 
        %   {1, ..., 14} of the PUSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 10]}

        %Probability of a Resource element to contain a placeholder.
        probPlaceholder = {0, 0.01}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsgnb/phy/upper/channel_processors/pusch_demodulator.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
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
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Access = private)
        function [reIndexes, xIndexes, yIndexes] = getPlaceholders(~, Modulation, NumLayers, NumRe, ProbPlaceholder)
        %getPlaceholders Generates a list of the RE containing repetition
        %   placeholders and their respective soft bits indexes for x and y 
        %   placeholders. All indexes are 0based.
            xIndexes = [];
            yIndexes = [];

            % Deduce modulation order.
            Qm = 1;
            switch Modulation
                case 'QPSK'
                    Qm = 2;
                case '16QAM'
                    Qm = 4;
                case '64QAM'
                    Qm = 6;
                case '256QAM'
                    Qm = 8;
            end

            % Early return if the modulation order is not suffcient or the 
            % probability of placeholder is zero.
            if (Qm < 2) || (ProbPlaceholder == 0)
                reIndexes = {};
                return;
            end

            % Select REs that contain placeholders.
            reIndexes = 1:floor(1 / ProbPlaceholder):(NumRe - 1);
            
            % Generate placeholder bit indexes.
            for reIndex = reIndexes
                for layer = 0:NumLayers-1
                    xIndexes = [xIndexes; ((reIndex * NumLayers + layer) * Qm + transpose(2:Qm - 1))];
                    yIndexes = [yIndexes; ((reIndex * NumLayers + layer) * Qm + 1)];
                end
            end

            % If the number of indexes is scalar, then convert to cell.
            if length(reIndexes) < 2
                reIndexes = {reIndexes};
            end
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
        function testvectorGenerationCases(testCase, DMRSConfigurationType, Modulation, SymbolAllocation, probPlaceholder)
        %testvectorGenerationCases Generates a test vector for the given 
        %   DMRSConfigurationType, Modulation, SymbolAllocation and probPlaceholder.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
            import srsMatlabWrappers.phy.helpers.srsIndexes0BasedSubscrit
            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID by looking at the number of files 
            % generated so far.
            testID = testCase.generateTestID;

            % Configure carrier.
            NCellID = randi([0, 1007]);
            carrier = srsConfigureCarrier(NCellID);

            % Prepare PRB set.
            NumPRB = randi([1, 15]);
            PRBSet = 0:(NumPRB-1);
            NID = carrier.NCellID;

            % Configure PUSCH.
            NumLayers = 1;
            RNTI = randi([1, 65535]);
            pusch = srsConfigurePUSCH(NumLayers, Modulation, PRBSet, SymbolAllocation, NID, RNTI);
            pusch.DMRS.DMRSConfigurationType = DMRSConfigurationType;
            pusch.DMRS.DMRSAdditionalPosition = randi([0, 3]);
            pusch.DMRS.NumCDMGroupsWithoutData = randi([1, pusch.DMRS.DMRSConfigurationType + 1]);

            % Generate PUSCH data grid indices.
            [puschGridIndices, puschInfo] = nrPUSCHIndices(carrier, pusch);
            [puschIndices] = nrPUSCHIndices(carrier, pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Generate DM-RS for PUSCH grid indices.
            puschDmrsIndices = nrPUSCHDMRSIndices(carrier, pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Generate random encoded and rate-matched codeword.
            cw = randi([0, 1], puschInfo.G, 1);

            % Modulate PUSCH.
            txSymbols = nrPUSCH(carrier, pusch, cw);

            % Generate grid.
            grid = nrResourceGrid(carrier);

            % Put PUSCH symbols in grid.
            grid(puschGridIndices) = txSymbols;

            % OFDM information.
            ofdmInfo = nrOFDMInfo(carrier.NSizeGrid, carrier.SubcarrierSpacing);

            % Prepare channel.
            tdl = nrTDLChannel;
            tdl.DelayProfile = 'TDL-C';
            tdl.DelaySpread = 100e-9;
            tdl.MaximumDopplerShift = 300;
            tdl.SampleRate = ofdmInfo.SampleRate;
            tdl.NumReceiveAntennas = 1;

            T = tdl.SampleRate * 1e-3;
            tdlInfo = info(tdl);
            Nt = tdlInfo.NumTransmitAntennas;
            in = complex(randn(T,Nt),randn(T,Nt));

            [~,pathGains] = tdl(in);
            pathFilters = getPathFilters(tdl);

            % Generate channel estimates.
            ce = nrPerfectChannelEstimate(carrier,pathGains,pathFilters);

            % Select noise variance between 0.0001 and 0.01.
            noiseVar = rand() * 0.0099 + 0.0001;

            % Generate noise.
            noise = (randn(size(grid)) + 1i * randn(size(grid))) * sqrt(noiseVar / 2);

            % Generate receive grid.
            rxGrid = grid .* ce + noise;

            % Extract PUSCH symbols.
            rxSymbols = rxGrid(puschGridIndices);

            % Extract CE for PUSCH.
            cePusch = ce(puschGridIndices);

            % Equalize.
            [eqSymbols, eqNoise] = srsChannelEqualizer(rxSymbols, cePusch, 'ZF', noiseVar, 1.0);

            % Soft demapping.
            softBits = srsDemodulator(eqSymbols, pusch.Modulation, eqNoise);

            % Generate repetition placeholders.
            [placeholderReIndexes, xBitIndexes, yBitIndexes] = testCase.getPlaceholders(pusch.Modulation, pusch.NumLayers, length(eqSymbols), probPlaceholder);

            % Reverse Scrambling. Attention: placeholderBitIndexes are
            % 0based. 
            schSoftBits = nrPUSCHDescramble(softBits, pusch.NID, pusch.RNTI, xBitIndexes + 1, yBitIndexes + 1);

            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(puschDmrsIndices);

            % Write each complex symbol and their associated indices into a binary file.
            testCase.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxSymbols, puschIndices);

            % Write channel estimates to a binary file.
            testCase.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, ce(:));

            % Write soft bits to a binary file.
            testCase.saveDataFile('_test_output', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = '{0}';

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = zeros(carrier.NSizeGrid, 1);
            rbAllocationMask(pusch.PRBSet + 1) = 1;

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', pusch.DMRS.DMRSConfigurationType);

            % Generate a QAM modulation string.
            if iscell(pusch.Modulation)
                error('Unsupported');
            else
                switch pusch.Modulation
                    case 'pi/2-BPSK'
                        modString = 'modulation_scheme::PI_2_BPSK';
                    case 'BPSK'
                        modString = 'modulation_scheme::BPSK';
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
                pusch.NumAntennaPorts, ...              % nof_tx_layers
                placeholderReIndexes, ...               % placeholders
                portsString, ...                        % rx_ports
		    };

            testCaseContext = { ...
                noiseVar, ...        % noise_var
                puschCellConfig, ... % config
		    };

            testCaseString = testCase.testCaseToString(testID, ...
                testCaseContext, true, '_test_input_symbols', ...
                '_test_input_estimates', '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHDemodulatorUnittest
