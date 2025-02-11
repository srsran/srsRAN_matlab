%srsDemodulator Soft demodulator for NR constellations.
%   LLRSQ = srsDemodulator(SYMBOLS, SCHEME) computes the log-likelihood ratios LLRSQ
%   corresponding to the (noisy) modulated symbols SYMBOLS, and the modulation
%   scheme SCHEME. SYMBOLS is an array of complex values. SCHEME is a character
%   array denoting one of the possible NR constellations, namely 'BPSK', 'pi/2-BPSK',
%   'QPSK', '16QAM', '64QAM', or '256QAM'. The LLRSQ are quantized and take integer
%   values in the range -128 to 127 (mimicking a int8_t variable).
%
%   LLRSQ = srsDemodulator(..., NOISEVAR) specifies the noise variance for the input
%   symbols. If NOISEVAR is an array of positive values, then it must have the same
%   number of elements as SYMBOLS (SYMBOLS have different noise variances). If
%   NOISEVAR is a positive scalar, then it is assumed that the noise variance is
%   the same across all SYMBOLS. The default is NOISEVAR = 1e-10.
%
%   See also nrSymbolDemodulate, qamdemod.

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

function llrsq = srsDemodulator(symbols, scheme, noiseVar)
    arguments
        symbols (:, 1) double
        scheme  (1, :) char {mustBeMember(scheme, {'BPSK', 'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'})}
        noiseVar (:, 1) double {mustBeReal, mustBePositive, mustBeFinite} = 1e-10
    end

    if (numel(noiseVar) > 1)
        assert(numel(symbols) == numel(noiseVar), 'Input NOISEVAR has invalid size.');
    end

    % generate NR constellation
    switch scheme
        case {'BPSK', 'pi/2-BPSK'}
            nBits = 1;
        case 'QPSK'
            nBits = 2;
        case '16QAM'
            nBits = 4;
        case '64QAM'
            nBits = 6;
        case '256QAM'
            nBits = 8;
    end

    if (strcmp(scheme, 'BPSK') || strcmp(scheme, 'pi/2-BPSK'))
        % Because of MATLAB limitations, we need to treat BPSK as QPSK and then combine
        % the LLRs.
        constLabels = [2 3 0 1];
        nConstPoints = 4;

        % To apply different noise variances, symbols must be in a row.
        % The output will be a matrix where each column contains the LLRs corresponding
        % to the symbol with the same index.
        llrsTmp = qamdemod(symbols.', nConstPoints, constLabels, ...
            'UnitAveragePower', true, 'NoiseVariance', noiseVar, 'OutputType', 'approxllr');
        llrs = (llrsTmp(1,:) + llrsTmp(2,:)).';

        if strcmp(scheme, 'pi/2-BPSK')
            llrs(2:2:end) = (-llrsTmp(1,2:2:end) + llrsTmp(2,2:2:end)).';
        end
    else
        nConstPoints = 2^nBits;

        % we need to label the constellation points from the top-left corner, column order
        % first compute the modulated symbols for all possible bit strings, according to the NR constellation
        constPointsBits = int2bit(0:nConstPoints-1, nBits);
        constPoints = nrSymbolModulate(constPointsBits(:), scheme);
        % now, demodulate them to see the position they get in the constellation grid
        tmp1 = qamdemod(constPoints, nConstPoints, 'bin', 'UnitAveragePower', true);
        % finally, invert the map label-point to get the labels in the correct order
        tmp2 = sortrows([tmp1, (0:nConstPoints-1)']);
        constLabels = tmp2(:, 2);

        % demodulate the symbols with the computed constellation
        % To apply different noise variances, symbols must be in a row.
        % The output will be a matrix where each column contains the LLRs corresponding
        % to the symbol with the same index.
        llrsTmp = qamdemod(symbols.', nConstPoints, constLabels, ...
            'UnitAveragePower', true, 'NoiseVariance', noiseVar, 'OutputType', 'approxllr');
        llrs = llrsTmp(:);
    end
    llrsq = quantize(llrs, scheme);
end

function softBitsQuant = quantize(softBits, mod)
    rangeLimitInt = 120;
    switch mod
        case {'BPSK', 'pi/2-BPSK', 'QPSK'}
            rangeLimitFloat = 24;
        case '16QAM'
            rangeLimitFloat = 20;
        case '64QAM'
            rangeLimitFloat = 20;
        case '256QAM'
            rangeLimitFloat = 20;
        otherwise
            error('srsDemodulator:Unknown constellation.');
    end
    softBitsQuant = softBits;
    clipIdx = (abs(softBits) > rangeLimitFloat);
    softBitsQuant(clipIdx) = rangeLimitFloat * sign(softBitsQuant(clipIdx));
    softBitsQuant = round(softBitsQuant * rangeLimitInt / rangeLimitFloat);
end
