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

function [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, chEsts, eqType, noiseVar, txScaling)

% Extract the number of RE and Rx ports from the channel estimates.
[nRE, nRx, ~] = size(chEsts);

% Scale the channel estimates to prevent carrying the scaling factor
% around.
chEsts = txScaling * chEsts;

% Check that the sizes match.
if (size(rxSymbols, 1) ~= nRE)
    error('Number of channel estimate RE (%d) and Rx signal RE (%d) do not match.', ...
        nRE, size(rxSymbols, 1));
end

if (size(rxSymbols, 2) ~= nRx)
    error('Number of channel estimate receive ports (%d) and Rx signal receive ports (%d) do not match.', ...
        nRx, size(rxSymbols, 2));
end

if strcmp(eqType, 'MMSE')

    % CSI contains the MMSE estimated channel gain for each
    % transmit layer.
    [eqSymbols, csi] = nrEqualizeMMSE(rxSymbols, chEsts, noiseVar);

elseif strcmp(eqType, 'ZF')
    
    % Zero Forcing equalization is equivalent to MMSE when the noise
    % variance is 0, that is, in the absense of additive noise.
    [eqSymbols, csi] = nrEqualizeMMSE(rxSymbols, chEsts, 0);

else
    error('Unknown equalizer %s.', eqType);
end

% Calculate the equivalent, post-equalization noise variance.
eqNoiseVars = noiseVar ./ csi;  
