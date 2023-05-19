%srsConfigurePUSCH Generates a physical uplink shared channel object.
%   PUSCH = srsConfigurePUSCH(VARARGIN) returns a PUSCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPUSCHConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPUSCHConfig and nrPUSCHDMRSConfig.

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

function pusch = srsConfigurePUSCH(varargin)
    pusch = nrPUSCHConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        pusch.(paramName) = varargin{index};
    end

end
