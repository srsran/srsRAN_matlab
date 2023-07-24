%srsPRACHdetector Detects the 5G NR PRACH preamble in a PRACH occasion.
%   [INDICES, OFFSETS, SINR, RSSI] = srsPRACHdetector(CARRIER, PRACH, GRID, IGNORECFO)
%   detects the 5G NR PRACH preambles in GRID. GRID is a matrix (one column per
%   RX antenna port) with the baseband symbols corresponding to one PRACH occasion,
%   that is it may contain a number of copies of the preamble depending on the
%   format. CARRIER is an nrCarrierConfig object with the carrier configuration.
%   PRACH is an nrPRACHConfig object with the PRACH configuration (the
%   PreambleIndex field is ignored). The boolean flag IGNORECFO tells the detector
%   whether to assume that the signal is affected by CFO (false) or not (true).
%
%   The function returns INDICES and OFFSETS, that is a 64-entry boolean mask of
%   the detected Preamble indices and the corresponding offsets in microseconds,
%   respectively. It also returns an estimation of the SINR (in dB, basically
%   the detection metric) and of the signal RSSI (in dB).

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

function [indices, offsets, sinr, rssi] = srsPRACHdetector(carrier, prachConf, grid, ignoreCFO)
    assert(prachConf.RestrictedSet == "UnrestrictedSet", "srsran_matlab:srsPRACHdetector",...
        "Only unrestricted sets are supported.");

    % Working copy of the PRACH configuration.
    prach = prachConf;
    % Reset the preamble index, since it is unkown.
    prach.PreambleIndex = 0;

    % Get the numerology index.
    mu = log2(carrier.SubcarrierSpacing / 15);

    % Get useful information about the PRACH preambles.
    info = getWindowInfo(prach, mu);

    LRA = prach.LRA;
    halfLRA = (LRA - 1) / 2;

    % Rearrange signal to have a single replica per column. If "ignoreCFO", the
    % replicas from the same antennas are combined together.
    preambles = preprocess(grid, LRA, ignoreCFO);

    nAntennas = size(grid, 2);
    nReplicas = size(preambles, 2);

    % Set the margin around the detection window (useful for computing reference
    % power).
    % Detection threshold. The detector is inspired by the GLRT test, but it's
    % not exactly that one - threshold must be tuned by simulation.
    [winMargin, threshold] = getThreshold(prach, nAntennas, ignoreCFO);

    Nfft = fftsize(prach.Format);

    % Initialize output.
    indices = false(64, 1);
    offsets = nan(64, 1);
    sinr = nan(64, 1);

    rssi = 10 * log10(mean(abs(grid).^2, 'all') / LRA);

    nSequences = info.nSequences;
    remainingShifts = 64;
    for iSequence = 1:nSequences
        % Preamble index corresponding to the current sequence index.
        prach.PreambleIndex = (iSequence - 1) * info.nShifts;

        % Get the root sequence: note that MATLAB can return multiple copies
        % depending on the format.
        rootLong = nrPRACH(carrier, prach);
        root = rootLong(1:LRA);

        % Multiply the preamble by the complex conjugate of the root sequence and
        % take the ifft - same as correlation.
        noRoot = conj(root) .* preambles / LRA;
        % We want a symmetric FFT.
        noRootLarge = [noRoot(halfLRA + 1:end, :); zeros(Nfft - LRA, nReplicas); noRoot(1:halfLRA, :)];

        noRootTimeSimple = ifft(noRootLarge) * sqrt(Nfft);
        modSquare = abs(noRootTimeSimple).^2;

        noRootTimeSinc = noRootTimeSimple * sqrt(Nfft / LRA);

        nWindows = min(info.nShifts, remainingShifts);
        remainingShifts = remainingShifts - info.nShifts;
        assert((remainingShifts > 0) || (iSequence == nSequences));

        for iWindow = 1:nWindows
            % Scale the detection window according to the FFT size.
            winWidth = floor(info.WinWidths(iWindow) * Nfft / LRA);
            winStart = mod(Nfft - floor(info.WinStart(iWindow) * Nfft / LRA), Nfft);

            ix = (winStart - winMargin):(winStart + winWidth + winMargin - 1);

            winScalar = abs(noRootTimeSinc(winStart + (1:winWidth), :)).^2;

            % GLRT inspired detection test.
            reference = sum(modSquare(mod(ix, Nfft) + 1, :), 1);

            % The absolute value at the denominator shouldn't be necessary.
            % Nevertheless, because of the approximations, it may happen that
            % the difference at the denominator takes very small negative values.
            metricGlobal = sum(winScalar, 2) ./ abs(sum(reference - winScalar, 2));

            if false
                figure(1) %#ok<UNRCH>
                plot(winStart + (0:winWidth-1), winScalar);
                hold on
                plot(ix, abs(noRootTimeSimple(mod(ix, Nfft) +1, :)));
                hold off
                title(sprintf('%d', (iSequence-1) * info.nShifts + iWindow-1));

                metric = winScalar ./ abs(reference - winScalar);
                figure(2)
                hold off
                plot(winStart + (0:winWidth-1), [metric metricGlobal]);
                hold on
                plot(winStart + (0:winWidth-1), threshold*ones(winWidth,1), '-.');
                title(sprintf('%d', (iSequence-1) * info.nShifts + iWindow-1));
                pause(0.5)
            end

            % We don't want peaks at the very end of the window because they
            % are most probably side effects of a peak at the beginning of
            % the adjacent window. We discard peaks that fall in the last
            % 1/5 of the detection window.
            [m, delay] = max(metricGlobal);
            if (m > threshold) && (delay < length(metricGlobal) * 0.8)
                pos = (iSequence - 1) * nWindows + iWindow;
                indices(pos) = true;
                d = delay + winStart - 1;
                offsets(pos) = (d / Nfft - mod(LRA - info.WinStart(iWindow), LRA) / LRA) / prach.SubcarrierSpacing * 1000;
                sinr(pos) = 10 * log10(m);
            end
        end
    end

