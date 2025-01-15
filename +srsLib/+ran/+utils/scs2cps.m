%scs2cps Returns the duration (in ms) of the CPs for one slot depending on the SCS.

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

function cpDurations = scs2cps(scs)
    if (scs == 15)
        cpDurations = [160 144 144 144 144 144 144 160 144 144 144 144 144 144];
    elseif (scs == 30)
        cpDurations = [160 144 144 144 144 144 144 144 144 144 144 144 144 144];
    end
    cpDurations = cpDurations / sum(cpDurations) / scs;
end
