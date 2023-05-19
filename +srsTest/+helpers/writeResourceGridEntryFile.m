%writeResourceGridEntryFile Writes resource grid symbols to a binary file.
%   writeResourceGridEntryFile(FILENAME, DATA, INDICES) generates a new binary
%   file FILENAME containing a set of complex symbols and its related indices,
%   formatted to match the 'file_vector<resource_grid_spy::entry_t>' structures
%   used by the SRSRAN.

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

function writeResourceGridEntryFile(filename, dataIn, indices)
% Make sure data has a good format.
data = dataIn(:);

dataLength = numel(data);
usefulIndices = indices(1:dataLength, :);

% Flatten coordinates in a 32bit register.
gridCoordinate = uint32(usefulIndices(:, 3)) ...
    + uint32(usefulIndices(:, 2)) * 2^8 + ...
    + uint32(usefulIndices(:, 1)) * 2^16;

% Flatten data in a binary format·
if isreal(dataIn)
    singleRealData = zeros(1, 2 * dataLength, 'uint32');
    singleRealData(1:2:end) = gridCoordinate;
    singleRealData(2:2:end) = typecast(single(data), 'uint32');
else
    data = complex(data);
    singleRealData = zeros(1, 3 * dataLength, 'uint32');
    singleRealData(1:3:end) = gridCoordinate;
    singleRealData(2:3:end) = typecast(single(real(data)), 'uint32');
    singleRealData(3:3:end) = typecast(single(imag(data)), 'uint32');
end

% Write all data once.
fileID = fopen(filename, 'w');
fwrite(fileID, singleRealData, 'uint32');
fclose(fileID);
end
