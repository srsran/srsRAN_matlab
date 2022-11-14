%srsPUCCH1 Physical uplink control channel Format 1 modulator.
%   [SYMBOLS, INDICES] = srsPUCCH1(CARRIER, PUCCH, ACK, SR)
%   modulates a PUCCH Format 1 message containing the HARQ acknowledgment bits
%   provided by ACK and the scheduling request provided by SR. It returns the
%   complex symbols SYMBOLS as well as a column vector of RE indices INDICES.
%
%   See also nrPUCCH1 and nrPUCCHIndices.
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
