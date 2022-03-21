%SRSPBCHMODULATOR:
%  Function generating the PBCH modulation symbols.
%
%  Call details:
%    [MODULATEDSYMBOLS, SYMBOLINDICES] = SRSPBCHMODULATOR(CW, NCELLID, LMAX) receives the parameters
%      * double array CW - BCH codeword
%      * double NCELLID  - PHY-layer cell ID
%      * double SSBINDEX - index of the SSB
%      * double LMAX     - parameter defining the maximum number of SSBs within a SSB set
%    and returns
%      * complex double array MODULATEDSYMBOLS - PBCH modulated symbols
%      * uint32 array SYMBOLINDICES            - PBCH RE indices

function [modulatedSymbols, symbolIndices] = srsPBCHmodulator(cw, NCellID, SSBindex, Lmax)

    % v as described in TS 38.211 Section 7.3.3.1
    if Lmax == 4
        v = mod(SSBindex, 4); % 2 LSBs of SSB index
    else
        v = mod(SSBindex, 8); % 3 LSBs of SSB index
    end
    modulatedSymbols = nrPBCH(cw, NCellID,v);
    symbolIndices = nrPBCHIndices(NCellID, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
