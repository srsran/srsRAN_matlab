%writeUint16File Generates a new binary file with 'uint16_t' entries.
%   writeUint16File(FILENAME, DATA) writes the numeric array DATA to the binary
%   file FILENAME (pathname).

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

function writeUint16File(filename, data)
    fileID = fopen(filename, 'w');
    dataLength = length(data);
    for idx = 1:dataLength
        fwrite(fileID, data(idx), 'uint16');
    end
    fclose(fileID);
end
