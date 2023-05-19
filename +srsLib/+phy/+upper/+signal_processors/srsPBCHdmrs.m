%srsPBCHdmrs Physical broadcast channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = srsPBCHdmrs(NCELLID, SSBINDEX, LMAX, NHF)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPBCHDMRS, nrPBCHDMRSIndices.

function [DMRSsymbols, symbolIndices] = srsPBCHdmrs(NCellID, SSBindex, Lmax, nHF)

    % iBar as described in TS 38.211 Section 7.4.1.4.1
    if Lmax == 4
        iBar = mod(SSBindex, 4) + 4 * nHF; % i = 2 LSBs of SSB index
    else
        iBar = mod(SSBindex, 8);           % i = 3 LSBs of SSB index
    end
    DMRSsymbols = nrPBCHDMRS(NCellID,iBar);
    symbolIndices = nrPBCHDMRSIndices(NCellID, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
