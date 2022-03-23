%SRSCONFIGURECARRIER Generates a carrier object.
%   CARRIER = SRSCONFIGURECARRIER(NCELLID, NUMEROLOGY, NSIZEGRID, NSTARTGRID, NSLOT, NFRAME)
%   returns a CARRIER object with the requested configuration.
%
%   See also nrCarrierConfig.

function carrier = srsConfigureCarrier(NCellID, numerology, NSizeGrid, NStartGrid, NSlot, NFrame)

    carrier = nrCarrierConfig;
    carrier.NCellID = NCellID;
    carrier.SubcarrierSpacing = 15 * (2 .^ numerology);
    carrier.NSizeGrid = NSizeGrid;
    carrier.NStartGrid = NStartGrid;
    carrier.NSlot = NSlot;
    carrier.NFrame = NFrame;

end
