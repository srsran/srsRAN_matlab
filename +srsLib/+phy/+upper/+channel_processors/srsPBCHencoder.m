%srsPBCHEncoder Physical broadcast channel encoding.
%   CW = srsPBCHEncoder(PAYLOAD, NCELLID, SSBINDEX, LMAX, SFN, HRF, KSSB)
%   encodes the 24-bit BCH payload PAYLOAD and returns the codeword CW.
%
%   See also nrBCH.

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

function cw = srsPBCHencoder(payload, NCellID, SSBindex, Lmax, SFN, hrf, kSSB)

    % subcarrier offset described in TS 38.211 7.4.3.1
    if Lmax == 64
        idxOffset = SSBindex;
    else
        idxOffset = kSSB;
    end
    cw = nrBCH(payload, SFN, hrf, Lmax, idxOffset, NCellID);

end
