%srsChannelEstimator channel estimation.
%   [CHANNELESTRG, NOISEEST, RSRP, EPRE, TIMEALIGNMENT, CFO] = srsChannelEstimator(RECEIVEDRG, PILOTS, BETADMRS, HOP1, HOP2, CONFIG)
%   estimates the channel coefficients for the REs resulting from the provided
%   configuration (see below) from the observations in the resource grid RECEIVEDRG.
%   The transmission is assumed to be either single-layer or two-layer.
%
%   Inputs:
%   RECEIVEDRG - Observed signal samples organized in a resource grid
%   PILOTS     - Multidimensional array of DM-RS pilots (each column represents the pilots carried
%                by a single OFDM symbol, for each layer)
%   BETADMRS   - DM-RS-to-information linear amplitude gain
%   HOP1       - Configuration of the first intraSlot frequency hop (see below)
%   HOP2       - Configuration of the second intraSlot frequency hop (see below)
%   CONFIG     - General configuration (struct with fields scs, subcarrier spacing
%                in hertz, CyclicPrefixDurations, the duration of the CPs in milliseconds,
%                Smoothing, the smoothing strategy, and CFOCompensate, a boolean flag
%                to activate or not the CFO compensation).
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
%
%   Outputs:
%   CHANNELESTRG   - Estimated channel coefficients organized in a resource grid
%   NOISEEST       - Estiamted noise variance
%   RSRP           - Estimated reference-signal received power
%   EPRE           - Average receive-side energy per reference-signal resource
%                    element (including noise)
%   TIMEALIGNMENT  - Time alignment estimation (delay of the strongest tap)
%   CFO            - Carrier Frequency Offset

%   Copyright 2021-2024 Software Radio Systems Limited
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

