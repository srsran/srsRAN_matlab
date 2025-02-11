%indices2SymbolMask Generates an OFDM symbol allocation mask.
%   MASK = indices2SymbolMask(INDICES) generates a symbol allocation bitmask
%   MASK from a set of Resource Element (RE) indices INDICES.
%
%   INDICES is a two-dimensional array comprising a list of zero-based
%   Resource Element (RE) locations, where the first column is the subcarrier
%   index, the second column is the OFDM symbol index, and the third one is
%   the antenna port index.
%
%   MASK is a 14-element column vector where each element represents an OFDM
%   symbol within a 5G NR slot.
%
%   See also srsIndexes0BasedSubscrit.

%   Copyright 2021-2025 Software Radio Systems Limited
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

function mask = indices2SymbolMask(indices)

mask = false(14, 1); % Maximum possible number of symbols.
for symbolIndex = indices(:, 2)
    mask(symbolIndex + 1) = true;
end
