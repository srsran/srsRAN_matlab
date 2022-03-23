%SRSCONFIGUREPDCCH Generates a physical control channel object.
%   PDCCH = SRSCONFIGUREPDCCH(CORESET, NSTARTBWP, NSIZEBWP, RNTI, AGGREGATIONLEVEL, ...
%       SEARCHSPACETYPE, ALLOCATEDCANDIDATE)
%   returns a PDCCH object with the requested configuration.
%
%   See also nrPDCCHConfig.

function pdcch = srsConfigurePDCCH(coreset, NStartBWP, NSizeBWP, rnti, aggregationLevel, searchSpaceType, allocatedCandidate)

    pdcch = nrPDCCHConfig('CORESET', coreset);
    pdcch.NStartBWP = NStartBWP;
    pdcch.NSizeBWP = NSizeBWP;
    pdcch.RNTI = rnti;
    pdcch.AggregationLevel = aggregationLevel;
    pdcch.SearchSpace.SearchSpaceType = searchSpaceType;
    pdcch.AllocatedCandidate = allocatedCandidate;

end