function [channelEstRG, noiseEst, rsrp, epre, timeAlignment, cfo] = ...
    srsChannelEstimator(receivedRG, pilots, betaDMRS, hop1, hop2, config)

    % If pilots is a three-dimensional array, then the number of layers is 2.
    % Otherwise, single layer.
    nLayers = 1 + (numel(size(pilots)) == 3);

    cfoCompensate = true;
    if (isfield(config, 'CFOCompensate'))
        cfoCompensate = config.CFOCompensate;
    end

    channelEstRG = complex(zeros([size(receivedRG), nLayers]));
    noiseEst = 0;
    rsrp = 0;
    epre = 0;
    timeAlignment = 0;
    cfo = [];

    nPilotSymbolsHop1 = sum(hop1.DMRSsymbols);

    scs = config.scs;

    if isfield(config, 'Smoothing')
        smoothing = config.Smoothing;
    else
        smoothing = 'filter';
    end

    if (cfoCompensate)
        % Compute the start time of all OFDM symbols from the start of the slot, expressed in
        % units of OFDM symbol time.
        CyclicPrefixDurations = config.CyclicPrefixDurations * scs / 1000;
        symbolStartTime = cumsum([CyclicPrefixDurations(1) CyclicPrefixDurations(2:14) + 1]);
    end

    processHop(hop1, pilots(:, 1:nPilotSymbolsHop1, :), smoothing);

    allDMRSsymbols = hop1.DMRSsymbols;
    if ~isempty(hop2.DMRSsymbols)
        assert(~any(hop1.DMRSsymbols & hop2.DMRSsymbols), "Hops should not overlap.");
        allDMRSsymbols = allDMRSsymbols | hop2.DMRSsymbols;

        assert(all(hop1.DMRSREmask == hop2.DMRSREmask, 'all'), ...
            "The DM-RS mask should be the same for the two hops.");

        processHop(hop2, pilots(:, (nPilotSymbolsHop1 + 1):end, :), smoothing);
    end

    nDMRSsymbols = sum(allDMRSsymbols);
    nPilots = hop1.nPRBs * sum(hop1.DMRSREmask) * nDMRSsymbols;

    rsrp = rsrp / nPilots / nLayers;
    epre = epre / nPilots;

    noiseEst = noiseEst / (nPilots - 1);

    if ~isempty(hop2.DMRSsymbols)
        timeAlignment = timeAlignment / 2;
    end

    if (cfoCompensate && ~isempty(cfo))
        PHcorrection = 2 * pi * symbolStartTime * cfo;
        % Apply the phase shifts caused by the CFO to the channel estimates, so they
        % can be compensated by the channel equalizer.
        channelEstRG = channelEstRG .* reshape(exp(1j * PHcorrection), 1, []);
    end

    % Convert CFO from normalized units to hertz.
    cfo = cfo * scs;

    %     Nested functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function processHop(hop_, pilots_, smoothing_)
    %Processes the DM-RS corresponding to a single hop.

        % Create a mask for all subcarriers carrying DM-RS.
        maskPRBs_ = hop_.maskPRBs;
        DMRSREmask_ = hop_.DMRSREmask;
        maskREs_ = (kron(maskPRBs_, DMRSREmask_) > 0);

        % Pick the REs corresponding to the pilots.
        receivedPilots_ = receivedRG(maskREs_, hop_.DMRSsymbols);

        % Compute receive side DM-RS EPRE.
        epre = epre + norm(receivedPilots_, 'fro')^2;

        % LSE-estimate the channel coefficients of the subcarriers carrying DM-RS.
        nDMRSsymbols_ = sum(hop_.DMRSsymbols);
        recXpilots_ = receivedPilots_ .* conj(pilots_);

        [recXpilotsNOCFO_, cfoHop_] = compensateCFO(recXpilots_, ...
            hop_.DMRSsymbols, scs / 1000, config.CyclicPrefixDurations, cfoCompensate);
        if ~isempty(cfoHop_)
            if ~isempty(cfo)
                cfo = (cfo + cfoHop_) / 2;
            else
                cfo = cfoHop_;
            end
        end

        estimatedChannelP_ = squeeze(sum(recXpilotsNOCFO_, 2) / betaDMRS / nDMRSsymbols_);
        % TODO: at this point, we should compute a metric for signal detection.
        % detectMetricNum = detectMetricNum + norm(recXpilots_, 'fro')^2;

        nLayers_ = 1 + (numel(size(pilots_)) == 3);
        if nLayers_ == 2
            % For two layers, we assume DM-RS Type 1, Mapping Type A, ports {0, 1} - that is,
            % pilots for the two layers are transmitted on the same REs. Also, the pilots for
            % layer 2 are the same as those of layer 1, but for a sign flip every other pilot.
            % The estimator assumes the channel constant over two consecutive DM-RS REs, and
            % the contribution of the "other" layer can be removed by averaging after
            % multiplication by the conjugate of the DM-RS sequences.
            estimatedChannelP_(1:2:end, :) = (estimatedChannelP_(1:2:end, :) + estimatedChannelP_(2:2:end, :)) / 2;
            estimatedChannelP_(2:2:end, :) = estimatedChannelP_(1:2:end, :);
        end

        switch smoothing_
            case 'mean'
                estimatedChannelP_ = ones(size(estimatedChannelP_)) .* mean(estimatedChannelP_);
            case 'filter'
                % Denoising with RC filter.
                rcFilter_ = getRCfilter(12/sum(DMRSREmask_), min(3, sum(maskPRBs_)));

                if sum(maskPRBs_) > 1
                    nPils_ = min(12, floor(length(rcFilter_) / 2));
                else
                    nPils_ = sum(DMRSREmask_);
                end

                for iLayer_ = 1:nLayers_
                    % Create some virtual pilots on both sides of the allocated band.
                    vPilsBegin_ = createVirtualPilots(estimatedChannelP_(1:nPils_, iLayer_), nPils_);
                    vPilsEnd_ = createVirtualPilots(estimatedChannelP_(end:-1:end-nPils_+1, iLayer_), nPils_);

                    tmp_ = conv([vPilsBegin_; estimatedChannelP_(:, iLayer_); flipud(vPilsEnd_)], rcFilter_, "same");
                    estimatedChannelP_(:, iLayer_) = tmp_(nPils_+1:end-nPils_);
                end
            case 'none'
                % estimatedChannelP_ is passed forward.
            otherwise
                error('Unknown smoothing strategy %s.', smoothing_);
        end

        % Estimate time alignment.
        estChannelSC_ = complex(zeros(length(maskREs_), nLayers_));
        estChannelSC_(maskREs_, :) = estimatedChannelP_;
        fftSize_ = 4096;
        channelIRlp_ = sum(abs(ifft(estChannelSC_, fftSize_)).^2, 2);
        halfCPLength_ = floor((144 / 2) * fftSize_ / 2048);
        [maxDelay_, iMaxDelay_] = max(channelIRlp_(1:halfCPLength_));
        [maxAdvance_, iMaxAdvance_] = max(channelIRlp_(end-halfCPLength_+1:end));
        if maxDelay_ >= maxAdvance_
            iMax_ = iMaxDelay_ - 1;
        else
            iMax_ = -(halfCPLength_ - iMaxAdvance_ + 1);
        end
        timeAlignment = timeAlignment + iMax_ / fftSize_ / scs;

        estimatedRx_ = complex(zeros(size(receivedPilots_)));
        if (cfoCompensate && ~isempty(cfoHop_))
            PHcorrection = 2 * pi * symbolStartTime * cfoHop_;
            for iLayer_ = 1:nLayers_
                estimatedRx_ = estimatedRx_ + betaDMRS * pilots_(:, :, iLayer_) ...
                .* (estimatedChannelP_(:, iLayer_) * reshape(exp(1j * PHcorrection(hop_.DMRSsymbols)), 1, []));
            end
        else
            for iLayer_ = 1:nLayers_
                estimatedRx_ = estimatedRx_ + betaDMRS * pilots_(:, :, iLayer_) ...
                .* repmat(estimatedChannelP_(:, iLayer_), 1, nDMRSsymbols_);
            end
        end
        noiseEst = noiseEst + norm(receivedPilots_ - estimatedRx_,'fro')^2;
        rsrp = rsrp + betaDMRS^2 * norm(estimatedChannelP_, 'fro')^2 * nDMRSsymbols_;

        % The other subcarriers are linearly interpolated.
        channelEstRG = fillChEst(channelEstRG, estimatedChannelP_, hop_);
    end
