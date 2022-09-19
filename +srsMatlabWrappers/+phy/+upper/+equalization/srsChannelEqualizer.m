%srsChannelEqualizer 5G NR MIMO Channel Equalizer.
%   
%   [EQSYMBOLS, EQNOISEVARS] = srsChannelEqualizer(RXSYMBOLS, CHESTS, EQTYPE, NOISEVAR)
%   Equalizes the Resource Elements (RE) in RXSYMBOLS using the estimated
%   channel information CHESTS and the noise variance NOISEVAR, according
%   to the equalization criteria EQTYPE, which cab be either ZF (Zero
%   forcing) or MMSE (Minimum Mean Square Error). EQSYMBOLS contains the 
%   equalized OFDM symbols, while EQNOISEVARS contains the equivalent 
%   post-equalization noise variances, that can be used for soft symbol
%   demodulation.
%
%   RXSYMBOLS is a 3D tensor with dimensions NSC, NSYM, NRX where NSC is 
%   the number of OFDM subcarriers, NSYM is the number of OFDM symbols, and
%   NRX is the number of receive ports.
%
%   CHESTS is a 4D tensor with dimensions NSC, NSYM, NRX, NTX, where NSC is 
%   the number of OFDM subcarriers, NSYM is the number of OFDM symbols, NRX
%   is the number of receive ports and NTX is the number of transmit
%   layers.
%
%   EQSYMBOLS and EQNOISEVARS are 3D tensors with dimensions NSC, NSYM,
%   NTX, where NSC is the number of OFDM subcarriers, NSYM is the number of
%   OFDM symbols, and NTX is the number of transmit layers.
%   
%   See also nrEqualizeMMSE.

function [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, chEsts, eqType, noiseVar)

% Extract the channel tensor shape for number of subcarriers, OFDM symbols,
% Rx ports and Tx layers.
[nSC, nSym, nRx, nTx] = size(chEsts);

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

        % csi contains the MMSE estimated channel gain for each
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
