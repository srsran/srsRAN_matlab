%MODULATED_SYMBOLS_GENERATE:
%  Function generating the modulated symbols from the input bit array.
%
%  Call details:
%    [MODULATEDSYMBOLS] = MODULATED_SYMBOLS_GENERATE(CW, SHEME) receives the parameters
%      * int8 array CW - input codeword as a bit sequence
%      * string SCHEME - parameter defining modulation scheme
%    and returns
%      * complex float array MODULATEDSYMBOLS - modulated symbols

function [modulatedSymbols] = srsModulator(cw, scheme)
    modulatedSymbols = nrSymbolModulate(cw, scheme, 'OutputDataType', 'single');
end
