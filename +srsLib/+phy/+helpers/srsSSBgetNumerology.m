%srsSSBgetNumerology Returns the numerology of a given SSB pattern.
%   NUMEROLOGY = srsSSBgetNumerology(SSBPATTERN) returns a subcarrier space NUMEROLOGY
%   given an SSB pattern SSBPATTERN.

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

function numerology = srsSSBgetNumerology(SSBpattern)

  numerology = 0; %default 15 kHz SCS
  switch SSBpattern
      case {'B', 'C'}
          numerology = 1; %30 kHz SCS
      case 'D'
          numerology = 3; %120 kHz SCS
      case 'E'
          numerology = 4; %240 kHz SCS
  end

end
