%RBallocationMask2string Generates a new RB allocation bitmask string.
%   OUTPUTSTRING = RBallocationMask2string(VARARGIN)
%   generates an RB bitmask allocation string OUTPUTSTRING from either a vector
%   of indices SYMBOLINDICESVECTOR or from a start index PRBSTART and an end
%   index PRBEND.

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

function outputString = RBallocationMask2string(varargin)

    rbAllocation = zeros(52, 1); % maximum possible RB size
    switch length(varargin)
        case 1
            symbolIndicesVector = varargin{1};
            for index = 1:length(symbolIndicesVector)
                REidx = symbolIndicesVector(index, 1);
                rbIdx = fix(double(REidx) / 12);
                rbAllocation(rbIdx + 1) = 1;
            end
        case 2
            PRBstart = varargin{1};
            PRBend = varargin{2};
            for rbIdx = PRBstart:PRBend
                rbAllocation(rbIdx + 1) = 1;
            end
    end
    import srsTest.helpers.cellarray2str
    outputString = cellarray2str({rbAllocation}, false);

end
