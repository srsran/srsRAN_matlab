%srsPDCCHCandidatesCommon Generates a list of the lowest CCE index for each PDCCH candidate.
%
%   CANDIDATES = srsPDCCHCandidatesCommon(NUMCCES,NUMCANDIDATES,AGGREGATIONLEVEL)
%   generates a list of the PDCCH candidates for common SS from:
%   NUMCCES          - number of CCE available in the CORESET.
%   NUMCANDIDATES    - number of candidates given by the SS configuration.
%   AGGREGATIONLEVEL - Number of CCE taken by a PDCCH transmission.
%   
%
% See also nrPDCCHSpace.
function candidates = srsPDCCHCandidatesCommon(numCCEs, numCandidates, aggregationLevel)

% Load parameters for common SS.
nCI = 0;
Yp = 0;
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

