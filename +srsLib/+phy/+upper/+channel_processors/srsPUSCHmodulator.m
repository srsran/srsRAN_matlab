%srsPUSCHmodulator Physical Uplink Shared Channel.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPUSCHmodulator(CARRIER, PUSCH, CW)
%   modulates a single PUSCH codeword CW and returns the complex symbols
%   MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPUSCH, nrPUSCHIndices.
function [modulatedSymbols, symbolIndices] = srsPUSCHmodulator(carrier, pusch, cw)
    modulatedSymbols = nrPUSCH(carrier, pusch, cw);

    symbolIndices = nrPUSCHIndices(carrier, pusch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
