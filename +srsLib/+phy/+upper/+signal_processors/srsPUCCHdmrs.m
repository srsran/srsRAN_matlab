%srsPUCCHdmrs Physical uplink control channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = srsPUCCHdmrs(CARRIER, PUCCH)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPUCCHDMRS and nrPUCCHDMRSIndices.

function [DMRSsymbols, symbolIndices] = srsPUCCHdmrs(carrier, pucch)

    DMRSsymbols   = nrPUCCHDMRS(carrier, pucch);
    symbolIndices = nrPUCCHDMRSIndices(carrier, pucch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
