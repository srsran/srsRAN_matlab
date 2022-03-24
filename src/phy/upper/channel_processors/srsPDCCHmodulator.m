%srsPDCCHmodulator Physical Downlink Control channel modulator.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPDCCHmodulator(CW, CARRIER, PDCCH, NID, RNTI)
%   modulates the codeword CW using CARRIER and PDCCH objects and returns 
%   the complex symbols MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPDCCH, nrPDCCHResources.

function [modulatedSymbols, symbolIndices] = srsPDCCHmodulator(cw, carrier, pdcch, nID, rnti)
    % get modulated symbols and resource-element indices
    modulatedSymbols = nrPDCCH(cw, nID, rnti);
    symbolIndices = nrPDCCHResources(carrier, pdcch, ...
        'IndexStyle', 'subscript', 'IndexBase', '0based');
end
