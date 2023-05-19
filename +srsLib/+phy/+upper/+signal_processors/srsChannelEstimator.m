%srsChannelEstimator channel estimation.
%   [CHANNELESTRG, NOISEEST, RSRP, EPRE, TIMEALIGNMENT] = srsChannelEstimator(RECEIVEDRG, PILOTS, BETADMRS, HOP1, HOP2, CONFIG)
%   estimates the channel coefficients for the REs resulting from the provided
%   configuration (see below) from the observations in the resource grid RECEIVEDRG.
%   The transmission is assumed to be single-layer.
%
%   Inputs:
%   RECEIVEDRG - Observed signal samples organized in a resource grid
%   PILOTS     - Matrix of DM-RS pilots (each column represents the pilots carried
%                by a single OFDM symbol)
%   BETADMRS   - DM-RS-to-information linear amplitude gain
%   HOP1       - Configuration of the first intraSlot frequency hop (see below)
%   HOP2       - Configuration of the second intraSlot frequency hop (see below)
%   CONFIG     - General configuration (struct with fields DMRSREmask, pattern
%                of REs carrying DM-RS inside a DM-RS dedicated PRB,
%                nPilotsNoiseAvg, number of pilots used for noise averaging, and scs,
%                subcarrier spacing in hertz)
%
%   Each hop is configured by a struct with fields
%   DMRSsymbols       - OFDM symbols carrying DM-RS in the first hop (logical mask)
%   DMRSREmask        - REs carrying DM-RS in a dedicated PRB (logical mask)
%   PRBstart          - First PRB dedicated to DM-RS (0-based indexing)
%   nPRBs             - Number of PRBs dedicated to DM-RS
%   maskPRBs          - PRBs dedicated to DM-RS (logical mask)
%   startSymbol       - Index of the OFDM symbol (0-based) correspoding to the
%                       start of the hop
%   nAllocatedSymbols - Number of OFDM symbols allocated to the PUxCH transmission
%                       in the hop
%   CHsymbols         - OFDM symbols allocated to the PUxCH transmission in the
%                       hop (logical mask)
%
%   Outputs:
%   CHANNELESTRG - Estimated channel coefficients organized in a resource grid
%   NOISEEST     - Estiamted noise variance
%   RSRP         - Estimated reference-signal received power
%   EPRE         - Average receive-side energy per reference-signal resource
%                  element (including noise).

%   Copyright 2021-2023 Software Radio Systems Limited
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

