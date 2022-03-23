%SRSPDCCHDMRS:
%  Function generating the PDCCH DMRS symbols.
%
%  Call details:
%    [DMRSSYMBOLS, SYMBOLINDICES] = SRSPBCHDMRS(CW, NCELLID, LMAX) receives the parameters
%      * nrCarrierConfig carrier - configured carrier object
%      * nrPDCCHConfig pdcch     - configured PDCCH object
%    and returns
%      * complex double array DMRSSYMBOLS - PDCCH DMRS symbols
%      * uint32 array SYMBOLINDICES       - PDCCH DMRS RE indices

function [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch)

    % here we are not interested in the resource element indices of the PDCCH
    [~,DMRSsymbols,symbolIndices] = nrPDCCHResources(carrier, pdcch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
