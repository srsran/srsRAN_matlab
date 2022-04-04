%srsPDCCHdmrs Physical control channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = srsPDCCHdmrs(CARRIER, PDCCH)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrCarrierConfig, nrPDCCHConfig and nrPDCCHSpace.

function [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch)

    % no need of keeping track of the resource element indices of the PDCCH
    [~,DMRSsymbols,symbolIndices] = nrPDCCHSpace(carrier, pdcch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
