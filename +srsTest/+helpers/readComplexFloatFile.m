%readComplexFloatFile Reads complex symbols from a binary file.
%   DATA = readComplexFloatFile(FILENAME) opens and reads an existent
%   binary file FILENAME containing a set of complex symbols, formatted to
%   match the 'file_vector<cf_t>' object used by the SRS gNB.
%
%   DATA = readComplexFloatFile(FILENAME, OFFSET, SIZE), simmilarly to the
%   previous call, but the first sample offset and number of samples is
%   specified through arguments.

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

function data = readComplexFloatFile(filename, varargin)
% Open the file.
fileID = fopen(filename, 'r');

% If there is two additional argument, take it as the offset from the
% beggining of the file (BOF).
if length(varargin) == 2
    % Calculate offset in bytes assuming each sample consists of eight
    % bytes.
    offsetBytes = 8 * varargin{1};
    fseek(fileID, offsetBytes, 'bof');

    % Calculate the number of samples assuming each sample consits of
    % two single precission values.
    nofSingleDataReal = 2 * varargin{2};

    % Read all the samples.
    singleRealData = fread(fileID, nofSingleDataReal, 'float32');
elseif isempty(varargin)
    % Read all the samples.
    singleRealData = fread(fileID, 'float32');
else
    error('Invalid number of inputs.');
end

% Close the file.
fclose(fileID);

% Convert real data to complex.
data = singleRealData(1:2:end) + 1i * singleRealData(2:2:end);
end
