%srsPUCCH1 Physical uplink control channel Format 1 modulator.
%   [SYMBOLS, INDICES] = srsPUCCH1(CARRIER, PUCCH, ACK, SR)
%   modulates a PUCCH Format 1 message containing the HARQ acknowledgment bits
%   provided by ACK and the scheduling request provided by SR. It returns the
%   complex symbols SYMBOLS as well as a column vector of RE indices INDICES.
%
%   See also nrPUCCH1 and nrPUCCHIndices.

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

function [symbols, indices] = srsPUCCH1(carrier, pucch, ack, sr)

    FrequencyHopping = 'disabled';
    if strcmp(pucch.FrequencyHopping, 'intraSlot')
        FrequencyHopping = 'enabled';
    end

    symbols = nrPUCCH1(ack, sr, pucch.SymbolAllocation, ...
        carrier.CyclicPrefix, carrier.NSlot, carrier.NCellID, ...
        pucch.GroupHopping, pucch.InitialCyclicShift, FrequencyHopping, ...
        pucch.OCCI);
    indices = nrPUCCHIndices(carrier, pucch, 'IndexStyle', 'subscript', 'IndexBase', '0based');
end
