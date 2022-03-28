%SRSCONFIGUREPDSCH Generates a physical shared channel object.
%   PDSCH = SRSCONFIGUREPDSCH(DMRSCONFIG, NSTARTBWP, NSIZEBWP, SCRAMBLINGID, RNTI,...
%       RESERVEDRE, MODULATION, NUMLAYERS, MAPPINGTYPE, SYMBOLALLOCATION, PRBSET)
%   returns a PDSCH object with the requested configuration.
%
%   See also nrPDSCHConfig and nrPDSCHDMRSConfig.

function pdsch = srsConfigurePDSCH(DMRSconfig, NStartBWP, NSizeBWP, scramblingID, rnti, reservedRE, modulation, numLayers, mappingType, symbolAlocation, PRBset)
    if isempty(DMRSconfig)
        pdsch = nrPDSCHConfig;
    else
        pdsch = nrPDSCHConfig('DMRS', DMRSconfig);
    end
    pdsch.NStartBWP = NStartBWP;
    pdsch.NSizeBWP = NSizeBWP;
    pdsch.NID = scramblingID;
    pdsch.RNTI = rnti;
    pdsch.ReservedRE = reservedRE;
    pdsch.Modulation = modulation;
    pdsch.NumLayers = numLayers;
    pdsch.MappingType = mappingType;
    pdsch.SymbolAllocation = symbolAlocation;
    pdsch.PRBSet = PRBset;

end
