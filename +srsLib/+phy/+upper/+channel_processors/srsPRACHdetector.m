%srsPRACHdetector Detects the 5G NR PRACH preamble in a PRACH occasion.
%   [INDICES, OFFSETS, DETECTINFO] = srsPRACHdetector(CARRIER, PRACH, GRID)
%   detects the 5G NR PRACH preambles in GRID. GRID is a matrix (one column per
%   RX antenna port) with the baseband symbols corresponding to one PRACH occasion,
%   that is it may contain a number of copies of the preamble depending on the
%   format. CARRIER is an nrCarrierConfig object with the carrier configuration.
%   PRACH is an nrPRACHConfig object with the PRACH configuration (the
%   PreambleIndex field is ignored).
%
%   The function returns INDICES and OFFSETS, that is a 64-entry boolean mask of
%   the detected Preamble indices and the corresponding offsets in microseconds,
%   respectively.
%   DETECTINFO is a structure with extra information inferred by the detector. It
%   contains the following fields.
%   CFO   - The estimated carrier frequency offset in hertz.

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

function [indices, offsets, detectInfo] = srsPRACHdetector(carrier, prachConf, grid)
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
    remainingShifts = 64;

    LRA = prach.LRA;
    halfLRA = (LRA - 1) / 2;

    % Estimate and compensate the CFO, and, for each antenna, combine all the
    % replicas. "preamble" thus contain only one preamble per antenna.
    [preamble, cfo] = preprocess(grid, LRA);
    detectInfo = struct();
    detectInfo.CFO = cfo / 2 / pi * prach.SubcarrierSpacing * 1000;

    nAntennas = size(preamble, 2);

    %[sincEx, M] = getsinc(LRA);
    % Set the margin around the detection window (useful for computing reference
    % power).
    % Detection threshold. The detector is inspired by the GLRT test, but it's
    % not exactly that one - threshold must be tuned by simulation.
    if LRA == 839
        marg = 5;
        threshold = 7;
    else
        marg = 12;
        threshold = 13;
    end
    Nfft = fftsize();

    % Initialize output.
    indices = false(64, 1);
    offsets = nan(64, 1);

    nSequences = info.nSequences;
    for iSequence = 1:nSequences
        % Get the root sequence: note that MATLAB can return multiple copies
        % depending on the format.
        rootLong = nrPRACH(carrier, prach);
        root = rootLong(1:LRA);

        % Multiply the preamble by the complex conjugate of the root sequence and
        % take the ifft - same as correlation.
        noRoot = conj(root) .* preamble / LRA;
        % We want a symmetric FFT.
        noRootLarge = [noRoot(halfLRA + 1:end, :); zeros(Nfft - LRA, nAntennas); noRoot(1:halfLRA, :)];

        noRootTimeSimple = ifft(noRootLarge) * sqrt(Nfft);
        modSquare = abs(noRootTimeSimple).^2;

        noRootTimeSinc = noRootTimeSimple * sqrt(Nfft / LRA);

        nWindows = min(info.nShifts, remainingShifts);

        for iWindow = 1:nWindows
            % Scale the detection window according to the FFT size.
            winWidth = floor(info.WinWidths(iWindow) * Nfft / LRA);
            winStart = mod(Nfft - round(info.WinStart(iWindow) * Nfft / LRA), Nfft);

            ix = (winStart - marg):(winStart + winWidth + marg - 1);

            winScalar = abs(noRootTimeSinc(winStart + (1:winWidth), :)).^2;

            % GLRT inspired detection test.
            reference = sum(modSquare(mod(ix, Nfft) + 1, :), 1);

            % The absolute value at the denominator shouldn't be necessary.
            % Nevertheless, because of the approximations, it may happen that
            % the difference at the denominator takes very small negative values.
            metricGlobal = 2 * marg * sum(winScalar, 2) ./ abs(sum(reference - winScalar, 2));

            if false
                figure(1) %#ok<UNRCH>
                plot(winStart + (0:winWidth-1), winScalar);
                hold on
                plot(ix, abs(noRootTimeSimple(mod(ix, Nfft) +1, :)));
                hold off
                title(sprintf('%d', (iSequence-1) * info.nShifts + iWindow-1));

                metric = 2 * marg * winScalar ./ abs(reference - winScalar);
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
            % the adjacent window.
            [m, delay] = max(metricGlobal);
            if (m > threshold) && (delay < length(metricGlobal) - 5)
                pos = (iSequence - 1) * nWindows + iWindow;
                indices(pos) = true;
                d = delay + winStart;
                offsets(pos) = (d / Nfft - mod(LRA - info.WinStart(iWindow), LRA) / LRA) * 800;
            end
        end

        % Compute the next root sequence index and the number of preambles still
        % to detect.
        prach.SequenceIndex = mod(prach.SequenceIndex + 1, LRA - 1);
        remainingShifts = remainingShifts - info.nShifts;
        if remainingShifts < 0
            break;
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

    % Get the length of the cyclic prefix, as given in the standard.
    CP = getCP(prach);

    % Express the CP in terms of the PRACH sampling time.
    CPprach = floor(CP * prach.LRA * 64  * prach.SubcarrierSpacing ...
        / (2^mu * 480 * fftsize()));

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

function [preamble, cfo] = preprocess(grid, LRA)
% If the grid contains multiple replicas of the preamble (that is, for all formats
% but Format 0 and Format C0), combine them together after estimating and
% compensating the CFO.

    assert(mod(size(grid, 1), LRA) == 0, 'srsran_matlab:srsPRACHdetector', ...
        'The number of symbols does not match with the preamble length.');

    nAntennas = size(grid, 2);
    %preamble = squeeze(mean(reshape(grid, LRA, [], nAntennas), 2));

    tmp = reshape(grid, LRA, [], nAntennas);

    nPreambles = size(tmp, 2);
    cfo = nan;

    if nPreambles > 1
        prods = complex(nan(LRA, floor(nPreambles / 2), nAntennas));

        % We assume that all replicas undergo the same channel and they only
        % differ for the rotation (constant throughout the replica) due to the CFO.
        for n = 1:2:nPreambles-1
            prods(:, n, :) = conj(tmp(:, 2*n-1, :)) .* tmp(:, 2*n, :);
        end

        cfo = angle(sum(prods, 'all'));
        correctionMatrix = diag(exp(-1j * cfo * (0:nPreambles-1)));

        for iAntenna = 1:nAntennas
            tmp(:, :, iAntenna) = tmp(:, :, iAntenna) * correctionMatrix;
        end
    end

    % Take the mean over the replicas (second dimension) and return one preamble
    % per antenna.
    preamble = squeeze(mean(tmp, 2));
end

% function [s, M] = getsinc(LRA)
%     N = fftsize();
%     st = diric(2*pi*(0:N-1)/N, LRA);
%     if LRA == 839
%         M = 5;
%     else
%         M = 12;
%     end
% 
%     %st((M + 2):(end-M)) = 0;
% 
%     st = st / norm(st);
% 
%     s = fft(st', N) / sqrt(N);
% end

function x = fftsize
% FFT size used by the detector - it defines the offset granularity.
    x = 4096;
end
