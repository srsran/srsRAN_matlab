%array2str Converts an array of numeric values to a string.
%   OUTPUTSTRING = array2str(INPUTARRAY) converts the numeric array INPUTARRAY
%   into its character representation OUTPUTSTRING.

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

function outputString = array2str(inputArray)
    if isempty(inputArray)
        outputString = '{}';
        return;
    end

    if any(~isreal(inputArray))
        fmt = 'cf_t(%f, %f)';
        inputArray = reshape([real(inputArray).'; imag(inputArray).'], [], 1);
    elseif any(mod(inputArray,1) > 0)
        fmt = '%.3f';
    else
        fmt = '%d';
    end
    inputArray = inputArray(:).'; % ensure it's a row
    outputString = [num2str(inputArray(1:end-2), [fmt, ', ']), ' ', num2str(inputArray(end-1:end), fmt)];
  end
