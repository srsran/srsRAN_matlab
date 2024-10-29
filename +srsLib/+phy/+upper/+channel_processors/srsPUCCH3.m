%srsPUCCH3 Physical Uplink Control Channel format 3 modulator.
%   [SYMBOLS, INDICES] = srsPUCCH3(CARRIER, PUCCH, UCICW) modulates a PUCCH
%   Format 3 message containing the UCICW UCI codeword. It returns the
%   complex symbols SYMBOLS as well as a column vector of RE indices INDICES.
%
%   See also nrPUCCH3 and nrPUCCHIndices.

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

function [symbols, indices] = srsPUCCH3(carrier, pucch, uciCW)

    symbols = nrPUCCH3(uciCW, pucch.Modulation, pucch.NID, pucch.RNTI, length(pucch.PRBSet), "OutputDataType", "single");

    indices = nrPUCCHIndices(carrier, pucch, 'IndexStyle', 'subscript', 'IndexBase', '0based');
end
