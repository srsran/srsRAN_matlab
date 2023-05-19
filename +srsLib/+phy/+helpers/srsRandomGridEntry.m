%srsRandomGridEntry Generates a random set of resource grid symbols and indices.
%   [SYMBOLS, INDICES] = srsRandomGridEntry(CARRIER, PORTIDX) generates a set of
%   complex symbols SYMBOLS and its related indices INDICES, emulating a fully
%   allocated resource grid for a given carrier CARRIER and a given port PORTIDX.

%   Copyright 2021-2023 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

function [symbols, indices] = srsRandomGridEntry(carrier, portIdx)

    nofSymbols = carrier.SymbolsPerSlot;
    nofSubcarriers = carrier.NSizeGrid * 12;
    symbols = [1 1j] * (2 * rand(2, nofSymbols * nofSubcarriers) - 1);
    indices = nan(nofSymbols * nofSubcarriers, 3);
    symbolOffset = 0;
    for symbolIdx = 0:nofSymbols-1
        indices(symbolOffset + (1:nofSubcarriers), 1) = 0:nofSubcarriers-1;
        indices(symbolOffset + (1:nofSubcarriers), 2) = ones(1, nofSubcarriers) * symbolIdx;
        indices(symbolOffset + (1:nofSubcarriers), 3) = ones(1, nofSubcarriers) * portIdx;
        symbolOffset = symbolOffset + nofSubcarriers;
    end

end
