%SRSCONFIGURECARRIER:
%  Function generating a nrCarrierConfig object with the requested configuration.
%
%  Call details:
%    carrier = SRSCONFIGURECARRIER(NCELLID, NUMEROLOGY, NSIZEGRID, NSTARTGRID, NSLOT, NFRAME) receives the parameters
%      * double NCELLID    - PHY-layer cell ID
%      * double numerology - defines the subcarrier spacing
%      * double NSizeGrid  - number of RBs in the carrier resource grid
%      * double NStartGrid - start of carrier resource grid relative to CRB 0
%      * double NSlot      - slot number
%      * double NFrame     - system frame number
%    and returns
%      * nrCarrierConfig carrier - configured carrier object

function carrier = srsConfigureCarrier(NCellID, numerology, NSizeGrid, NStartGrid, NSlot, NFrame)

    carrier = nrCarrierConfig;
    carrier.NCellID = NCellID;
    carrier.SubcarrierSpacing = 15 * (2 .^ numerology);
    carrier.NSizeGrid = NSizeGrid;
    carrier.NStartGrid = NStartGrid;
    carrier.NSlot = NSlot;
    carrier.NFrame = NFrame;

end