end

function ncs = getNCS(prach)
% Returns the NCS for the current prach configuration.
    switch prach.Format
        case {'0','1','2'}
            ncsTable = nrPRACHConfig.Tables.NCSFormat012;
            colName = prach.RestrictedSet;
        case '3'
            ncsTable = nrPRACHConfig.Tables.NCSFormat3;
            colName = prach.RestrictedSet;
        otherwise
            ncsTable = nrPRACHConfig.Tables.NCSFormatABC;
            colName = string(['LRA_' num2str(prach.LRA)]);
    end

    ncsRow = ncsTable(ncsTable{:, "ZeroCorrelationZone"} == prach.ZeroCorrelationZone, :);
    ncs = ncsRow.(colName);

    assert(isfinite(ncs), "srsran_matlab:srsPRACHdetector", ...
        "Invalid PRACH format, restricted set, ZCZ combination.");
end

function Ncp = getCP(prach)
% Returns the length of the cyclic prefix and of the preamble for the configured
% prach (an nrPRACHConfig object).
    switch prach.Format
        case {'0','1','2','3'}
            table = nrPRACHConfig.Tables.LongPreambleFormats;
        otherwise
            table = nrPRACHConfig.Tables.ShortPreambleFormats;
    end

    row = table(strcmp(table{:, "Format"}, prach.Format), :);
    Ncp = row.('N_CP');
    % Nu = row.('N_u');
end

function info = getWindowInfo(prach, mu)
% Returns a struct of useful information about the prach (an nrPRACHConfig object),
% assuming that the underlying PUSCH numerology is mu.

    % Only works for unrestricted sets.
    NCS = getNCS(prach);
    % Get the number of preambles using the same root sequence (i.e., the number
    % of cyclic shifts) and the total number of root sequences needed.
    if NCS == 0
        nShifts = 1;
        nSequences = 64;
    else
        nShifts = floor(prach.LRA / NCS);
        nSequences = ceil(64 / nShifts);
    end

    muLoc = mu;
    if prach.LRA == 839
        muLoc = 0;
    end

    % Get the length of the cyclic prefix, as given in the standard.
    CP = getCP(prach);

    % CP is in units of kappa * 2^(-muLoc), convert it to ms.
    CPms = CP * 64 / (2^muLoc * 480 * 4096);

    % Express the CP as a number of samples at sampling frequency equal to LRA * SCS.
    CPprach = floor(CPms * prach.LRA * prach.SubcarrierSpacing);

    % Each preamble correspond to a detection window whose width is the miniumum
    % between the CP length and the NCS.
    winWidth = min(NCS, CPprach);
    if NCS == 0
        winWidth = CPprach;
    end

    info.NCS = NCS;
    info.WinWidths = ones(nShifts, 1) * winWidth;
    info.WinStart = (0:(nShifts - 1)) * NCS;
    info.nSequences = nSequences;
    info.nShifts = nShifts;
