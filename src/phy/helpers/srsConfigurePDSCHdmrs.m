%SRSCONFIGUREPDSCHDMRS Generates a physical shared channel demodulation reference signals configuraiton object.
%   DMRSCONFIG = SRSCONFIGUREPDSCHDMRS(DMRSCONFIGURATIONTYPE, DMRSTYPEAPOSITION, DMRSADDITIONALPOSITION, ...
%       DMRSLENGTH, DRMSSCRAMBLINGID, DRMSSCRAMBLINGINIT, NUMCDMGROUPSWITHOUTDATA)
%   returns a PDSCH DMRS configuration object.
%
%   See also nrPDSCHDMRSConfig.

function DMRSconfig = srsConfigurePDSCHdmrs(DMRSconfigurationType, DMRStypeAposition, DMRSadditionalPosition, DMRSlength, DRMSscramblingID, DRMSscramblingInit, numCDMgroupsWithoutData)

    DMRSconfig = nrPDSCHDMRSConfig;
    DMRSconfig.DMRSConfigurationType = DMRSconfigurationType;
    DMRSconfig.DMRSTypeAPosition = DMRStypeAposition;
    DMRSconfig.DMRSAdditionalPosition = DMRSadditionalPosition;
    DMRSconfig.DMRSLength = DMRSlength;
    DMRSconfig.NIDNSCID = DRMSscramblingID;
    DMRSconfig.NSCID = DRMSscramblingInit;
    DMRSconfig.NumCDMGroupsWithoutData = numCDMgroupsWithoutData;

end
