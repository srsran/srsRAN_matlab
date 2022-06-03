%srsPDCCHCandidatesCommon Generates a list of the lowest CCE index for each
%PDCCH candidate.
%   candidates = srsPDCCHCandidatesCommon(SSCFG,CRSTCFG,slotNum)
%   Generates a downlink regference signal where the parameter
%
% See also nrPDCCHSpace.
function candidates = srsPDCCHCandidatesCommon(numCCEs, numCandidates, aggregationLevel)
nCI = 0;
Yp = 0;
L = aggregationLevel;


candidates = zeros(1,numCandidates,'uint32');
for ms = 0:numCandidates-1
    candidates(ms+1) = L*( mod(Yp + ...
        floor(double(ms*numCCEs)/double(L*numCandidates)) + nCI, ...
        floor(numCCEs/L)));
end

end

