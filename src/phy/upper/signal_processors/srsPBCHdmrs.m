%SRSPBCHDMRS:
%  Function generating the PBCH DMRS symbols.
%
%  Call details:
%    [DMRSSYMBOLS, SYMBOLINDICES] = SRSPBCHDMRS(CW, NCELLID, LMAX) receives the parameters
%      * double NCELLID  - PHY-layer cell ID
%      * double SSBINDEX - index of the SSB
%      * double LMAX     - parameter defining the maximum number of SSBs within a SSB set
%      * double nHF      - half-frame indicator
%    and returns
%      * complex double array DMRSSYMBOLS - PBCH DMRS symbols
%      * uint32 array SYMBOLINDICES       - PBCH DMRS RE indices

function [DMRSsymbols, symbolIndices] = srsPBCHdmrs(NCellID, SSBindex, Lmax, nHF)

    % iBar as described in TS 38.211 Section 7.4.1.4.1
    if Lmax == 4
        iBar = mod(SSBindex, 4) + 4*nHF; % i = 2 LSBs of SSB index
    else
        iBar = mod(SSBindex, 8);         % i = 3 LSBs of SSB index
    end
    DMRSsymbols = nrPBCHDMRS(NCellID,iBar);
    symbolIndices = nrPBCHDMRSIndices(NCellID, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
