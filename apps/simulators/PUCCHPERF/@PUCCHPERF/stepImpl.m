%stepImpl System object step method implementation.

%   Copyright 2021-2025 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

function stepImpl(obj, SNRIn, nFrames)
    arguments
        obj (1, 1) PUCCHPERF
        %SNR range in dB.
        SNRIn double {mustBeReal, mustBeFinite, mustBeVector}
        %Number of 10-ms frames.
        nFrames (1, 1) double {mustBeInteger, mustBePositive} = 10
    end

    % Ensure SNRIn has no repetitions and is a row vector.
    SNRIn = unique(SNRIn);
    SNRIn = SNRIn(:).';

    % Get the maximum number of delayed samples by a channel multipath
    % component. This is calculated from the channel path with the largest
    % delay and the implementation delay of the channel filter. This is
    % required later to flush the channel filter to obtain the received signal.
    chInfo = info(obj.Channel);
    maxChDelay = ceil(max(chInfo.PathDelays*obj.Channel.SampleRate)) + chInfo.ChannelFilterDelay;

    % Take copies of channel-level parameters to simplify subsequent parameter referencing.
    carrier = obj.Carrier;
    pucch = obj.PUCCH;
    implementationType = obj.ImplementationType;
    nTxAnts = obj.NTxAnts;
    nRxAnts = obj.NRxAnts;
    if (obj.PUCCHFormat == 0)
        ouci = [obj.NumACKBits obj.NumSRBits];
    else
        ouci = obj.NumACKBits + obj.NumSRBits + obj.NumCSI1Bits + obj.NumCSI2Bits;
    end
    nFFT = obj.Nfft;
    symbolsPerSlot = obj.Carrier.SymbolsPerSlot;
    slotsPerFrame = obj.Carrier.SlotsPerFrame;
    perfectChannelEstimator = obj.PerfectChannelEstimator;
    displaySimulationInformation = obj.DisplaySimulationInformation;
    isDetectTest = obj.isDetectionTest;

    useMATLABpucch = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
    useSRSpucch = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

    if useSRSpucch
        processPUCCHsrs = srsMEX.phy.srsPUCCHProcessor;
    end

    quickSim = obj.QuickSimulation;

    nSNRIn = numel(SNRIn);
    totalBlocks = zeros(nSNRIn, 1);
    stats = obj.FormatDetails.setupTmpStats(nSNRIn);


    for snrIdx = 1:numel(SNRIn)

        % Reset the random number generator so that each SNR point will
        % experience the same noise realization.
        rng('default')
        reset(obj.Channel)

        % Initialize variables for this SNR point (required when using
        % Parallel Computing Toolbox).
        pathFilters = [];

        % Get operating SNR value.
        SNRdB = SNRIn(snrIdx);
        fprintf(['\nSimulating transmission scheme MIMO (%dx%d) and SCS=%dkHz with ', ...
                 '%s channel at %gdB SNR for %d 10ms frame(s)\n'], ...
            nTxAnts, nRxAnts, carrier.SubcarrierSpacing, ...
            obj.DelayProfile, SNRdB, nFrames);


        % Get total number of slots in the simulation period.
        NSlots = nFrames*slotsPerFrame;

        % Set timing offset, which is updated in every slot for perfect
        % synchronization and when correlation is strong for practical
        % synchronization.
        offset = 0;

        for nslot = 0:NSlots-1

            % Update carrier slot number to account for new slot transmission.
            carrier.NSlot = nslot;

            % Get PUCCH resources.
            [pucchIndices, pucchIndicesInfo] = nrPUCCHIndices(carrier, pucch);
            dmrsIndices = nrPUCCHDMRSIndices(carrier, pucch);
            dmrsSymbols = nrPUCCHDMRS(carrier, pucch);

            % Create random UCI bits.
            if isscalar(ouci)
                uci = randi([0 1], ouci, 1);
            else
                uci = cell(2, 1);
                uci{1} = randi([0 1], ouci(1), 1);
                if ouci(1) > 0
                    uci{2} = randi([0 1], ouci(2), 1);
                else
                    % If there are no ACK bits, the PUCCH is transmitted only if
                    % the SR bit is 1. Since the no transmission case is covered
                    % by the 'False Alarm' test, here we set the bit to 1.
                    uci{2} = 1;
                end
            end

            [codedUCI, stats] = obj.FormatDetails.UCIEncode(uci, ouci, pucchIndicesInfo.G, stats, snrIdx);

            % Perform PUCCH modulation.
            pucchSymbols = nrPUCCH(carrier, pucch, codedUCI);

            % Create resource grid associated with PUCCH transmission antennas.
            pucchGrid = nrResourceGrid(carrier, nTxAnts);

            % Perform implementation-specific PUCCH MIMO precoding and mapping.
            F = eye(1, nTxAnts);
            [~, pucchAntIndices] = nrExtractResources(pucchIndices, pucchGrid);
            pucchGrid(pucchAntIndices) = pucchSymbols*F;

            % Perform implementation-specific PUCCH DM-RS MIMO precoding and mapping.
            [~, dmrsAntIndices] = nrExtractResources(dmrsIndices, pucchGrid);
            pucchGrid(dmrsAntIndices) = dmrsSymbols*F;

            % Perform OFDM modulation.
            txWaveform = nrOFDMModulate(carrier, pucchGrid);

            % Pass data through the channel model. Append zeros at the end of
            % the transmitted waveform to flush the channel content. These
            % zeros take into account any delay introduced in the channel. This
            % delay is a combination of the multipath delay and implementation
            % delay. This value can change depending on the sampling rate,
            % delay profile, and delay spread.
            txWaveformChDelay = [txWaveform; zeros(maxChDelay, size(txWaveform, 2))];
            [rxWaveform, pathGains, sampleTimes] = obj.Channel(txWaveformChDelay);

            % Add AWGN to the received time domain waveform. Normalize the
            % noise power by the size of the inverse fast Fourier transform
            % (IFFT) used in OFDM modulation, because the OFDM modulator
            % applies this normalization to the transmitted waveform. Also,
            % normalize the noise power by the number of receive antennas,
            % because the default behavior of the channel model is to apply
            % this normalization to the received waveform.
            SNR = 10^(SNRdB / 20);
            N0 = 1 / (sqrt(2.0 * nRxAnts * nFFT) * SNR);
            noise = N0 * complex(randn(size(rxWaveform)), randn(size(rxWaveform)));

            if isDetectTest
                rxWaveform = rxWaveform + noise;
            else
                rxWaveform = noise;
            end

            if ((obj.PUCCHFormat ~= 0) && perfectChannelEstimator)
                % Perfect synchronization. Use information provided by the
                % channel to find the strongest multipath component.
                pathFilters = getPathFilters(obj.Channel);
                [offset, ~] = nrPerfectTimingEstimate(pathGains, pathFilters);
                rxWaveform = rxWaveform(1+offset:end, :);
            end

            % Perform OFDM demodulation on the received data to recreate the
            % resource grid. Include zero padding in the event that practical
            % synchronization results in an incomplete slot being demodulated.
            rxGrid = nrOFDMDemodulate(carrier, rxWaveform);
            [K, L, R] = size(rxGrid);
            if (L < symbolsPerSlot)
                rxGrid = cat(2, rxGrid, zeros(K, symbolsPerSlot-L, R));
            end

            if useMATLABpucch
                if (obj.PUCCHFormat == 0)
                    % Get PUCCH REs from received grid and estimated channel grid.
                    pucchRx = nrExtractResources(pucchIndices, rxGrid);

                    % Decode PUCCH symbols. uciRx are hard bits for PUCCH F1 and soft bits for PUCCH F2.
                    uciRx = nrPUCCHDecode(carrier, pucch, ouci, pucchRx);
                else
                    % Perform channel estimation.
                    if perfectChannelEstimator
                        % For perfect channel estimation, use the value of the path
                        % gains provided by the channel.
                        estChannelGrid = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);

                        % Get the perfect noise estimate (from the noise realization).
                        noiseGrid = nrOFDMDemodulate(carrier, noise(1+offset:end,:));
                        noiseEst = var(noiseGrid(:));

                        % Apply MIMO deprecoding to estChannelGrid to give an
                        % estimate per transmission layer.
                        K = size(estChannelGrid, 1);
                        estChannelGrid = reshape(estChannelGrid, K*symbolsPerSlot*nRxAnts, nTxAnts);
                        estChannelGrid = estChannelGrid*F.';
                        estChannelGrid = reshape(estChannelGrid, K, symbolsPerSlot, nRxAnts, []);
                    else
                        % For practical channel estimation, use PUCCH DM-RS.
                        [estChannelGrid, noiseEst] = nrChannelEstimate(carrier, rxGrid, dmrsIndices, dmrsSymbols);
                    end

                    % Get PUCCH REs from received grid and estimated channel grid.
                    [pucchRx, pucchHest] = nrExtractResources(pucchIndices, rxGrid, estChannelGrid);

                    % Perform equalization.
                    pucchEq = nrEqualizeMMSE(pucchRx, pucchHest, noiseEst);

                    % Decode PUCCH symbols. uciRx are hard bits for PUCCH F0 and F1 and soft bits for PUCCH F2.
                    uciRx = nrPUCCHDecode(carrier, pucch, ouci, pucchEq, noiseEst);

                end % if (obj.PUCCHFormat == 0)

                stats = obj.FormatDetails.updateStatsMATLAB(stats, uci, uciRx, ouci, isDetectTest, snrIdx);
            end % if useMATLABpucch

            if useSRSpucch
                msg = processPUCCHsrs(carrier, pucch, rxGrid, ...
                NumHARQAck=obj.NumACKBits, ...
                NumSR=obj.NumSRBits, ...
                NumCSIPart1=obj.NumCSI1Bits, ...
                NumCSIPart2=obj.NumCSI2Bits);

                stats = obj.FormatDetails.updateStatsSRS(stats, uci, msg, isDetectTest, snrIdx);
            end % if useSRSpucch

            totalBlocks(snrIdx) = totalBlocks(snrIdx) + 1;

            % To speed the simulation up, we stop after 100 missed transport blocks.
            if quickSim && obj.FormatDetails.isSimOver(stats, snrIdx, obj.ImplementationType)
                break;
            end
        end

        % Display results dynamically.
        usedFrames = round((nslot + 1) / carrier.SlotsPerFrame);
        if displaySimulationInformation == 1
            if useMATLABpucch
                obj.FormatDetails.printMessagesMATLAB(stats, usedFrames, totalBlocks, SNRIn, isDetectTest, snrIdx);
            end
            if useSRSpucch
                obj.FormatDetails.printMessagesSRS(stats, usedFrames, totalBlocks, SNRIn, isDetectTest, snrIdx);
            end
        end % of if displaySimulationInformation == 1
    end % of for snrIdx = 1:numel(snrIn)

    % Export results.
    obj.FormatDetails.updateCounters(stats, SNRIn, totalBlocks);

    fprintf('\n');

end % of function stepImpl(obj, SNRIn, nFrames)

