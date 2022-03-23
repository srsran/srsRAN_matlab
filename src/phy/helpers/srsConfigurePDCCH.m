%SRSCONFIGUREPDCCH:
%  Function generating a nrPDCCHConfig object with the requested configuration.
%
%  Call details:
%    PDCCH = SRSCONFIGUREPDCCH(CORESET, NSTARTBWP, NSIZEBWP, RNTI, AGGREGATIONLEVEL, SEARCHSPACETYPE, ALLOCATEDCANDIDATE)
%    receives the parameters
%      * nrCORESET CORESET         - configured CORESET object
%      * double NSTARTBWP          - start of BWP resource grid relative to CRB 0
%      * double NSIZEBWP           - number of RBs in BWP resource grid
%      * double RNTI               - radio network temporary identifier
%      * double AGGREGATIONLEVEL   - PDCCH aggregation level
%      * string SEARCHSPACETYPE    - search space type
%      * double ALLOCATEDCANDIDATE - candidate used for PDCCH instance
%    and returns
%      * nrPDCCHConfig pdcch - configured PDCCH object

function pdcch = srsConfigurePDCCH(coreset, NStartBWP, NSizeBWP, rnti, aggregationLevel, searchSpaceType, allocatedCandidate)

    pdcch = nrPDCCHConfig('CORESET', coreset);
    pdcch.NStartBWP = NStartBWP;
    pdcch.NSizeBWP = NSizeBWP;
    pdcch.RNTI = rnti;
    pdcch.AggregationLevel = aggregationLevel;
    pdcch.SearchSpace.SearchSpaceType = searchSpaceType;
    pdcch.AllocatedCandidate = allocatedCandidate;

end
