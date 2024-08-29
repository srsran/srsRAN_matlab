%srsConfigurePRACH Generates a physical random access channel (PRACH) configuration object.
%   PRACH = srsConfigurePRACH(PREAMBLEFORMAT, Name, Value, Name, Value, ...) returns a PRACH
%   configuration object with the requested configuration. PREAMBLEFORMAT may be any valid
%   PRACH preamble format (e.g., '0', 'B4', or 'A1/B1'). The properties that can be specified with
%   Name-Value pairs are the same as those of an nrPRACHConfig object. If the requested
%   configuration is invalid, the function returns an empty array.
%
%   See also nrPRACHConfig.

%   Copyright 2021-2024 Software Radio Systems Limited
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

function prach = srsConfigurePRACH(preambleFormat, prachParams)
    arguments
        preambleFormat {mustBeMember(preambleFormat, ...
            {'0', '1', '2', '3', 'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', ...
             'C0', 'C2', 'A1/B1', 'A2/B2', 'A3/B3'})}
        prachParams.?nrPRACHConfig
    end

    prach = nrPRACHConfig;
    try
        paramList = fieldnames(prachParams);
        for iParam = 1:numel(paramList)
            paramName = paramList{iParam};
            prach.(paramName) = prachParams.(paramName);
        end
    catch
        prach = [];
    end
    prach = setPreambleFormat(prach, preambleFormat);
end


function prach = setPreambleFormat(prach, preambleFormat)
    import srsLib.phy.helpers.srsSelectPRACHConfigurationIndex

    % Select configuration index according to the duplex mode and preamble
    % format.
    prach.ConfigurationIndex = srsSelectPRACHConfigurationIndex(prach.FrequencyRange, prach.DuplexMode, preambleFormat);

    % Force PRACH parameters that depend on the format.
    switch preambleFormat
        case '0'
            prach.SubcarrierSpacing = 1.25;
            prach.LRA = 839;
        case '1'
            prach.SubcarrierSpacing = 1.25;
            prach.LRA = 839;
        case '2'
            prach.SubcarrierSpacing = 1.25;
            prach.LRA = 839;
        case '3'
            prach.SubcarrierSpacing = 5;
            prach.LRA = 839;
        otherwise
            prach.RestrictedSet = 'UnrestrictedSet';
            if (prach.SubcarrierSpacing < 15)
                prach.SubcarrierSpacing = 15;
            end
            if strcmp(prach.DuplexMode, 'TDD')
                prach.ActivePRACHSlot = 1;
            end
            prach.LRA = 139;
    end
end
