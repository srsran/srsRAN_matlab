%srsChEqualizerUnittest Unit tests for the channel equalizer.
%   This class implements unit tests for the channel equalizer functions using
%   the matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = srsChEqualizerUnittest
%   and then running all the tests with
%      testResults = testCase.run
%
%   srsChEqualizerUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'channel_equalizer').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/equalization').
%
%   srsChEqualizerUnittest Properties (ClassSetupParameter):
%
%   outputPath  - Path to the folder where the test results are stored.
%
%   srsChEqualizerUnittest Properties (TestParameter):
%
%   channelSize - Channel dimensions, i.e., number of receive ports and
%                 transmit layers.
%   eqType      - Equalization algorithm, either MMSE or ZF.
%
%   srsChEqualizerUnittest Methods:
%
%   MSEsimulation - Computes the expected (nominal) and empirical SNR and
%                   MSE achieved by the channel equalizer.
%
%   srsChEqualizerUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsChEqualizerUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsChEqualizerUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'channel_equalizer'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/equalization'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'channel_equalizer' tests will be erased).
        outputPath = {['testChEqualizer', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Channel dimensions.
        %   The first entry is the number of receive antenna ports, the
        %   second entry is the number of transmit layers.
        channelSize = {[1, 1], [2, 1], [3, 1], [4, 1], [2, 2]}

        %Equalizer type.
        %   MMSE or ZF.
        eqType = {'MMSE', 'ZF'}
    end

    properties (Hidden)
        %Number of Resource Blocks.
        nRB = 25
        %Subcarrier Spacing in kHz.
        scs = 15
        %FFT size.
        fftSize = 512
        %SNR in dB of the reference signals used for channel estimation.
        snr = 10
        %Amplitude scaling of the data symbols relative to the reference signals.
        beta = 1.2
        %Channel tensor (subcarrier, OFDM symbols, Rx antennas, Tx layers).
        channelTensor double
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.
        fprintf(fileID, [...
            '#include "srsran/adt/complex.h"\n' ...
            '#include "srsran/support/file_vector.h"\n' ...
            ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.
        fprintf(fileID, [...
            'template <typename T>\n' ...
            'struct re_exploded {\n' ...
            '  unsigned       nof_prb, nof_symbols, nof_slices;\n' ...
            '  file_vector<T> measurements;\n' ...
            '};\n'...
            '\n' ...
            'struct ch_estimates_exploded {\n' ...
            '  unsigned          nof_prb, nof_symbols, nof_rx_ports, nof_tx_layers;\n' ...
            '  float             noise_var;\n' ...
            '  file_vector<cf_t> estimates;\n' ...
            '};\n' ...
            '\n' ...
            'struct test_case_t {\n' ...
            '  re_exploded<cf_t>     equalized_symbols;\n' ...
            '  re_exploded<float>    equalized_noise_vars;\n' ...
            '  re_exploded<cf_t>     transmitted_symbols;\n' ...
            '  re_exploded<cf_t>     received_symbols;\n' ...
            '  ch_estimates_exploded ch_estimates;\n' ...
            '  float                 scaling;\n' ...
            '  std::string           equalizer_type;\n' ...
            '};\n'...
            ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, channelSize, eqType)
        %testvectorGenerationCases Generates a test vector for the given
        %   channel size and equalizer type.
            import srsTest.helpers.writeComplexFloatFile
            import srsTest.helpers.writeFloatFile
            import srsTest.helpers.cellarray2str

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = obj.generateTestID;

            % Create the channel estimates.
            obj.createChTensor(channelSize);

            % Generate and process the symbols.
            [eqSymbols, txSymbols, rxSymbols, eqNoiseVars] = obj.runCase(eqType, obj.beta);

            [~, nSymbols, nRx, nTx] = size(obj.channelTensor);
            noiseVar = 10^(-obj.snr/10);

            txSymbolDimensions = {...
                obj.nRB, ...           % nof_prb
                nSymbols, ...          % nof_symbols
                nTx, ...               % nof_slices
                };

            rxSymbolDimensions = {...
                obj.nRB, ...           % nof_prb
                nSymbols, ...          % nof_symbols
                nRx, ...               % nof_slices
                };

            chEstimateParams = {...
                obj.nRB, ...           % nof_prb
                nSymbols, ...          % nof_symbols
                nRx, ...               % nof_rx_ports  
                nTx, ...               % nof_tx_layers
                noiseVar, ...          % noise_var
            };

            eqTestParams = {...
                obj.beta, ...         % scaling
                ['"' eqType '"'], ... % equalizer_type
                };


            % Write the equalized symbols to a binary file.
            obj.saveDataFile('_test_output_eq_symbols', testID, @writeComplexFloatFile, eqSymbols(:));
            eqString = obj.testCaseToString(testID, txSymbolDimensions, false, '_test_output_eq_symbols');
            eqString = strrep(eqString, newline, '');

            % Write the post-equalization noise variances to a binary file.
            obj.saveDataFile('_test_output_eq_noise_vars', testID, @writeFloatFile, eqNoiseVars(:));
            eqNoiseString = obj.testCaseToString(testID, txSymbolDimensions, false, '_test_output_eq_noise_vars');
            eqNoiseString = strrep(eqNoiseString, newline, '');
            
            % Write the transmitted symbols to a binary file.
            obj.saveDataFile('_test_check_tx_symbols', testID, @writeComplexFloatFile, txSymbols(:));
            txString = obj.testCaseToString(testID, txSymbolDimensions, false, '_test_check_tx_symbols');
            txString = strrep(txString, newline, '');

            % Write the received symbols to a binary file.
            obj.saveDataFile('_test_input_rx_symbols', testID, @writeComplexFloatFile, rxSymbols(:));
            rxString = obj.testCaseToString(testID, rxSymbolDimensions, false, '_test_input_rx_symbols');
            rxString = strrep(rxString, newline, '');

            % Write the channel estimates to a binary file.
            obj.saveDataFile('_test_input_ch_estimates', testID, @writeComplexFloatFile, obj.channelTensor(:));
            chEstString = obj.testCaseToString(testID, chEstimateParams, false, '_test_input_ch_estimates');
            chEstString = strrep(chEstString, sprintf(',\n'), '');

            % Generate the test case string.
            dataString = {[eqString eqNoiseString txString rxString chEstString]};
            eqTestParams = [dataString eqTestParams];

            testCaseString = sprintf("%s,\n", cellarray2str(eqTestParams, true));

            % Add the test to the file header.
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % methods (Test, TestTags = {'testvector'})

    methods
        function [mseEmp, mseNom, snrEmp, snrNom] = MSEsimulation(obj, channelSize, eqType)
            %MSEsimulation Computes the expected (nominal) and empirical 
            %   SNR and MSE achieved by the channel equalizer for the given
            %   channel size, i.e., number of receive ports and transmit
            %   layers, and equalizer type. The results are computed for
            %   each of the generated REs.
            obj.createChTensor(channelSize);

            [nSC, nSym, ~, nTx] = size(obj.channelTensor);
            mseEmp = zeros(nSC, nSym, nTx);
            nRuns = 1000;

            if nargout > 1
                [mseNom, snrNom] = obj.computeREnominals(eqType);
                sigPower = zeros(nSC, nSym);
                noisePower = zeros(nSC, nSym);
            end

            for iRun = 1:nRuns
                [eqSymbols, txSymbols] = obj.runCase(eqType, 1);
                mseEmp = mseEmp + abs(eqSymbols - txSymbols).^2 / nRuns;

                if nargout > 1
                    [sigPwrTmp, noisePwrTmp] = obj.computePowers(eqSymbols, txSymbols, eqType);
                    sigPower = sigPower + sigPwrTmp / nRuns;
                    noisePower = noisePower + noisePwrTmp / nRuns;
                end
            end

        if nargout > 1
            snrEmp = sigPower ./ noisePower;
        end
        end % of function MSEsimulation(obj, channelSize, eqType)
    end % methods

    methods (Access = private)
        function createChTensor(obj, channelSize)
            tdl = nrTDLChannel;
            tdl.MaximumDopplerShift = 0;
            tdl.SampleRate = obj.fftSize * obj.scs * 1000;
            tdl.TransmissionDirection = 'Uplink';
            tdl.NumTransmitAntennas = channelSize(2);
            tdl.NumReceiveAntennas = channelSize(1);

            % Dummy random signal.
            T = obj.fftSize * obj.scs;
            s = randn(T, channelSize(2)) + 1j * randn(T, channelSize(2));

            % Obtain channel characterization.
            [~, pathGains] = tdl(s);
            pathFilters = getPathFilters(tdl);

            % Channel tensor.
            obj.channelTensor = nrPerfectChannelEstimate(pathGains, pathFilters, ...
                obj.nRB, obj.scs, 0);
        end % of function createChTensor(obj, channelSize)

        function [eqSymbols, txSymbols, rxSymbols, eqNoiseVars] = runCase(obj, eqType, txScaling)
            import srsLib.phy.upper.equalization.srsChannelEqualizer
            
            [nSC, nSym, nRx, nTx] = size(obj.channelTensor);

            % Tx symbols: unitary power.
            txSymbols = (randn(nSC, nSym, nTx) + 1j * randn(nSC, nSym, nTx)) / sqrt(2);

            noiseVar = 10^(- obj.snr/10);
            % Rx symbols: start with the noise.
            rxSymbols = (randn(nSC, nSym, nRx) + 1i * randn(nSC, nSym, nRx)) ...
                * sqrt(noiseVar / 2);
            % Rx symbols: scale and add transmitted symbols.
            for iRx = 1:nRx
                for iTx = 1:nTx
                    rxSymbols(:, :, iRx) = rxSymbols(:, :, iRx) ...
                        + txScaling * obj.channelTensor(:, :, iRx, iTx)  .* txSymbols(:, :, iTx);
                end
            end
            
            % Equalize the Rx symbols and compute the equivalent noise
            % variances.
            eqSymbols = nan(nSC, nSym, nTx);
            eqNoiseVars = nan(nSC, nSym, nTx);

            for iSymbol = 1 : nSym
                % Get the Rx and channel RE for a single OFDM symbol.
                rxRE = squeeze(rxSymbols(:, iSymbol, :));
                chRE = squeeze(obj.channelTensor(:, iSymbol, :, :));

                % Equalize.
                [eqSymbols(:, iSymbol, :), eqNoiseVars(:, iSymbol, :)] = ...
                    srsChannelEqualizer(rxRE, chRE, eqType, noiseVar, txScaling);
            end
            
        end % of function runCase()

        function [mseN, snrN] = computeREnominals(obj, eqType)
            noiseVar = 10^(- obj.snr/10);
            [nSC, nSym, ~, ~] = size(obj.channelTensor);

            snrN = nan(nSC, nSym);
            mseN = nan(nSC, nSym);
            for iSC = 1:nSC
                for iSym = 1:nSym
                    chMatrix = squeeze(obj.channelTensor(iSC, iSym, :, :));
                    chHch = chMatrix' * chMatrix;
                    if strcmp(eqType, 'MMSE')
                        M = (noiseVar * eye(size(chHch)) + chHch);
                    elseif strcmp(eqType, 'ZF')
                        M = chHch;
                    else
                        error('Unknown equalizer %s.', eqType);
                    end

                    Q = M \ chHch;
                    trQQH = trace(Q * Q');
                    snrN(iSC, iSym) = trQQH / trace(Q / M) / noiseVar;
                    nTx = size(Q, 1);
                    QmI = Q - eye(nTx);
                    mseN(iSC, iSym) = trace(QmI * QmI') / nTx + trace(Q / M) * noiseVar / nTx;
                end
            end
        end

        function [sigPower, noisePower] = computePowers(obj, eqSymbols, txSymbols, eqType)
            noiseVar = 10^(- obj.snr/10);
            [nSC, nSym, ~, ~] = size(obj.channelTensor);

            sigPower = nan(nSC, nSym);
            noisePower = nan(nSC, nSym);
            for iSC = 1:nSC
                for iSym = 1:nSym
                    chMatrix = squeeze(obj.channelTensor(iSC, iSym, :, :));
                    txSyms = squeeze(txSymbols(iSC, iSym, :));
                    eqSyms = squeeze(eqSymbols(iSC, iSym, :));
                    [sigPower(iSC, iSym), noisePower(iSC, iSym)] = ...
                        computeREpower(txSyms, eqSyms, chMatrix, noiseVar, eqType);
                end
            end
        end % of function computePowers(obj, eqSymbols, txSymbols, eqType)

    end % of methods (Access = private)

end % of classdef srsChEqualizerUnittest < srsTest.srsBlockUnittest

function [sigPower, noisePower] = computeREpower(txSymbols, eqSymbols, chMatrix, ...
        noiseVar, eqType)

    chHch = chMatrix' * chMatrix;
    if strcmp(eqType, 'MMSE')
        M = (noiseVar * eye(size(chHch)) + chHch);
    elseif strcmp(eqType, 'ZF')
        M = chHch;
    else
        error('Unknown equalizer %s.', eqType);
    end

    Q = M \ chHch;
    trQQH = trace(Q * Q');

    nTx = length(txSymbols);

    sigPower = trQQH / nTx;

    estNoise = eqSymbols - Q * txSymbols;
    noisePower = trace(estNoise * estNoise') / nTx;
end
