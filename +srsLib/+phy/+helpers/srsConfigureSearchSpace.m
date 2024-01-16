%srsConfigureSearchSpace Generates a search space object.
%   SEARCHSPACE = srsConfigureSearchSpace(VARARGIN) returns a search space object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrSearchSpaceConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrCORESETConfig.

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

function SearchSpace = srsConfigureSearchSpace(varargin)

    SearchSpace = nrSearchSpaceConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        SearchSpace.(paramName) = varargin{index};
    end

end
