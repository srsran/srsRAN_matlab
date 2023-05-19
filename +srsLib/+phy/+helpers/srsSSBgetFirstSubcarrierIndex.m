%srsSSBgetFirstSymbolIndex Calculates the position of the first SS/PBCH subcarrier.
%   SSBFIRSTSUBCARRIERINDEX = srsSSBgetFirstSubcarrierIndex(NUMEROLOGY, POINTAOFFSET, SSBOFFSET)
%   returns a subcarrier index SSBFIRSTSUBCARRIERINDEX, given a subcarrier spacing NUMEROLOGY,
%   a bottom grid value POINTAOFFSET and an SSB offset SSBOFFSET. Note that
%   SSBFIRSTSUBCARRIERINDEX is relative to POINTAOFFSET.

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

function SSBfirstSubcarrierIndex = srsSSBgetFirstSubcarrierIndex(numerology, pointAoffset, SSBoffset)

  NRE = 12; % number of RE per RB
  SSBfirstSubcarrierIndex = pointAoffset * NRE + (SSBoffset / (2 .^ numerology));

end
