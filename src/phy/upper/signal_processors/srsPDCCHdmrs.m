%SRSPDCCHDMRS Physical control channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = SRSPDCCHDMRS(CARRIER, PDCCH)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrCarrierConfig, nrPDCCHConfig and nrPDCCHResources.

function [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch)

    % here we are not interested in the resource element indices of the PDCCH
    [~,DMRSsymbols,symbolIndices] = nrPDCCHSpace(carrier, pdcch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
