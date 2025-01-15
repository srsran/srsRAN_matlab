%srsCSIRSGetNofFreqRefs Number of subcarrier references for CSI-RS mapping.
%   NOFREFS = srsCSIRSGetNofFreqRefs(ROW) returns the number of subcarrier 
%   reference values to map the CSI-RS signal, according to the Row entry
%   ROW of the CSI-RS location table in TS 38.211 Table 7.4.1.5.3-1.

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

function nofRefs = srsCSIRSGetNofFreqRefs(row)

    if ((row > 0) && (row <= 5))
        nofRefs = 1;
    elseif ((row == 6) || (row == 11) || (row == 12))
        nofRefs = 4;
    elseif ((row == 7) || (row == 8))
        nofRefs = 2;
    elseif (row == 9)
        nofRefs = 6;
    elseif (row == 10)
        nofRefs = 3;
    else
        % Unknown or unsupported mapping table row.
        nofRefs = 0;
    end
