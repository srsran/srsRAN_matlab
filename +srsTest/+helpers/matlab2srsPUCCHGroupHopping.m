%matlab2srsPUCCHGroupHopping Generates a PUCCH group hopping string.
%   GROUPHOPPINGSTRING = matlab2srsPUCCHGroupHopping(GROUPHOPPING) returns a
%   string GROUPHOPPINGSTRING that is compliant with the C++ enum class element
%   used in SRSGNB to identify the PUCCH group hopping type GROUPHOPPING.
%
% See also nrPUCCH0Config, nrPUCCH1Config, nrPUCCH2Config, nrPUCCH3Config, nrPUCCH4Config.

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
