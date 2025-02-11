%srsSSBgetFirstSymbolIndex Calculates the first OFDM symbol in a 5ms SS/PBCH block burst.
%   SSBFIRSTSYMBOLINDEX = srsSSBgetFirstSymbolIndex(SSBPATTERN, SSBINDEX, CARRIERFREQ)
%   returns an OFDM symbol index in a half-frame SSBFIRSTSYMBOLINDEX, given an SSB pattern
%   case SSBPATTERN, an SSB index SSBINDEX and a carrier frequency CARRIERFREQ.

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

function SSBfirstSymbolIndex = srsSSBgetFirstSymbolIndex(SSBpattern, SSBindex, ~)

    % SSB parameters according to TS 38.213 Section 4.1
    switch SSBpattern
        case 'B' % 30 kHz SCS (n = [0] for carrier frequenies <= 3 GHz, n = [0, 1] for carrier frequencies > 3 GHz)
            n = [0, 1];
            SSBfirstSymbolIndexArray = [4, 8, 16, 20];
            offset = 28;
        case 'D' % 120 kHz SCS (frequencies larger than 6 GHz only)
            n = [0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18];
            SSBfirstSymbolIndexArray = [4, 8, 16, 20];
            offset = 28;
        case 'E' % 240 kHz SCS (frequencies larger than 6 GHz only)
            n = [0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18];
            SSBfirstSymbolIndexArray = [8, 12, 16, 20, 32, 36, 40, 44];
            offset = 56;
        otherwise % case 'A' 15 kHz SCS, case 'C' 30 kHz SCS (n = [0, 1] for carrier frequenies <= 3 GHz, n = [0, 1, 2, 3] for carrier frequencies > 3 GHz)
            n = [0, 1, 2, 3];
            SSBfirstSymbolIndexArray = [2, 8];
            offset = 14;
    end

    lengthSymbolIndicesArray = length(SSBfirstSymbolIndexArray);
    SSBfirstSymbolIndex = SSBfirstSymbolIndexArray(mod(SSBindex, lengthSymbolIndicesArray) + 1) + ...
        offset * n(floor(SSBindex / lengthSymbolIndicesArray) + 1);

end
