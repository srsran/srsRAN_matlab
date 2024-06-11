%cell2str Converts an any cell type value into a string.
%   OUTPUTSTRING = cell2str(ARG) converts the input INPUTCELL into its
%   character representation OUTPUTSTRING.

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

function [outoutString] = cell2str(inputCell)
    import srsTest.helpers.array2str

    mat = cell2mat(inputCell);

    if isstring(inputCell) || iscellstr(inputCell)
        outoutString = mat;
    elseif isscalar(mat)
        outoutString = num2str(mat);
    else
        outoutString = ['{', array2str(mat), '}'];
    end
end
