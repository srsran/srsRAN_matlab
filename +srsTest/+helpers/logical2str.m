%logical2str Convert logical to character representation.
%   T = logical2str(X) converts the logical X into its character representation
%   ('false' or 'true'). If X is a number, then T is the character representation
%   of X > 0.

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

function logicString = logical2str(input)
    strings = {'false', 'true'};
    logicString = strings{1 + (input > 0)};
