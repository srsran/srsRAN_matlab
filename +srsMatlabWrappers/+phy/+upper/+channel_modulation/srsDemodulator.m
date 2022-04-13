%srsDemodulator Soft demodulator for NR constellations.
%   LLRS = srsDemodulator(SYMBOLS, SCHEME) computes the log-likelihood ratios LLRS
%   corresponding to the (noisy) modulated symbols SYMBOLS, and the modulation
%   scheme SCHEME. SYMBOLS is an array of complex values. SCHEME is a character
%   array denoting one of the possible NR constellations, namely 'BPSK', 'QPSK',
%   '16QAM', '64QAM', or '256QAM'.
%
%   LLRS = srsDemodulator(..., NOISEVAR) specifies the noise variance for the input
%   symbols. If NOISEVAR is an array of positive values, then it must have the same
%   number of elements as SYMBOLS (SYMBOLS have different noise variances). If
%   NOISEVAR is a positive scalar, then it is assumed that the noise variance is
%   the same across all SYMBOLS. The default is NOISEVAR = 1e-10.
function llrs = srsDemodulator(symbols, scheme, noiseVar)
    arguments
        symbols (:, 1) double
        scheme  (1, :) char {mustBeMember(scheme, {'BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'})}
        noiseVar (:, 1) double {mustBeReal, mustBePositive, mustBeFinite} = 1e-10
    end

    if (numel(noiseVar) > 1)
        assert(numel(symbols) == numel(noiseVar), 'Input NOISEVAR has invalid size.');
    end

    % generate NR constellation
    switch scheme
        case 'BPSK'
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

    if strcmp(scheme, 'BPSK')
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

