%SRSCSIRS2RESERVEDCELL Generates a cell array that describes a reserved RE 
% pattern list from a carrier configuration and a list of CSI-RS resources.
%
%   [RESERVEDLIST] = srsCSIRS2ReservedCell(CFGOBJ,CSIRSRESOURCES) Generates
%   a cell array that describes a reserved RE pattern list from a carrier
%   configuration and a list of CSI-RS resources.
% 
%   Where the parameter CFGOBJ must be of type <a href="matlab:
%   help('nrDLCarrierConfig')">nrDLCarrierConfig</a> and 
%   CSIRSRESOURCES must be a list integers selecting the indexes of CSI-RS 
%   resources in CFGOBJ.CSIRS. 
%
%   Example: 
%   %  Create first resource of CSI-RS
%   csirs1 = nrcfgCSIRSConfig;
%   csirs1.BandwidthPartID = 1;
%   csirs1.CSIRSType = 'nzp';
%   csirs1.CSIRSPeriod = [10 1];
%   csirs1.RowNumber = 1;
%   csirs1.Density = 'three';
%   csirs1.SymbolLocations = 6;
%   csirs1.SubcarrierLocations = 0;
%   csirs1.NumRB = 52;
%   csirs1.RBOffset = 0;
%   csirs1.NID = 0;
% 
%   % Create a second resource of CSI-RS with a different symbol location
%   csirs2 = csirs1;
%   csirs2.SymbolLocations = 10;
% 
%   % Create a default carrier and set the CSI-RS resources
%   cfgObj = nrDLCarrierConfig;
%   cfgObj.CSIRS= {csirs1, csirs2};
% 
%   % Select the CSI-RS resource of interest
%   CSIRSResources = [2];
%
%   reservedPattern = srsCSIRS2ReservedCell(cfgObj, CSIRSResources);
%
%   display(reservedPattern{1})
function [reservedList] = srsCSIRS2ReservedCell(cfgObj,CSIRSResources)

reservedList = {};

% For each CSIRS resource
for CSIRSIndex = CSIRSResources
    % Select CSI-RS resource configuration
    cfgCSIRS = cfgObj.CSIRS{CSIRSIndex};

    % Extract BWP
    bwp = cfgObj.BandwidthParts{cfgCSIRS.BandwidthPartID};

    % Create carrier object from BWP configuration
    carrier = nrCarrierConfig;
    carrier.NCellID = cfgObj.NCellID;
    carrier.SubcarrierSpacing = bwp.SubcarrierSpacing;
    carrier.CyclicPrefix = bwp.CyclicPrefix;
    carrier.NSizeGrid = bwp.NSizeBWP;
    carrier.NStartGrid = bwp.NStartBWP;
    carrier.NSlot = 0;
    carrier.NFrame = 0;

    % Create CSI-RS configuration
    configuration = nrCSIRSConfig;
    configuration.CSIRSType = cfgCSIRS.CSIRSType;
    configuration.CSIRSPeriod = cfgCSIRS.CSIRSPeriod;
    configuration.RowNumber = cfgCSIRS.RowNumber;
    configuration.Density = cfgCSIRS.Density;
    configuration.SymbolLocations = cfgCSIRS.SymbolLocations;
    configuration.SubcarrierLocations = cfgCSIRS.SubcarrierLocations;
    configuration.NumRB = cfgCSIRS.NumRB;
    configuration.RBOffset = cfgCSIRS.RBOffset;
    configuration.NID = cfgCSIRS.NID;

    % Generate CSI-RS mapping information
    [~, info] = nrCSIRSIndices(carrier, configuration);

    % Parametrize resource element pattern
    RBStart = cfgCSIRS.RBOffset;
    RBEnd = cfgCSIRS.RBOffset + cfgCSIRS.NumRB;
    RBStride = 1;
    RBMask = zeros(1,12);
    SymbolMask = zeros(1,14);

    % Create RE and symbol masks from KBarLbar
    for KBarLBarIndex = 1:length(info.KBarLBar)
        KBarLBar = info.KBarLBar{KBarLBarIndex};
        for KBarLBarIndex2 = 1:length(KBarLBar)
            KBarLBar2 = KBarLBar{KBarLBarIndex2};
            RBMask(KBarLBar2(1) + 1) = 1;
            SymbolMask(KBarLBar2(2) + 1) = 1;
        end
    end

    reservedList = [reservedList, {{RBStart, RBEnd, RBStride, RBMask, SymbolMask}}];
end

end

