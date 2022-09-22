% indices2SymbolMask Generates an OFDM symbol allocation mask.
% MASK = indices2SymbolMask(INDICES) generates a symbol allocation bitmask
% MASK from a set of Resource Element (RE) indices INDICES. 
% 
% INDICES is a two-dimensional array comprising a list of zero-based
% Resource Element (RE) locations, where the first column is the subcarrier
% index, the second column is the OFDM symbol index, and the third one is 
% the antenna port index.
%
% MASK is a 14 element column vector where each element represents an OFDM
% symbol within a 5G NR slot.
%
% see also srsIndexes0BasedSubscrit.

function mask = indices2SymbolMask(indices)

mask = zeros(14, 1); % Maximum possible number of symbols.
for symbolIndex = indices(:, 2)
    mask(symbolIndex + 1) = 1;
end
