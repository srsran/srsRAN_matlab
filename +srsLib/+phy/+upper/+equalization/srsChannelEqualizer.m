%srsChannelEqualizer 5G NR MIMO Channel Equalizer.
%
%   [EQSYMBOLS, EQNOISEVARS] = srsChannelEqualizer(RXSYMBOLS, CHESTS, EQTYPE, NOISEVAR, TXSCALING)
%   Equalizes the Resource Elements (RE) in RXSYMBOLS using the estimated
%   channel information CHESTS and the noise variance NOISEVAR, according
%   to the equalization criteria EQTYPE, which can be either ZF (Zero
%   Forcing) or MMSE (Minimum Mean Square Error). EQSYMBOLS contains the 
%   equalized OFDM symbols, while EQNOISEVARS contains the equivalent 
%   post-equalization noise variances, which can be used for soft symbol
%   demodulation. The TXSCALING scaling factor is the transmit symbol gain
%   relative to the reference signals used for channel estimation.
%
%   RXSYMBOLS is a two-dimensional array. The first dimension corresponds
%   to the Resource Elements and the second one to the receive antenna 
%   ports.
%
%   CHESTS is a three-dimensional array. The first dimension corresponds to
%   the resource elements, the second one to the receive antenna ports and
%   the third one to the transmit layers.
%
%   EQSYMBOLS and EQNOISEVARS are two-dimensional arrays. The first
%   dimension corresponds to the Resource Elements and the second one to
%   the transmit layers.
%
%   See also nrEqualizeMMSE.

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

function [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, chEsts, eqType, noiseVar, txScaling)

% Extract the number of RE and Rx ports from the channel estimates.
[nRE, nRx, nLayers] = size(chEsts);

% Check that the sizes match.
if (size(rxSymbols, 1) ~= nRE)
    error('Number of channel estimate RE (%d) and Rx signal RE (%d) do not match.', ...
        nRE, size(rxSymbols, 1));
end

if (size(rxSymbols, 2) ~= nRx)
    error('Number of channel estimate receive ports (%d) and Rx signal receive ports (%d) do not match.', ...
        nRx, size(rxSymbols, 2));
end

% Scale the channel estimates to prevent carrying the scaling factor
% around.
chEsts = txScaling * chEsts;

% Permute channel estimate dimensions for easier access - now we have one page
% per RE, and each page has nRx rows and nLayers columns.
chEstsPerm = permute(chEsts, [2, 3, 1]);

% Gram matrix of the channel estimates.
chGram = pagemtimes(pagectranspose(chEstsPerm), chEstsPerm);

if strcmp(eqType, 'MMSE')

    % CSI contains the MMSE estimated channel gain for each
    % transmit layer.
    eqSymbols = nrEqualizeMMSE(rxSymbols, chEsts, noiseVar);

    % Calculate scaling correction term for better LLRs.
    V = eye(nLayers) + chGram / noiseVar;
    correctionTerms = real(pagediag(pagemldivide(V, chGram)))';
    scaledNoiseVars = noiseVar ./ correctionTerms;

    % Correct the equalized symbols.
    eqSymbols = eqSymbols ./ correctionTerms * noiseVar;

    % Calculate the equivalent, post-equalization noise variance.
    eqNoiseVars = scaledNoiseVars - 1;
    assert(all(eqNoiseVars > 0, 'all'), 'srsran_matlab:srsChannelEqualizer', ...
        'Equivalent noise variances should be positive valued.');

elseif strcmp(eqType, 'ZF')

    % Zero Forcing equalization is equivalent to MMSE when the noise
    % variance is 0, that is, in the absense of additive noise.
    [eqSymbols, csi] = nrEqualizeMMSE(rxSymbols, chEsts, 0);

    % Calculate the equivalent, post-equalization noise variance.
    eqNoiseVars = noiseVar .* real(pagediag(pageinv(chGram)))';

    assert(all(abs(eqNoiseVars - noiseVar ./ csi) ./ eqNoiseVars < 1e-6, 'all'), ...
        'srsran_matlab::srsChannelEqualizer', ...
        'ZF equivalent noise computation has failed.');

else
    error('Unknown equalizer %s.', eqType);
end
end

% For each page of A, it returns an array with the diagonal elements.
function d = pagediag(A)
    [nr, nc, np] = size(A);
    assert(nr == nc, 'The pages of A should be square matrices.');
    Q = reshape(A, nr^2, np);
    ix = 1:nr;
    ix = ix + (0:nr:nr*(nr-1));
    d = Q(ix, :);
end
