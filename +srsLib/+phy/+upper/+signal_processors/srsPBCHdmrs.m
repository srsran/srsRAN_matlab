%srsPBCHdmrs Physical broadcast channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = srsPBCHdmrs(NCELLID, SSBINDEX, LMAX, NHF)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPBCHDMRS, nrPBCHDMRSIndices.

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

function [DMRSsymbols, symbolIndices] = srsPBCHdmrs(NCellID, SSBindex, Lmax, nHF)

    % iBar as described in TS 38.211 Section 7.4.1.4.1
    if Lmax == 4
        iBar = mod(SSBindex, 4) + 4 * nHF; % i = 2 LSBs of SSB index
    else
        iBar = mod(SSBindex, 8);           % i = 3 LSBs of SSB index
    end
    DMRSsymbols = nrPBCHDMRS(NCellID,iBar);
    symbolIndices = nrPBCHDMRSIndices(NCellID, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
