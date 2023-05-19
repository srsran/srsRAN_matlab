%symbolAllocationMask2string Generates a new OFDM symbol allocation bitmask string.
%   OUTPUTSTRING = symbolAllocationMask2string(SYMBOLINDICESVECTOR)
%   generates a symbol bitmask allocation string OUTPUTSTRING from a vector of indices
%   SYMBOLINDICESVECTOR.

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

function outputString = symbolAllocationMask2string(symbolIndicesVector)
    import srsTest.helpers.cellarray2str
    symbolAllocation = zeros(14, 1); % maximum possible number of symbols
    for symbolIndex = symbolIndicesVector(:, 2)
      symbolAllocation(symbolIndex + 1) = 1;
    end
    outputString = cellarray2str({symbolAllocation}, false);

end
