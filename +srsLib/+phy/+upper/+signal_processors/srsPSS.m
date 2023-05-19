%srsPSS Primary synchronization signal.
%   [PSSSYMBOLS, PSSINDICES] = srsPSS(NCELLID) generates the PSS for a
%   given physical cell ID NCELLID and returns the BPSK modulated symbols
%   PSSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPSS and nrPSSIndices.

function [PSSsymbols, PSSindices] = srsPSS(NCellID)

    PSSsymbols = nrPSS(NCellID);
    PSSindices = nrPSSIndices('IndexStyle', 'subscript', 'IndexBase', '0based');

end
