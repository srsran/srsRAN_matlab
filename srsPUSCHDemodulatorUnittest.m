%srsPUSCHDemodulatorUnittest Unit tests for PUSCH symbol demodulator functions.
%   This class implements unit tests for the PUSCH symbol demodulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsPUSCHDemodulatorUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsPUSCHDemodulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'pusch_demodulator').
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
%                      TS38.104 Annex A.
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
        outputPath = {['testPUSCHDemodulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %DM-RS Configuration types {1, 2}.
        DMRSConfigurationType = {1, 2};

        %Modulation {pi/2-BPSK, QPSK, 16-QAM, 64-QAM, 256-QAM}.
        Modulation = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};

        %Symbols allocated to the PUSCH transmission. The symbol allocation is described
        %   by a two-element array with the starting symbol (0, ..., 13) and the length
        %   (1, ..., 14) of the PUSCH transmission. Example: [0, 14].
        SymbolAllocation = {[0, 14], [1, 13], [2, 10]}

        %Probability of a Resource element to contain a placeholder.
        probPlaceholder = {0, 0.01}
    end

    properties (Constant, Hidden)
        % Receive antenna port indices the PUSCH transmission is mapped to.
        rxPorts = {[0]}
    end % of properties (Constant, Hidden)

    properties (Hidden)
        % Carrier.
        carrier
        % Physical Uplink Shared Channel.
        pusch
        % PUSCH resource-element indices.
        puschGridIndices
        % PUSCH resource-element indices (subscript form).
        puschIndices
        % Indices of PUSCH DM-RS in the frequency grid.
        puschDmrsIndices
        % Frequency grid.
        grid
        % Channel estimates.
        ce
        % Placeholder repetition indices.
        placeholderReIndices
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pusch_demodulator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
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
        function [reIndices, xIndices, yIndices] = getPlaceholders(~, Modulation, NumLayers, NumRe, ProbPlaceholder)
        %getPlaceholders Generates a list of the RE containing repetition
        %   placeholders and their respective soft bits indices for x and y
        %   placeholders. All indices are 0based.

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
                reIndices = {};
                xIndices = [];
                yIndices = [];
                return;
            end

            % Select REs that contain placeholders.
            reIndices = 1:floor(1 / ProbPlaceholder):(NumRe - 1);

            nIndices = numel(reIndices) * NumLayers;
            xIndices = nan(nIndices * (Qm - 2), 1);
            yIndices = nan(nIndices, 1);

            % Generate placeholder bit indices.
            i = 0;
            for reIndex = reIndices
                for layer = 0:NumLayers-1
                    offset = i * (Qm - 2);
                    xIndices(offset + (1:Qm-2)) = (reIndex * NumLayers + layer) * Qm + transpose(2:Qm - 1);
                    i = i + 1;
                    yIndices(i) = (reIndex * NumLayers + layer) * Qm + 1;
                end
            end

            % If the number of indices is scalar, then convert to cell.
            if length(reIndices) < 2
                reIndices = {reIndices};
            end
        end % of function getPlaceholders(...
    end % of methods (Access = private)

    methods (TestClassSetup)
        function classSetup(obj)
            orig = rng;
            obj.addTeardown(@rng,orig)
            rng('default');
        end
    end

    methods (Access = private)
        function setupsimulation(obj, DMRSConfigurationType, Modulation, SymbolAllocation)
        % Sets secondary simulation variables.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH

            % Configure carrier.
            NCellID = randi([0, 1007]);
            obj.carrier = srsConfigureCarrier(NCellID);

            % Prepare PRB set.
            NumPRB = randi([1, 15]);
            PRBSet = 0:(NumPRB-1);
            NID = obj.carrier.NCellID;

            % Configure PUSCH.
            NumLayers = 1;
            RNTI = randi([1, 65535]);
            obj.pusch = srsConfigurePUSCH(NumLayers, Modulation, PRBSet, SymbolAllocation, NID, RNTI);
            obj.pusch.DMRS.DMRSConfigurationType = DMRSConfigurationType;
            obj.pusch.DMRS.DMRSAdditionalPosition = randi([0, 3]);
            obj.pusch.DMRS.NumCDMGroupsWithoutData = randi([1, obj.pusch.DMRS.DMRSConfigurationType + 1]);

            % Generate PUSCH data grid indices.
            [obj.puschGridIndices, puschInfo] = nrPUSCHIndices(obj.carrier, obj.pusch);
            [obj.puschIndices] = nrPUSCHIndices(obj.carrier, obj.pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Generate DM-RS for PUSCH grid indices.
            obj.puschDmrsIndices = nrPUSCHDMRSIndices(obj.carrier, obj.pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Generate random encoded and rate-matched codeword.
            cw = randi([0, 1], puschInfo.G, 1);

            % Modulate PUSCH.
            txSymbols = nrPUSCH(obj.carrier, obj.pusch, cw);

            % Generate grid.
            obj.grid = nrResourceGrid(obj.carrier);

            % Put PUSCH symbols in grid.
            obj.grid(obj.puschGridIndices) = txSymbols;

            % OFDM information.
            ofdmInfo = nrOFDMInfo(obj.carrier.NSizeGrid, obj.carrier.SubcarrierSpacing);

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
            obj.ce = nrPerfectChannelEstimate(obj.carrier,pathGains,pathFilters);

        end % of function setupsimulation(obj, DMRSConfigurationType, Modulation, SymbolAllocation, probPlaceholder)
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, DMRSConfigurationType, Modulation, SymbolAllocation, probPlaceholder)
        %testvectorGenerationCases Generates a test vector for the given
        %   DMRSConfigurationType, Modulation, SymbolAllocation and probPlaceholder.

            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = obj.generateTestID;

            % Configure the test.
            setupsimulation(obj, DMRSConfigurationType, Modulation, SymbolAllocation);

            % Select noise variance between 0.0001 and 0.01.
            noiseVar = rand() * 0.0099 + 0.0001;

            % Generate noise.
            noise = (randn(size(obj.grid)) + 1j * randn(size(obj.grid))) * sqrt(noiseVar / 2);

            % Generate receive grid.
            rxGrid = obj.grid .* obj.ce + noise;

            % Extract PUSCH symbols.
            rxSymbols = rxGrid(obj.puschGridIndices);

            % Extract CE for PUSCH.
            cePusch = obj.ce(obj.puschGridIndices);

            % Equalize.
            [eqSymbols, eqNoise] = srsChannelEqualizer(rxSymbols, cePusch, 'ZF', noiseVar, 1.0);

            % Soft demapping.
            softBits = srsDemodulator(eqSymbols, obj.pusch.Modulation, eqNoise);

            % Generate repetition placeholders.
            [obj.placeholderReIndices, xBitIndices, yBitIndices] = obj.getPlaceholders(obj.pusch.Modulation, obj.pusch.NumLayers, length(eqSymbols), probPlaceholder);

            % Reverse Scrambling. Attention: placeholderBitIndices are
            % 0based.
            schSoftBits = nrPUSCHDescramble(softBits, obj.pusch.NID, obj.pusch.RNTI, xBitIndices + 1, yBitIndices + 1);

            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = symbolAllocationMask2string(obj.puschDmrsIndices);

            % Write each complex symbol and their associated indices into a binary file.
            obj.saveDataFile('_test_input_symbols', testID, ...
                @writeResourceGridEntryFile, rxSymbols, obj.puschIndices);

            % Write channel estimates to a binary file.
            obj.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, obj.ce(:));

            % Write soft bits to a binary file.
            obj.saveDataFile('_test_output', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = cellarray2str(obj.rxPorts, true);

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = zeros(obj.carrier.NSizeGrid, 1);
            rbAllocationMask(obj.pusch.PRBSet + 1) = 1;

            dmrsTypeString = sprintf('dmrs_type::TYPE%d', obj.pusch.DMRS.DMRSConfigurationType);

            % Generate a QAM modulation string.
            if iscell(obj.pusch.Modulation)
                error('Unsupported');
            else
                switch obj.pusch.Modulation
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
                obj.pusch.RNTI, ...                         % rnti
                rbAllocationMask, ...                       % rb_mask
                modString, ...                              % modulation
                obj.pusch.SymbolAllocation(1), ...          % start_symbol_index
                obj.pusch.SymbolAllocation(2), ...          % nof_symbols
                dmrsSymbolMask, ...                         % dmrs_symb_pos
                dmrsTypeString, ...                         % dmrs_config_type
                obj.pusch.DMRS.NumCDMGroupsWithoutData, ... % nof_cdm_groups_without_data
                obj.pusch.NID, ...                          % n_id
                obj.pusch.NumAntennaPorts, ...              % nof_tx_layers
                obj.placeholderReIndices, ...               % placeholders
                portsString, ...                            % rx_ports
		        };

            testCaseContext = { ...
                noiseVar, ...        % noise_var
                puschCellConfig, ... % config
		        };

            testCaseString = obj.testCaseToString(testID, ...
                testCaseContext, true, '_test_input_symbols', ...
                '_test_input_estimates', '_test_output');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, DMRSConfigurationType, Modulation, SymbolAllocation, probPlaceholder)
        %mexTest  Tests the mex wrapper of the SRSGNB PUSCH demodulator.
        %   mexTest(OBJ, DMRSCONFIGURATIONTYPE, MODULATION, SYMBOLALLOCATION,
        %   PROBPLACEHOLDER) runs a short simulation with a ULSCH transmission
        %   using DMRS type DMRSCONFIGURATIONTYPE, symbol modulation MODULATION
        %   and allocation ALLOCATION and probability of a resource element
        %   containing a placeholder PROBPLACEHOLDER. Channel estimation on the
        %   PUSCH transmission is done in MATLAB and PUSCH equalization and
        %   demodulation is then performed using the mex wrapper of the srsRAN
        %   C++ component. The test is considered as passed if the recovered
        %   soft bits are coinciding with those originally transmitted.

            import srsTest.phy.srsPUSCHDemodulator

            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer

            % Configure the test.
            setupsimulation(obj, DMRSConfigurationType, Modulation, SymbolAllocation);

            % Select noise variance between 0.0001 and 0.01.
            noiseVar = rand() * 0.0099 + 0.0001;

            % Generate noise.
            noise = (randn(size(obj.grid)) + 1i * randn(size(obj.grid))) * sqrt(noiseVar / 2);

            % Generate receive grid.
            rxGrid = obj.grid .* obj.ce + noise;

            % Extract PUSCH symbols.
            rxSymbols = rxGrid(obj.puschGridIndices);

            % Extract CE for PUSCH.
            cePusch = obj.ce(obj.puschGridIndices);

            % Equalize.
            [eqSymbols, eqNoise] = srsChannelEqualizer(rxSymbols, cePusch, 'ZF', noiseVar, 1.0);

            % Generate repetition placeholders.
            [obj.placeholderReIndices, xBitIndices, yBitIndices] = obj.getPlaceholders(obj.pusch.Modulation, obj.pusch.NumLayers, length(eqSymbols), probPlaceholder);

            % Initialize the SRS PUSCH demodulator mex.
            PUSCHDemodulator = srsPUSCHDemodulator;

            % Fill the PUSCH demodulator configuration.
            placeholderIndicesLoc = obj.placeholderReIndices;
            if iscell(placeholderIndicesLoc)
                placeholderIndicesLoc = cell2mat(placeholderIndicesLoc);
            end
            PUSCHDemCfg = srsPUSCHDemodulator.configurePUSCHDem(obj.pusch, obj.carrier.NSizeGrid, obj.puschDmrsIndices, placeholderIndicesLoc, obj.rxPorts{1});

            % Run the PUSCH demodulator.
            schSoftBits = PUSCHDemodulator(rxSymbols, obj.puschIndices, obj.ce(:), PUSCHDemCfg, noiseVar);

            % Verify the correct demodulation (expected, since the SNR is very high).
            % i) Soft demapping.
            softBits = srsDemodulator(eqSymbols, obj.pusch.Modulation, eqNoise);
            % ii) Reverse Scrambling. Attention: placeholderBitIndices are 0based.
            schSoftBitsMatlab = nrPUSCHDescramble(softBits, obj.pusch.NID, obj.pusch.RNTI, xBitIndices + 1, yBitIndices + 1);
            % iii) Compare srsRAN and MATLAB results.
            obj.assertEqual(schSoftBits, int8(schSoftBitsMatlab), 'AbsTol', int8(1), 'Demodulation errors.');
        end % of function mextest
    end % of methods (Test, TestTags = {'testmex'})
end % of classdef srsPUSCHDemodulatorUnittest
