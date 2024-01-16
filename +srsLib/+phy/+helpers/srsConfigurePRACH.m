%srsConfigurePRACH Generates a physical random access channel (PRACH) configuration object.
%   PRACH = srsConfigurePRACH(VARARGIN) returns a PRACH configuration object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPRACHConfig, with the exception of the suffix 'Loc' which is accepted. Moreover, the
%   'PreambleFormat' parameter is also accepted and used to configure the subcarrier spacing and
%   the length of Zadoff-Chu preamble sequence. If the requested configuration is invalid, PRACH
%   is returned empty.
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

function prach = srsConfigurePRACH(varargin)
    prach = nrPRACHConfig;
    try
        nofInputParams = length(varargin);
        for index = 1:nofInputParams
            paramName = erase(inputname(index), 'Loc');
            if strcmp(paramName,'PreambleFormat')
                prach = setPreambleFormat(prach, varargin{index});
            else
                prach.(paramName) = varargin{index};
            end
        end
    catch
        prach = [];
    end
end


function prach = setPreambleFormat(prach, PreambleFormat)
    import srsLib.phy.helpers.srsSelectPRACHConfigurationIndex
    
    % Select configuration index according to the duplex mode and preamble
    % format.
    prach.ConfigurationIndex = srsSelectPRACHConfigurationIndex(prach.DuplexMode, PreambleFormat);

    % Force PRACH parameters that depend on the format.
    switch PreambleFormat
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
            if strcmp(prach.DuplexMode, 'TDD')
                prach.ActivePRACHSlot = 1;
                prach.SubcarrierSpacing = 30;
            else
                prach.SubcarrierSpacing = 15;
            end
            prach.LRA = 139;
    end
end
