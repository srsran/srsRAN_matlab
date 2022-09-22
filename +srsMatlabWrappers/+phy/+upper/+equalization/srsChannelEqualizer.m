%srsChannelEqualizer 5G NR MIMO Channel Equalizer.
%   
%   [EQSYMBOLS, EQNOISEVARS] = srsChannelEqualizer(RXSYMBOLS, CHESTS, EQTYPE, NOISEVAR)
%   Equalizes the Resource Elements (RE) in RXSYMBOLS using the estimated
%   channel information CHESTS and the noise variance NOISEVAR, according
%   to the equalization criteria EQTYPE, which can be either ZF (Zero
%   Forcing) or MMSE (Minimum Mean Square Error). EQSYMBOLS contains the 
%   equalized OFDM symbols, while EQNOISEVARS contains the equivalent 
%   post-equalization noise variances, which can be used for soft symbol
%   demodulation.
%
%   RXSYMBOLS is a three-dimensional array. The first dimension corresponds
%   to the OFDM subcarriers, the second one to the OFDM symbols and the
%   third one to the receive antenna ports.
%
%   CHESTS is a four-dimensional array. The first dimension corresponds to
%   the OFDM subcarriers, the second one to the OFDM symbols, the third one
%   to the receive antenna ports and the fourth one to the transmit layers.
%
%   EQSYMBOLS and EQNOISEVARS are three-dimensional arrays. The first
%   dimension corresponds to the OFDM subcarriers, the second one to the 
%   OFDM symbols and the third one to the transmit layers.
%   
%   See also nrEqualizeMMSE.

function [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, chEsts, eqType, noiseVar, txScaling)

% Extract the number of subcarriers, OFDM symbols, Rx ports and Tx layers
% from the channel estimates.
[nSC, nSym, nRx, nTx] = size(chEsts);

% Scale the channel estimates to prevent carrying the scaling factor
% around.
chEsts = txScaling * chEsts;

% Check that the sizes match.
if (size(rxSymbols, 1) ~= nSC)
    error('number of channel estimate (%d) and Rx signal subcarriers (%d) do not match.', ...
        nSC, size(rxSymbols, 1));
end

if (size(rxSymbols, 2) ~= nSym)
    error('number of channel estimate (%d) and Rx signal OFDM symbols (%d) do not match.', ...
        nSym, size(rxSymbols, 2));
end

if (size(rxSymbols, 3) ~= nRx)
    error('number of channel estimate (%d) and Rx signal receive ports (%d) do not match.', ...
        nRx, size(rxSymbols, 3));
end

eqSymbols = nan(nSC, nSym, nTx);
eqNoiseVars = nan(size(eqSymbols));

for iSym = 1:nSym

    % Get a single OFDM symbol from the Rx signal.
    rxSym = squeeze(rxSymbols(:, iSym, :));

    % Get a single OFDM symbol from the channel estimates.   
    chTensor = squeeze(chEsts(:, iSym, :, :));

    if strcmp(eqType, 'MMSE')

        % CSI contains the MMSE estimated channel gain for each
        % transmit layer.
        [eqSymbols(:, iSym, :), csi] = nrEqualizeMMSE(rxSym, chTensor, noiseVar);
   
    elseif strcmp(eqType, 'ZF')
        
        % Zero Forcing equalization is equivalent to MMSE when the noise
        % variance is 0, that is, in the absense of additive noise.
        [eqSymbols(:, iSym, :), csi] = nrEqualizeMMSE(rxSym, chTensor, 0);
    
    else
        error('Unknown equalizer %s.', eqType);
    end
 
    % Calculate the equivalent, post-equalization noise variance.
    eqNoiseVars(:, iSym, :) = noiseVar ./ csi;  
end
