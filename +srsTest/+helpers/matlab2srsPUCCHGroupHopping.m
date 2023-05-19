%matlab2srsPUCCHGroupHopping Generates a PUCCH group hopping string.
%   GROUPHOPPINGSTRING = matlab2srsPUCCHGroupHopping(GROUPHOPPING) returns a
%   string GROUPHOPPINGSTRING that is compliant with the C++ enum class element
%   used in SRSRAN to identify the PUCCH group hopping type GROUPHOPPING.
%
%   See also nrPUCCH0Config, nrPUCCH1Config, nrPUCCH2Config, nrPUCCH3Config, nrPUCCH4Config.

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

function groupHoppingString = matlab2srsPUCCHGroupHopping(groupHopping)
    if strcmp(groupHopping, 'neither')
        type = 'NEITHER';
    elseif strcmp(groupHopping, 'enable')
        type = 'ENABLE';
    elseif strcmp(groupHopping, 'disable')
        type = 'DISABLE';
    else
        error('matlab2srsPUCCHGroupHopping:Invalid', 'Invalid PUCCH group hopping type.');
    end

    groupHoppingString = ['pucch_group_hopping::', type];
