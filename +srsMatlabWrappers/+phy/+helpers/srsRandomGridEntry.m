%srsRandomGridEntry Generates a random set of resource grid symbols and indices.
%   [SYMBOLS, INDICES] = srsRandomGridEntry(CARRIER, PORTIDX) generates a set of
 %  complex symbols SYMBOLS and its related indices INDICES, emulating a fully
 %  allocated resource grid for a given carrier CARRIER and a given port PORTIDX.

function [symbols, indices] = srsRandomGridEntry(carrier, portIdx)

    nofSymbols = carrier.SymbolsPerSlot;
    nofSubcarriers = carrier.NSizeGrid * 12;
    symbols = [1 1j] * (2 * rand(2, nofSymbols * nofSubcarriers) - 1);
    indices = nan(nofSymbols * nofSubcarriers, 3);
    symbolOffset = 0;
    for symbolIdx = 0:nofSymbols-1
        indices(symbolOffset + 1:symbolOffset + nofSubcarriers, 1) = 0:nofSubcarriers-1;
        indices(symbolOffset + 1:symbolOffset + nofSubcarriers, 2) = ones(1, nofSubcarriers) * symbolIdx;
        indices(symbolOffset + 1:symbolOffset + nofSubcarriers, 3) = ones(1, nofSubcarriers) * portIdx;
        symbolOffset = symbolOffset + nofSubcarriers;
    end

end
