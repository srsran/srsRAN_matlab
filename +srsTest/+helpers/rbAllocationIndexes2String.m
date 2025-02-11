%rbAllocationIndexes2String Generates an RB allocation string object compatible with srsran.
%   OUTPUTSTRING = rbAllocationIndexes2String(VRBINDEXES)
%   generates an RB allocation string OUTPUTSTRING from a vector of VRB
%   indexes VRBINDEXES.
%
%   In order to save space, the function detects if the allocation is
%   contiguous for a number of VRB. In that case, it constructs a type1
%   allocation with a start and an end VRB index.
%
%   If the allocation is not contiguous, it constructs a custom allocation.

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

function [output] = rbAllocationIndexes2String(vrbIndexes)
firstRB = vrbIndexes(1);
lastRB = vrbIndexes(end);
countRB = lastRB - firstRB + 1;
if length(vrbIndexes) == countRB
    output = sprintf('rb_allocation::make_type1(%d, %d)', firstRB, ...
        countRB);
else
    output = ['rb_allocation::make_custom({', ...
        array2str(pdschConfig.PRBSet), '})'];
end

end

