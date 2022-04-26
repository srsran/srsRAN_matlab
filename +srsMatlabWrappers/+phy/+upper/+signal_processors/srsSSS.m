%srsSSS Secondary synchronization signal.
%   [SSSSYMBOLS, SSSINDICES] = srsSSS(NCELLID) generates the SSS for a
%   given physical cell ID NCELLID and returns the BPSK modulated symbols
%   SSSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrSSS and nrSSSIndices.

function [SSSsymbols, SSSindices] = srsSSS(NCellID)

    SSSsymbols = nrSSS(NCellID);
    SSSindices = nrSSSIndices('IndexStyle', 'subscript', 'IndexBase', '0based');

end
