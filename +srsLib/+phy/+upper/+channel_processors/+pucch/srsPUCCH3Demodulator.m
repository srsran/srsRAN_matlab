function [softBits] = srsPUCCH3Demodulator(pucch, rxSymbols,dataChEsts, noiseVar)
    import srsLib.phy.upper.channel_modulation.srsDemodulator
    import srsLib.phy.upper.equalization.srsChannelEqualizer
    import srsLib.phy.generic_functions.transform_precoding.srsTransformDeprecode
    import srsLib.phy.upper.channel_processors.pucch.srsPUCCH4InverseBlockwiseSpreading

    % PUCCH uses a single layer.
    numLayers = 1;

    % Equalize channel symbols.
    [eqSymbols, eqNoiseVars] = srsChannelEqualizer(rxSymbols, dataChEsts, 'ZF', noiseVar, 1);

    % Inverse transform precoding.
    [modSymbols, noiseVars] = srsTransformDeprecode(eqSymbols, eqNoiseVars, length(pucch.PRBSet), numLayers);

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