end % of function srsChannelEstimator

function channelOut = fillChEst(channelIn, estimated, hop)
%Linearly interpolates the missing subcarriers and organizes the estimates on
%   a resource grid.
    NRE = 12;
    nLayers = 1 + (numel(size(channelIn)) == 3);
    channelOut = channelIn;
    estimatedAll = complex(nan(hop.nPRBs * NRE, nLayers));
    maskAll = repmat(hop.DMRSREmask, hop.nPRBs, 1);
    estimatedAll(maskAll, :) = estimated;
    filledIndices = find(maskAll);
    nFilledIndices = length(filledIndices);
    for i = 1:nFilledIndices-1
        start = filledIndices(i) + 1;
        stop = filledIndices(i+1) - 1;
        stride = stop - start + 1;
        span = estimatedAll(stop + 1, :) - estimatedAll(start - 1, :);
        estimatedAll(start:stop, :) = estimatedAll(start - 1, :) + span * (1:stride) / (stride + 1);
    end

    occupiedSCs = (NRE * hop.PRBstart):(NRE * (hop.PRBstart + hop.nPRBs) - 1);
    occupiedSymbols = hop.startSymbol + (0:hop.nAllocatedSymbols-1);

    for iLayer = 1:nLayers
        estimatedAll(filledIndices(end):end, iLayer) = estimatedAll(filledIndices(end), iLayer);
        estimatedAll(1:filledIndices(1), iLayer) = estimatedAll(filledIndices(1), iLayer);
        channelOut(1 + occupiedSCs, 1 + occupiedSymbols, iLayer) = repmat(estimatedAll(:, iLayer), 1, hop.nAllocatedSymbols);
    end
end

function [rcFilter, correction] = getRCfilter(stride, nRBs)
%Creates a raised-cosine filter with a band of 1/10 of the symbol time (the filter
%   is applied in the frequency domain). The filter spans nRBs RBs. The output
%   correction contains the correction factors for the tail estimations.
    bwFactor = 10; % must be even
    rollOff = 0.2;
    ff = rcosdesign(rollOff, nRBs, bwFactor, 'normal')';
    l = length(ff);
    n = (-floor(l/2/stride)*stride:stride:floor(l/2/stride)*stride) + ceil(l/2);
    rcFilter = ff(n);
    rcFilter = rcFilter / sum(rcFilter);
    tmp = cumsum(rcFilter);
    correction = 1./tmp(ceil(length(tmp)/2):end-1);
end

function virtualPilots = createVirtualPilots(inPilots, nVirtuals)
%Creates a nVirtual virtual pilots by extrapolation from inPilots. Extrapolation
%   is done linearly in both modulus and phase.
    nPilots = length(inPilots);
    x = 0:nPilots-1;
    mx = mean(x);
    normx = norm(x)^2;
    y = abs(inPilots);
    my = mean(y);
    a = (x * y - nPilots * mx * my) / (normx - nPilots * mx^2);
    b = my - a * mx;

    virtualPilots = a * (-nVirtuals:-1)' + b;

    y = angle(inPilots);
    y = unwrap(y);
    my = mean(y);
    a = (x * y - nPilots * mx * my) / (normx - nPilots * mx^2);
    b = my - a * mx;

    virtualPilots = virtualPilots .* exp(1j * (a * (-nVirtuals:-1)' + b));
end

% If cfoCompensate == false, only estimates the CFO.
function [recXpilotsOut, cfoOut] = compensateCFO(recXpilots, DMRSsymbols, ...
    SCS, CyclicPrefixDurations, cfoCompensate)

    if sum(DMRSsymbols) < 2
        recXpilotsOut = recXpilots;
        cfoOut = [];
        return
    end

    nLayers = 1 + (numel(size(recXpilots)) == 3);

    CPDs = CyclicPrefixDurations * SCS;

    dmrsIx = find(DMRSsymbols);
    nSyms = dmrsIx(2) - dmrsIx(1);
    cfoOut = complex(0);
    for iLayer = 1:nLayers
        cfoOut = cfoOut + recXpilots(:, 1, iLayer)' * recXpilots(:, 2, iLayer);
    end
    nSamples = nSyms + sum(CPDs((dmrsIx(1) + 1):dmrsIx(2)));
    cfoOut = angle(cfoOut) / (2 * pi * nSamples);

    if cfoCompensate
        symbolStartTime = cumsum([CPDs(1) CPDs(2:14) + 1]);
        PHcorrection = 2 * pi * symbolStartTime * cfoOut;
        recXpilotsOut = recXpilots .* reshape(exp(-1j * PHcorrection(dmrsIx)), 1, []);
    else
        recXpilotsOut = recXpilots;
    end
end
