%srsConfigurePUCCH Generates a physical uplink control channel object.
%   PUCCH = srsConfigurePUCCH(FORMAT, VARARGIN) returns a PUCCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPUCCHConfig{N} (with N = 1,2 3 or 4)
%
%   See also nrPUCCH1Config, nrPUCCH2Config, nrPUCCH3Config and nrPUCCH4Config.

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

function pucch = srsConfigurePUCCH(format, varargin)

    pucchConstructor = str2func(sprintf('nrPUCCH%dConfig', format));
    pucch = pucchConstructor();
    propertyList = properties(pucch);
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = inputname(index + 1);
        if ~ismember(paramName, propertyList)
            continue;
        end
        pucch.(paramName) = varargin{index};
    end
end
