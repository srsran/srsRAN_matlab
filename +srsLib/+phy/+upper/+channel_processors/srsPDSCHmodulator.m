%srsPDSCHmodulator Physical Downlink Shared Channel.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPDSCHmodulator(CARRIER, PDSCH, CWS)
%   modulates up to two PDSCH codewords CWS and returns the complex symbols
%   MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPDSCH, nrPDSCHIndices.
function [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws)
    modulatedSymbols = nrPDSCH(carrier, pdsch, cws);

    symbolIndices = nrPDSCHIndices(carrier, pdsch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
