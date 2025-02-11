%srsPUCCH4Demodulator PUCCH Format 4 demodulation.
%   softBits = srsPUCCH4Demodulator(CARRIER, PUCCH, RXSYMBOLS, DATACHESTS, NOISEVAR)
%   demodulates the received symbols RXSYMBOLS for the given CARRIER and PUCCH
%   configurations and returns the resulting SOFTBITS.

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
function softBits = srsPUCCH4Demodulator(carrier, pucch, rxSymbols,dataChEsts, noiseVar)
    import srsLib.phy.upper.channel_modulation.srsDemodulator
    import srsLib.phy.upper.equalization.srsChannelEqualizer
    import srsLib.phy.generic_functions.transform_precoding.srsTransformDeprecode
    import srsLib.phy.upper.channel_processors.pucch.srsPUCCH4InverseBlockwiseSpreading

    % PUCCH Format 4 uses a single PRB.
    numPRB = 1;

    % PUCCH uses a single layer.
    numLayers = 1;

    % Equalize channel symbols.
    [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, dataChEsts, 'ZF', noiseVar, 1);

    % Inverse transform precoding.
    [spreadSymbols, spreadNoiseVars] = srsTransformDeprecode(eqSymbols, eqNoiseVars, numPRB, numLayers);

    % Inverse block-wise spreading.
    [~, info] = nrPUCCHIndices(carrier, pucch);
    [modSymbols, noiseVars] = srsPUCCH4InverseBlockwiseSpreading(...
        spreadSymbols, spreadNoiseVars, pucch.SpreadingFactor, info.Gd, pucch.OCCI);

    % Convert equalized symbols into softbits.
    softBits = srsDemodulator(modSymbols(:), pucch.Modulation, noiseVars(:));

    % Scrambling sequence for PUCCH.
    scSequence = nrPUCCHPRBS(pucch.NID, pucch.RNTI, length(softBits));

    % Encode the scrambling sequence into the sign, so it can be
    % used with soft bits.
    scSequence = -(scSequence * 2) + 1;

    % Apply descrambling.
    softBits = softBits .* scSequence;
end
