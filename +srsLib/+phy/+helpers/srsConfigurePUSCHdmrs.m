%srsConfigurePUSCHdmrs Generates a configuration object for the PUSCH demodulation reference signals.
%   DMRSCONFIG = srsConfigurePUSCHdmrs(VARARGIN) returns a PUSCH DMRS configuration object.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPUSCHDMRSConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPUSCHDMRSConfig.

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

function DMRSconfig = srsConfigurePUSCHdmrs(varargin)

    DMRSconfig = nrPUSCHDMRSConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        DMRSconfig.(paramName) = varargin{index};
    end

end
