%bitPack Simple data-packing function.
%   PACKEDDATA = bitPack(DATA) converts a set of unpacked uint8 input values
%   DATA (i.e., only the LSB of each uint8 carries useful data) into a set of
%   packed uint8 values PACKEDDATA (i.e., all 8 bits carry useful data).

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

function packedData = bitPack(data)
    packedData = reshape(double(data), 8, [])' * 2.^(7:-1:0)';
end
