%SRSPDSCHMODULATOR:
%  Function generating the PDSCH modulation symbols.
%
%  Call details:
%    [MODULATEDSYMBOLS, SYMBOLINDICES] = SRSPDSCHMODULATOR(CW, NCELLID, LMAX) receives the parameters
%      * double array cws - PDSCH codewords
%      * struct carrier   - Provides carrier parameters
%      * struct pdsch     - Provides PDSCH transmission parameters
%    and returns
%      * complex double array MODULATEDSYMBOLS - PDSCH modulated symbols
%      * uint32 array SYMBOLINDICES            - PDSCH RE indices

function [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws)
    modulatedSymbols = nrPDSCH(carrier, pdsch, cws);

    symbolIndices = nrPDSCHIndices(carrier, pdsch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
