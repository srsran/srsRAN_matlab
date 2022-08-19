classdef srsChEqualizerUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'channel_equalizer'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/equalization'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'channel_equalizer' tests will be erased).
        outputPath = {['testChEqualizer', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Channel matrix size.
        %   The first entry is the number of Rx antennas, the second entry is the
        %   number of Tx layers.
        channelSize = {[1, 1], [2, 1], [2, 2]}

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
        %SNR in dB
        snr = 10
        %Channel tensor (subcarrier, OFDM symbols, Rx antennas, Tx layers).
        channelTensor double
        %Amplitude scaling.
        beta = 1.2
    end % of properties (Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.
        fprintf(fileID, [...
            '#include "srsgnb/adt/complex.h"\n' ...
            '#include "srsgnb/support/file_vector.h"\n' ...
            ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.
        fprintf(fileID, [...
            'struct re_measurement_exploded {\n' ...
            '  unsigned          nof_prb, nof_symbols, nof_slices;\n' ...
            '  file_vector<cf_t> measurements;\n' ...
            '};\n'...
            '\n' ...
            'struct ch_estimates_exploded {\n' ...
            '  unsigned          nof_prb, nof_symbols, nof_rx_ports, nof_tx_layers;\n' ...
            '  float             noise_var;\n' ...
            '  file_vector<cf_t> estimates;\n' ...
            '};\n' ...
            '\n' ...
            'struct test_case_t {\n' ...
            '  re_measurement_exploded equalized_symbols;\n' ...
            '  re_measurement_exploded transmitted_symbols;\n' ...
            '  re_measurement_exploded received_symbols;\n' ...
            '  ch_estimates_exploded   ch_estimates;\n' ...
            '  float                   scaling;\n' ...
            '};\n'...
            ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(obj, channelSize, eqType)
            import srsTest.helpers.writeComplexFloatFile

            % generate a unique test ID by looking at the number of files generated so far
            testID = obj.generateTestID;

            obj.createChTensor(channelSize);
            [eqSymbols, txSymbols, rxSymbols] = obj.runCase(eqType);

            [~, nSymbols, nRx, nTx] = size(obj.channelTensor);

            obj.saveDataFile('_test_output_eq_symbols', testID, @writeComplexFloatFile, eqSymbols(:));
            eqString = obj.testCaseToString(testID, {obj.nRB, nSymbols, nTx}, false, '_test_output_eq_symbols');
            eqString(end) = [];

            obj.saveDataFile('_test_check_tx_symbols', testID, @writeComplexFloatFile, txSymbols(:));
            txString = obj.testCaseToString(testID, {obj.nRB, nSymbols, nTx}, false, '_test_check_tx_symbols');
            txString(end) = [];

            obj.saveDataFile('_test_input_rx_symbols', testID, @writeComplexFloatFile, rxSymbols(:));
            rxString = obj.testCaseToString(testID, {obj.nRB, nSymbols, nRx}, false, '_test_input_rx_symbols');
            rxString(end) = [];

            noiseVar = 10^(-obj.snr/10);
            obj.saveDataFile('_test_input_ch_estimates', testID, @writeComplexFloatFile, obj.channelTensor(:) / obj.beta);
            chEstString = obj.testCaseToString(testID, {obj.nRB, nSymbols, nRx, nTx, noiseVar}, false, '_test_input_ch_estimates');
            chEstString(end) = [];

            % Concatenate all strings.
            testCaseString = ['{', eqString, txString, rxString, chEstString, ' ', num2str(obj.beta), ' },' newline];

            % add the test to the file header
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % methods (Test, TestTags = {'testvector'})

    methods
        function [mse, mseNom, snrEmp, snrNom] = MSEsimulation(obj, channelSize, eqType)
            obj.createChTensor(channelSize);

            [nSC, nSym, ~, nTx] = size(obj.channelTensor);
            mse = zeros(nSC, nSym, nTx);
            nRuns = 1000;

            if nargout > 1
                [mseNom, snrNom] = obj.computeREnominals(eqType);
                sigPower = zeros(nSC, nSym);
                noisePower = zeros(nSC, nSym);
            end

            for iRun = 1:nRuns
                [eqSymbols, txSymbols] = obj.runCase(eqType);
                mse = mse + abs(eqSymbols - txSymbols).^2 / nRuns;

                if nargout > 1
                    [sigPwrTmp, noisePwrTmp] = obj.computePowers(eqSymbols, txSymbols, eqType);
                    sigPower = sigPower + sigPwrTmp / nRuns;
                    noisePower = noisePower + noisePwrTmp / nRuns;
                end
            end

            snrEmp = sigPower ./ noisePower;
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

            % Channel tensor. Multiply by beta to avoid carrying it around
            % all the time.
            obj.channelTensor = obj.beta * nrPerfectChannelEstimate(pathGains, pathFilters, ...
                obj.nRB, obj.scs, 0);
        end % of function createChMatrix(obj, channelSize)

        function [eqSymbols, txSymbols, rxSymbols] = runCase(obj, eqType)
            [nSC, nSym, nRx, nTx] = size(obj.channelTensor);

            % Tx symbols: unitary power.
            txSymbols = (randn(nSC, nSym, nTx) + 1j * randn(nSC, nSym, nTx)) / sqrt(2);

            noiseVar = 10^(- obj.snr/10);
            % Rx symbols: start with the noise.
            rxSymbols = (randn(nSC, nSym, nRx) + 1i * randn(nSC, nSym, nRx)) ...
                * sqrt(noiseVar / 2);
            % Rx symbols: add transmitted symbols.
            for iRx = 1:nRx
                for iTx = 1:nTx
                    rxSymbols(:, :, iRx) = rxSymbols(:, :, iRx) ...
                        + obj.channelTensor(:, :, iRx, iTx)  .* txSymbols(:, :, iTx);
                end
            end

            % Equalize Rx symbols.
            eqSymbols = nan(size(txSymbols));
            for iSC = 1:nSC
                for iSym = 1:nSym
                    chMatrix = squeeze(obj.channelTensor(iSC, iSym, :, :));
                    rxSyms = squeeze(rxSymbols(iSC, iSym, :));
                    eqSymbols(iSC, iSym, :) = equalize(rxSyms, ...
                        chMatrix, noiseVar, eqType);
                end
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

function eqSymbols = equalize(rxSymbols, chMatrix, noiseVar, eqType)
    chHch = chMatrix' * chMatrix;
    if strcmp(eqType, 'MMSE')
        M = (noiseVar * eye(size(chHch)) + chHch);
        eqSymbols = M \ (chMatrix' * rxSymbols);
    elseif strcmp(eqType, 'ZF')
        eqSymbols = chMatrix \ rxSymbols;
    else
        error('Unknown equalizer %s.', eqType);
    end
end

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
