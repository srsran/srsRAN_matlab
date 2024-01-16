%srsConfigureCSIRS Generates a Channel State Information Reference Signal object.
%   CSIRSCONFIG = srsConfigureCSIRS(VARARGIN) returns a CSIRS object with the requested configuration.
%   The names of the input parameters must coincide with those of the properties
%   of the nrCSIRSConfig object. If there are errors in the configuration, 
%   CSIRSCONFIG is returned empty.
%
%   See also nrCSIRSConfig.

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

function CSIRSconfig = srsConfigureCSIRS(varargin)

    CSIRSconfig = nrCSIRSConfig;   
    try
        nofInputParams = length(varargin);
        for index = 1:nofInputParams
            paramName = inputname(index);
            CSIRSconfig.(paramName) = varargin{index};
        end
    catch
        CSIRSconfig = [];
    end
