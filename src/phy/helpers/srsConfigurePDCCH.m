%SRSCONFIGUREPDCCH Generates a physical control channel object.
%   PDCCH = SRSCONFIGUREPDCCH(CORESET, NSTARTBWP, NSIZEBWP, RNTI, AGGREGATIONLEVEL, ...
%       SEARCHSPACETYPE, ALLOCATEDCANDIDATE, DMRSSCRAMBLINGID)
%   returns a PDCCH object with the requested configuration.
%
%   See also nrPDCCHConfig.

function pdcch = srsConfigurePDCCH(coreset, NStartBWP, NSizeBWP, rnti, aggregationLevel, searchSpaceType, allocatedCandidate, DMRSscramblingID)

    if isempty(coreset)
        pdcch = nrPDCCHConfig;
    else
        pdcch = nrPDCCHConfig('CORESET', coreset);
    end
    pdcch.NStartBWP = NStartBWP;
    pdcch.NSizeBWP = NSizeBWP;
    pdcch.RNTI = rnti;
    pdcch.AggregationLevel = aggregationLevel;
    pdcch.SearchSpace.SearchSpaceType = searchSpaceType;
    pdcch.AllocatedCandidate = allocatedCandidate;
    pdcch.DMRSScramblingID = DMRSscramblingID;

end
