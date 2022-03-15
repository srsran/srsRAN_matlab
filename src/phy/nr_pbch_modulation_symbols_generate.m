% NR_PBCH_MODULATION_SYMBOLS_GENERATE:
%   Function generating the PBCH modulation symbols.
%
%   Call details:
%     [MODULATED_SYMBOLS,SYMBOL_INDICES] = NR_PBCH_MODULATION_SYMBOLS_GENERATE(CW,NCELLID,LMAX) receives the parameters
%       * double array CW - BCH codeword
%       * double NCELLID - PHY-layer cell ID
%       * double SSB_INDEX - index of the SSB
%       * double SSB_LMAX - parameter defining the maximum number of SSBs within a SSB set
%     and returns
%       * complex double array MODULATED_SYMBOLS - PBCH modulated symbols
%       * uint32 array SYMBOL_INDICES - PBCH RE indices

function [modulated_symbols,symbol_indices] = nr_pbch_modulation_symbols_generate(cw,NCellID,SSB_index,SSB_Lmax)

    % v as described in TS 38.211 Section 7.3.3.1
    if SSB_Lmax == 4
        v = mod(SSB_index,4); % 2 LSBs of SSB index
    else
        v = mod(SSB_index,8); % 3 LSBs of SSB index
    end
    modulated_symbols = nrPBCH(cw,NCellID,v);
    symbol_indices = nrPBCHIndices(NCellID, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
