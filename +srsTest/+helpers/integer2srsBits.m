%integer2srsBits Convert a nonnegative integer to an SRSRAN amount of bits.
%   B = integer2srsBits(I) converts the nonnegative integer I to an initialization
%   string of a "srsran::units::bits" variable containing I bits.

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

function bitString = integer2srsBits(int)
    arguments
        int (1, 1) double {mustBeInteger, mustBeNonnegative}
    end

    bitString = sprintf('units::bits(%d)', int);
end
