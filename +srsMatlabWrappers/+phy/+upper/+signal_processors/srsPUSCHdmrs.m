%srsPUSCHdmrs Physical downlink shared channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = srsPUSCHdmrs(CARRIER, PUSCH)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrCarrierConfig, nrPUSCHConfig, nrPUSCHDMRSConfig, nrPUSCHDMRS and nrPUSCHDMRSIndices.

function [DMRSsymbols, symbolIndices] = srsPUSCHdmrs(carrier, pusch)

    DMRSsymbols = nrPUSCHDMRS(carrier, pusch);
    symbolIndices = nrPUSCHDMRSIndices(carrier, pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
