%srsULSCHScramblingPlaceholders Generate UL-SCH Scrambling placeholders
%position.
%   [xInd, yInd] = srsULSCHScramblingPlaceholders(PUSCH, TCR, TBS, OACK, OCSI1, OCSI2)
%   generates a list of UL-SCH scrambling repetition placeholders x and a list of placeholders y.
%
%   See also nrULSCHInfo, nrULSCHDemultiplex, nrPUSCHDecode

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

function [xInd, yInd] = srsULSCHScramblingPlaceholders(pusch, tcr, tbs, ...
                OAck, OCsi1, OCsi2)

    % Get UL-SCH information.
    info = nrULSCHInfo(pusch, tcr, tbs, OAck, OCsi1, OCsi2);

    % Create SCH codeword with all zeros.
    schBits = zeros(info.GULSCH, 1);

    % Create HARQ-ACK bits to zero, encode and rate match.
    ackBits = zeros(OAck, 1);
    ackEncBits = nrUCIEncode(ackBits, info.GACK, pusch.Modulation);

    % Create CSI-Part1 bits to zero, encode and rate match.
    csi1Bits = zeros(OCsi1, 1);
    csi1EncBits = nrUCIEncode(csi1Bits, info.GCSI1, pusch.Modulation);
    
    % Create CSI-Part2 bits to zero, encode and rate match.
    csi2Bits = zeros(OCsi2, 1);
    csi2EncBits = nrUCIEncode(csi2Bits, info.GCSI2, pusch.Modulation);
    
    % Multiplex message, placeholders are marked as -2.
    encBits = nrULSCHMultiplex(pusch, tcr, tbs, schBits, ackEncBits, csi1EncBits, csi2EncBits);

    % Create bit indices list.
    indexes = transpose(0:length(encBits) - 1);

    % Select the bit indices that are x placeholders.
    xInd = indexes(encBits == -1);

    % Select the bit indices that are y placeholders.
    yInd = indexes(encBits == -2);
end
