%srsPUSCHmodulator Physical Downlink Shared Channel.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPUSCHmodulator(CARRIER, PUSCH, CWS)
%   modulates up to two PUSCH codewords CWS and returns the complex symbols
%   MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPUSCH, nrPUSCHIndices.
function [modulatedSymbols, symbolIndices] = srsPUSCHmodulator(carrier, pdsch, cws)
    modulatedSymbols = nrPUSCH(carrier, pdsch, cws);

    symbolIndices = nrPUSCHIndices(carrier, pdsch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
