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
%   DMRSConfigurationType - PUSCH DM-RS configuration type.
%   Modulation            - PUSCH Modulation scheme.
%   probPlaceholder       - Probability of a Resource element to contain a 
%                           placeholder.
%   NumRxPorts            - Number of receive antenna ports for PUSCH.
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

        %Probability of a Resource Element to contain a placeholder.
        probPlaceholder = {0, 0.01}

        %Number of receive antenna ports for PUSCH.
        NumRxPorts = {1, 2, 4}
    end

    properties (Constant, Hidden)
    end % of properties (Constant, Hidden)

    properties (Hidden)
        % Carrier.
        carrier
        % Physical Uplink Shared Channel.
        pusch
        % PUSCH transmission resource-element indices.
        puschTxIndices
        % PUSCH reception resource-element indices (subscript form). They
        % differ from the transmission indices in the receive port
        % dimension.
        puschRxIndices
        % Indices of PUSCH DM-RS in the frequency grid.
        puschDmrsIndices
        % Transmission resource grid.
        txGrid
        % Channel estimates.
        ce
        % Placeholder repetition indices.
        placeholderReIndices
        % Receive antenna port indices the PUSCH transmission is mapped to.
        rxPorts
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/channel_processors/pusch_demodulator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_tensor.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, 'enum class ch_dims : unsigned { subcarrier = 0, symbol = 1, rx_port = 2, tx_layer = 3, nof_dims = 4 };\n\n');
            fprintf(fileID, 'struct context_t {\n');
            fprintf(fileID, '  float noise_var;\n');
            fprintf(fileID, '  pusch_demodulator::configuration                        config;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  context_t                                                            context;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t>              symbols;\n');
            fprintf(fileID, '  file_tensor<static_cast<unsigned>(ch_dims::nof_dims), cf_t, ch_dims> estimates;\n');
            fprintf(fileID, '  file_vector<log_likelihood_ratio>                                    sch_data;\n');
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
        function setupsimulation(obj, DMRSConfigurationType, Modulation, nofRxPorts)
        % Sets secondary simulation variables.
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH

            % Configure carrier.
            NCellID = randi([0, 1007]);
            NSizeGrid = 25;
            obj.carrier = srsConfigureCarrier(NCellID, NSizeGrid);

            % Set symbol allocation.
            startSymbol = randi([0 2]);
            nofSymbols = randi([7 (14 - startSymbol)]);
            SymbolAllocation = [startSymbol, nofSymbols];

            % Prepare PRB set.
            NumPRB = randi([1, NSizeGrid]);
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
            [obj.puschTxIndices, puschInfo] = nrPUSCHIndices(obj.carrier, obj.pusch);

            % Generate PUSCH indices for a single Rx port in subscript
            % form.
            puschPortIndices = nrPUSCHIndices(obj.carrier, obj.pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Number of RE per port.
            nofREPort = size(puschPortIndices, 1);

            % Set the receive port indices.
            obj.rxPorts = 0 : (nofRxPorts - 1);

            % Generate the Rx resource grid indices for all receive ports.
            obj.puschRxIndices = zeros(nofREPort * nofRxPorts, 3);
            for iPort = 0 : (nofRxPorts - 1)
                % Copy the RE and OFDM symbol index coordinates.
                obj.puschRxIndices(((nofREPort * iPort) + 1) : (nofREPort * (iPort + 1)), :) = ...
                    puschPortIndices;

                % Generate the receive port index coordinates.
                obj.puschRxIndices(((nofREPort * iPort) + 1) : (nofREPort * (iPort + 1)), 3) = ...
                 obj.rxPorts(iPort + 1) * ones(nofREPort, 1);
            end

            % Generate DM-RS for PUSCH grid indices.
            obj.puschDmrsIndices = nrPUSCHDMRSIndices(obj.carrier, obj.pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

            % Generate random encoded and rate-matched codeword.
            cw = randi([0, 1], puschInfo.G, 1);

            % Modulate PUSCH.
            txSymbols = nrPUSCH(obj.carrier, obj.pusch, cw);

            % Generate grid.
            obj.txGrid = nrResourceGrid(obj.carrier);

            % Put PUSCH symbols in grid.
            obj.txGrid(obj.puschTxIndices) = txSymbols;

            % OFDM information.
            ofdmInfo = nrOFDMInfo(obj.carrier.NSizeGrid, obj.carrier.SubcarrierSpacing);

            % Prepare channel.
            tdl = nrTDLChannel;
            tdl.DelayProfile = 'TDL-C';
            tdl.DelaySpread = 100e-9;
            tdl.MaximumDopplerShift = 300;
            tdl.SampleRate = ofdmInfo.SampleRate;
            tdl.NumReceiveAntennas = nofRxPorts;

            T = tdl.SampleRate * 1e-3;
            tdlInfo = info(tdl);
            Nt = tdlInfo.NumTransmitAntennas;
            in = complex(randn(T,Nt),randn(T,Nt));

            [~,pathGains] = tdl(in);
            pathFilters = getPathFilters(tdl);

            % Generate channel estimates.
            obj.ce = nrPerfectChannelEstimate(obj.carrier,pathGains,pathFilters);

        end % of function setupsimulation(obj, DMRSConfigurationType, Modulation, probPlaceholder, nofRxPorts)
    end % of methods (Access = Private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, DMRSConfigurationType, Modulation, probPlaceholder, NumRxPorts)
        %testvectorGenerationCases Generates a test vector for the given
        %   DMRSConfigurationType, Modulation, probPlaceholder and NumRxPorts.

            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeInt8File
            import srsTest.helpers.writeComplexFloatFile
            import srsTest.helpers.cellarray2str

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = obj.generateTestID;
            
            % Configure the test.
            setupsimulation(obj, DMRSConfigurationType, Modulation, NumRxPorts);

            % Select noise variance between 0.0001 and 0.01.
            noiseVar = rand() * 0.0099 + 0.0001;

            % Generate noise.
            noise = (randn(size(obj.txGrid)) + 1j * randn(size(obj.txGrid))) * sqrt(noiseVar / 2);

            % Generate receive grid.
            rxGrid = obj.txGrid .* obj.ce + noise;

            % Extract PUSCH Rx symbols.
            rxSymbols = complex(zeros(size(obj.puschTxIndices, 1), NumRxPorts));

            for iPort = 1:NumRxPorts
                iRxGrid = rxGrid(:, :, iPort);
                rxSymbols(:, iPort) = iRxGrid(obj.puschTxIndices);
            end
            
            % Extract CE for PUSCH.
            cePusch = complex(zeros(size(obj.puschTxIndices, 1), NumRxPorts));    
            for iPort = 1:NumRxPorts
                iCePusch = obj.ce(:, :, iPort);
                cePusch(:, iPort) = iCePusch(obj.puschTxIndices);
            end

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
                @writeResourceGridEntryFile, rxSymbols(:), obj.puschRxIndices);

            % Write channel estimates to a binary file.
            obj.saveDataFile('_test_input_estimates', testID, @writeComplexFloatFile, obj.ce(:));

            % Write soft bits to a binary file.
            obj.saveDataFile('_test_output', testID, @writeInt8File, schSoftBits);

            % Reception port list.
            portsString = cellarray2str(num2cell(obj.rxPorts), true);

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

            % Channel estimate dimensions.
            estimatesDims = {...
                size(obj.ce, 1), ... % subcarrier
                size(obj.ce, 2), ... % symbol
                size(obj.ce, 3), ... % receive port
                size(obj.ce, 4), ... % transmit layer
                };

            testCaseString = obj.testCaseToString(testID, ...
                testCaseContext, true, '_test_input_symbols', ...
                {'_test_input_estimates', estimatesDims}, '_test_output');

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})

    methods (Test, TestTags = {'testmex'})
        function mexTest(obj, DMRSConfigurationType, Modulation, probPlaceholder, NumRxPorts)
        %mexTest  Tests the mex wrapper of the SRSGNB PUSCH demodulator.
        %   mexTest(OBJ, DMRSCONFIGURATIONTYPE, MODULATION,
        %   PROBPLACEHOLDER, NUMRXPORTS) runs a short simulation with a 
        %   ULSCH transmission using DM-RS type DMRSCONFIGURATIONTYPE,
        %   symbol modulation MODULATION, probability of a resource element
        %   containing a placeholder PROBPLACEHOLDER and number of receive 
        %   antenna ports NUMRXPORTS. Channel estimation on the PUSCH
        %   transmission is done in MATLAB and PUSCH equalization and
        %   demodulation is then performed using the mex wrapper of the
        %   srsRAN C++ component. The test is considered as passed if the 
        %   recovered soft bits are coinciding with those originally transmitted.

            import srsTest.phy.srsPUSCHDemodulator
            import srsMatlabWrappers.phy.upper.channel_modulation.srsDemodulator
            import srsMatlabWrappers.phy.upper.equalization.srsChannelEqualizer

            % Configure the test.
            setupsimulation(obj, DMRSConfigurationType, Modulation, NumRxPorts);

            % Select noise variance between 0.0001 and 0.01.
            noiseVar = rand() * 0.0099 + 0.0001;

            % Generate noise.
            noise = (randn(size(obj.txGrid)) + 1i * randn(size(obj.txGrid))) * sqrt(noiseVar / 2);

            % Generate receive grid.
            rxGrid = obj.txGrid .* obj.ce + noise;

            % Extract PUSCH symbols.
            rxSymbols = complex(zeros(size(obj.puschTxIndices, 1), NumRxPorts));

            for iPort = 1:NumRxPorts
                iRxGrid = rxGrid(:, :, iPort);
                rxSymbols(:, iPort) = iRxGrid(obj.puschTxIndices);
            end
            
            % Extract CE for PUSCH.
            cePusch = complex(zeros(size(obj.puschTxIndices, 1), NumRxPorts)); 

            for iPort = 1:NumRxPorts
                iCePusch = obj.ce(:, :, iPort);
                cePusch(:, iPort) = iCePusch(obj.puschTxIndices);
            end

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
            PUSCHDemCfg = srsPUSCHDemodulator.configurePUSCHDem(obj.pusch, obj.carrier.NSizeGrid, obj.puschDmrsIndices, placeholderIndicesLoc, obj.rxPorts);

            % Run the PUSCH demodulator.
            schSoftBits = PUSCHDemodulator(rxSymbols(:), obj.puschRxIndices, obj.ce(:), PUSCHDemCfg, noiseVar);

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
