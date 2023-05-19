%srsPBCHmodulator Physical broadcast channel.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPBCHmodulator(CW, NCELLID, LMAX)
%   modulates the 864-bit BCH codeword CW and returns the complex symbols
%   MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPBCH, nrPBCHIndices.

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

function [modulatedSymbols, symbolIndices] = srsPBCHmodulator(cw, NCellID, SSBindex, Lmax)

    % v as described in TS 38.211 Section 7.3.3.1
    if Lmax == 4
        v = mod(SSBindex, 4); % 2 LSBs of SSB index
    else
        v = mod(SSBindex, 8); % 3 LSBs of SSB index
    end
    modulatedSymbols = nrPBCH(cw, NCellID, v);
    symbolIndices = nrPBCHIndices(NCellID, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
