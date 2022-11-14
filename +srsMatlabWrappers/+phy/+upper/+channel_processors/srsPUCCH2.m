%srsPUCCH2 Physical Uplink Control Channel format 2 modulator.
%   [SYMBOLS, INDICES] = srsPUCCH2(CARRIER, PUCCH, UCICW) modulates a PUCCH
%   Format 2 message containing the UCICW UCI codeword. It returns the
%   complex symbols SYMBOLS as well as a column vector of RE indices INDICES. 
%
%   See also nrPUCCH2 and NRPUCCHIndices.
function [symbols, indices] = srsPUCCH2(carrier, pucch, uciCW)

    symbols = nrPUCCH2(uciCW, pucch.NID, pucch.RNTI, "OutputDataType","single");

    indices = nrPUCCHIndices(carrier, pucch, 'IndexStyle', 'subscript', 'IndexBase', '0based');
end
