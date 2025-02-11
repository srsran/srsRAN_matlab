%cellarray2str Converts any cell array type into a string.
%   OUTPUTSTRING = cellarray2str(ARG) converts the input INPUTCELLARRAY
%   into its character representation OUTPUTSTRING.
%    ISSTRUCT argument defines whether to use curly brackets wrapping OUTPUTSTRING

%   Copyright 2021-2025 Software Radio Systems Limited
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

function [outputString] = cellarray2str(inputCellArray, isStruct)
    import srsTest.helpers.cell2str
    import srsTest.helpers.cellarray2str

    if isStruct
        outputString = '{';
    else
        outputString = '';
    end

    % manage subcells within the input cell
    for arg = inputCellArray(1:end-1)
        outputString = [outputString, inputCell2str(arg), ', ']; %#ok<AGROW>
    end

    % Manage last element without appending colon.
    if ~isempty(inputCellArray)
      outputString = [outputString, inputCell2str(inputCellArray(end))];
    end

    if isStruct
        outputString = [outputString, '}'];
    end
end

function [outputString] = inputCell2str(inputCell)
    import srsTest.helpers.cell2str
    import srsTest.helpers.cellarray2str
    

    % manage subcells within the input cell
    if iscell(inputCell{1})
        outputString = cellarray2str(inputCell{1}(:)', true);
    else
        outputString = cell2str(inputCell);
    end
end
