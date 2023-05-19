%writeComplexFloatFile Writes complex symbols to a binary file.
%   writeComplexFloatFile(FILENAME, DATA) generates a new binary file FILENAME
%    containing a set of complex symbols, formatted to match the 'file_vector<cf_t>'
%    object used by the SRS gNB.

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

function writeComplexFloatFile(filename, data)
    % Flatten data.
    data = data(:);

    % Convert data to single precission floating point with interleaved
    % real and imaginary parts.
    singleRealData = nan(1, 2 * numel(data), 'single');
    singleRealData(1:2:end) = real(data);
    singleRealData(2:2:end) = imag(data);

    % Open file, write data and close file.
    fileID = fopen(filename, 'w');
    fwrite(fileID, singleRealData, 'float32');
    fclose(fileID);
end