end

function preambles = preprocess(grid, LRA, ignoreCFO)
% If the grid contains multiple replicas of the preamble (that is, for all formats
% but Format 0 and Format C0), reorganize samples so that we have one replica per
% column. If "ignoreCFO" replicas from the same antenna are averaged together.

    assert(mod(size(grid, 1), LRA) == 0, 'srsran_matlab:srsPRACHdetector', ...
        'The number of symbols does not match with the preamble length.');

    nAntennas = size(grid, 2);
    if ignoreCFO
        preambles = squeeze(mean(reshape(grid, LRA, [], nAntennas), 2));
        return;
    end

    preambles = reshape(grid, LRA, []);
end

function x = fftsize(format)
% FFT size used by the detector - it defines the offset granularity depending on
% the format.
    switch format
        case {'0', '1', '2', '3'}
            x = 1024;
        case {'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2'}
            x = 256;
        otherwise
            error('srsran_matlab:srsPRACHdetector', ...
                'Currently, Format %s is not supported.', format);
    end
end

% Returns the window margin and the detection threshold for the given PRACH configuration,
% number of antennas, and CFO flag.
function [winMargin, threshold] = getThreshold(prach, nAntennas, ignoreCFO)
    % assert(nAntennas <= 2, 'srsran_matlab:srsPRACHdetector', 'Only 2 antennas supported at the moment.');

    Configurations = [ ...
        "Ant1_F0_NCS0_noCFO1", ...
        "Ant1_F0_NCS13_noCFO1", ...
        "Ant1_FB4_NCS0_noCFO1", ...
        "Ant1_FB4_NCS46_noCFO1", ...
        "Ant2_F0_NCS0_noCFO1", ...
        "Ant2_F0_NCS13_noCFO1", ...
        "Ant2_FB4_NCS0_noCFO1", ...
        "Ant2_FB4_NCS46_noCFO1", ...
        "Ant4_F0_NCS0_noCFO1", ...
        "Ant4_F0_NCS13_noCFO1", ...
        "Ant4_FB4_NCS0_noCFO1", ...
        "Ant4_FB4_NCS46_noCFO1", ...
        ];
    ThresholdsMargins = { ...
        [0.15, 5],  ... % Ant1_F0_NCS0_noCFO1
        [1, 5],     ... % Ant1_F0_NCS13_noCFO1
        [0.39, 12], ... % Ant1_FB4_NCS0_noCFO1
        [0.39, 12], ... % Ant1_FB4_NCS46_noCFO1
        [0.09, 5],  ... % Ant2_F0_NCS0_noCFO1
        [0.45, 5],  ... % Ant2_F0_NCS13_noCFO1
        [0.14, 12], ... % Ant2_FB4_NCS0_noCFO1
        [0.18, 12], ... % Ant2_FB4_NCS46_noCFO1
        [0.06, 5],  ... % Ant4_F0_NCS0_noCFO1
        [0.32, 5],  ... % Ant4_F0_NCS13_noCFO1
        [0.09, 12], ... % Ant4_FB4_NCS0_noCFO1
        [0.11, 12], ... % Ant4_FB4_NCS46_noCFO1
        };
     d = dictionary(Configurations, ThresholdsMargins);

     NCS = getNCS(prach);
     confString = sprintf("Ant%d_F%s_NCS%d_noCFO%d", nAntennas, prach.Format, NCS, ignoreCFO);

     try
         tt = cell2mat(d(confString));
         winMargin = tt(2);
         threshold = tt(1);
     catch
         warning('srsran_matlab:srsPRACHdetector', ...
             'Using a non-calibrated configuration with a suboptimal detection threshold.');
         if ismember(prach.Format, {'0', '1', '2', '3'})
             winMargin = 5;
             threshold = 0.1;
         else
             winMargin = 12;
             threshold = 0.3;
         end
     end
end