function [channelEstRG, noiseEst, rsrp, epre, timeAlignment] = srsChannelEstimator(receivedRG, pilots, betaDMRS, hop1, hop2, config)
    channelEstRG = zeros(size(receivedRG));
    noiseEst = 0;
    rsrp = 0;
    epre = 0;
    timeAlignment = 0;

    nPilotSymbolsHop1 = sum(hop1.DMRSsymbols);

    scs = config.scs;

    processHop(hop1, pilots(:, 1:nPilotSymbolsHop1));

    if ~isempty(hop2.DMRSsymbols)
        processHop(hop2, pilots(:, (nPilotSymbolsHop1 + 1):end));
    end

    nDMRSsymbols = sum(config.DMRSSymbolMask);
    nPilots = hop1.nPRBs * sum(config.DMRSREmask) * nDMRSsymbols;

    rsrp = rsrp / nPilots;
    epre = epre / nPilots;

    noiseEst = noiseEst / (nPilots - hop1.nPRBs * sum(config.DMRSREmask) / config.nPilotsNoiseAvg);
    if (size(pilots, 2) < 3) || ~isempty(hop2.DMRSsymbols)
        noiseEst = epre * 10^(-3);
    end

    if ~isempty(hop2.DMRSsymbols)
        timeAlignment = timeAlignment / 2;
    end


    %     Nested functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function processHop(hop_, pilots_)
    %Processes the DM-RS corresponding to a single hop.

        % Create a mask for all subcarriers carrying DM-RS.
        maskPRBs_ = hop_.maskPRBs;
        maskREs_ = (kron(maskPRBs_, config.DMRSREmask) > 0);

        % Pick the REs corresponding to the pilots.
        receivedPilots_ = receivedRG(maskREs_, hop_.DMRSsymbols);

        % Compute receive side DM-RS EPRE.
        epre = epre + norm(receivedPilots_, 'fro')^2;

        % LSE-estimate the channel coefficients of the subcarriers carrying DM-RS.
        nDMRSsymbols_ = sum(hop_.DMRSsymbols);
        recXpilots_ = receivedPilots_ .* conj(pilots_);
        estimatedChannelP_ = sum(recXpilots_, 2) / betaDMRS / nDMRSsymbols_;
        % TODO: at this point, we should compute a metric for signal detection.
        % detectMetricNum = detectMetricNum + norm(recXpilots_, 'fro')^2;

        % Estimate time alignment.
        estChannelSC_ = zeros(length(maskREs_), 1);
        estChannelSC_(maskREs_) = estimatedChannelP_;
        fftSize_ = 4096;
        channelIRlp_ = ifft(estChannelSC_, fftSize_);
        halfCPLength_ = floor((144 / 2) * fftSize_ / 2048);
        [maxDelay_, iMaxDelay_] = max(channelIRlp_(1:halfCPLength_));
        [maxAdvance_, iMaxAdvance_] = max(channelIRlp_(end-halfCPLength_+1:end));
        if abs(maxDelay_) >= abs(maxAdvance_)
            iMax_ = iMaxDelay_ - 1;
        else
            iMax_ = -(halfCPLength_ - iMaxAdvance_ + 1);
        end
        timeAlignment = timeAlignment + iMax_ / fftSize_ / scs;

        % To estimate the noise, we assume the channel is constant over a small number
        % of adjacent subcarriers.
        estChannelRB_ = mean(reshape(estimatedChannelP_, config.nPilotsNoiseAvg, []), 1).';
        estChannelAvg_ = kron(estChannelRB_, ones(config.nPilotsNoiseAvg, 1));
        noiseEst = noiseEst + norm(receivedPilots_ - betaDMRS * pilots_ ...
            .* repmat(estChannelAvg_, 1, nDMRSsymbols_), 'fro')^2;
        rsrp = rsrp + betaDMRS^2 * norm(estimatedChannelP_)^2 * nDMRSsymbols_;

        % The other subcarriers are linearly interpolated.
        channelEstRG = fillChEst(channelEstRG, estimatedChannelP_, hop_);
    end
end % of function srsChannelEstimator

function channelOut = fillChEst(channelIn, estimated, hop)
%Linearly interpolates the missing subcarriers and organizes the estimates on
%   a resource grid.
    NRE = 12;
    channelOut = channelIn;
    estimatedAll = complex(nan(hop.nPRBs * NRE, 1));
    maskAll = repmat(hop.DMRSREmask, hop.nPRBs, 1);
    estimatedAll(maskAll) = estimated;
    filledIndices = find(maskAll);
    nFilledIndices = length(filledIndices);
    for i = 1:nFilledIndices-1
        start = filledIndices(i) + 1;
        stop = filledIndices(i+1) - 1;
        stride = stop - start + 1;
        span = estimatedAll(stop + 1) - estimatedAll(start - 1);
        estimatedAll(start:stop) = estimatedAll(start - 1) + span * (1:stride) / (stride + 1);
    end
    estimatedAll(filledIndices(end):end) = estimatedAll(filledIndices(end));
    estimatedAll(1:filledIndices(1)) = estimatedAll(filledIndices(1));

    occupiedSCs = (NRE * hop.PRBstart):(NRE * (hop.PRBstart + hop.nPRBs) - 1);
    occupiedSymbols = hop.startSymbol + (0:hop.nAllocatedSymbols-1);
    channelOut(1 + occupiedSCs, 1 + occupiedSymbols) = repmat(estimatedAll, 1, hop.nAllocatedSymbols);
end
