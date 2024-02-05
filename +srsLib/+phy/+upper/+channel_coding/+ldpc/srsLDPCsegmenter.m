%srsLDPCsegmenter LDPC segmentation.
%   SEGMENTS = srsLDPCsegmenter(TRANSBLOCK, BASEGRAPH) takes the bit sequence
%   TRANSBLOCK, appends the CRC and segments the result into a number of SEGMENTS.

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

function segments = srsLDPCsegmenter(transBlock, baseGraph)
    arguments
        transBlock (:, 1) {mustBeTB(transBlock)}
        baseGraph  (1, 1) {mustBeMember(baseGraph, [1, 2])}
    end

    tbSize = length(transBlock);

    if tbSize > 3824
        crcType = "24A";
    else
        crcType = "16";
    end

    transBlockCRC = nrCRCEncode(transBlock, crcType);

    segments = nrCodeBlockSegmentLDPC(transBlockCRC, baseGraph);

    % use SRS convention for filler bits
    FILLERBIT = 254;
    segments(segments == -1) = FILLERBIT;

end

% TB length validating function
function mustBeTB(tb)
    mustBeInRange(tb, 0, 1)
    mustBeInteger(tb)
    tbs = length(tb);
    if ~(mod(tbs, 8) == 0)
        eid = 'Size:notByte';
        msg = 'TBS must be a multiple of 8.';
        throwAsCaller(MException(eid, msg));
    end
    mustBeInRange(tbs, 24, 1277992)
end
