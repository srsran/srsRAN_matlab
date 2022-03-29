%SRSPDSCHDMRS Physical downlink shared channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = SRSPDSCHDMRS(CARRIER, PDSCH)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrCarrierConfig, nrPDSCHConfig, nrPDSCHDMRSConfig, nrPDSCHDMRS and nrPDSCHDMRSIndices.

function [DMRSsymbols, symbolIndices] = srsPDSCHdmrs(carrier, pdsch)

    DMRSsymbols = nrPDSCHDMRS(carrier, pdsch);
    symbolIndices = nrPDSCHDMRSIndices(carrier, pdsch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
