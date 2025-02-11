%srsPDCCHCandidatesCommon Generates a list of the lowest CCE index for each PDCCH candidate.
%
%   CANDIDATES = srsPDCCHCandidatesCommon(NUMCCES,NUMCANDIDATES,AGGREGATIONLEVEL,CORESETID,RNTI,SLOTNUM)
%   generates a list of the PDCCH candidates for UE specific SS from:
%   NUMCCES          - number of CCE available in the CORESET.
%   NUMCANDIDATES    - number of candidates given by the SS configuration.
%   AGGREGATIONLEVEL - Number of CCE taken by a PDCCH transmission.
%   CORESETID        - CORESET identifier.
%   RNTI             - UE's RNTI.
%   SLOTNUM          - Slot index within the subframe.
%
%   See also nrPDCCHSpace.

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

function candidates = srsPDCCHCandidatesUE(numCCEs, numCandidates, aggregationLevel, coresetId, rnti, slotNum)

% Load parameters for UE SS.
nCI = 0;
Yp = nr5g.internal.pdcch.getYp('ue', coresetId, rnti, slotNum);
L = aggregationLevel;

% Initialise all candidates to zero.
candidates = zeros(1, numCandidates, 'uint32');

% Generate lowest CCE index for each candidate.
for ms = 0:numCandidates - 1
    candidates(ms + 1) = L * (mod(Yp + ...
        floor(double(ms * numCCEs) / double(L * numCandidates)) + nCI, ...
        floor(numCCEs / L)));
end

end

