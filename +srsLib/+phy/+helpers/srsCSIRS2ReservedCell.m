%srsCSIRS2ReservedCell Generates a cell array that describes a reserved RE pattern.
%   RESERVEDLIST = srsCSIRS2ReservedCell(CARRIER, CSIRSRESOURCES) Generates
%   a cell array that describes a reserved RE pattern list from a carrier
%   configuration and a list of CSI-RS resources.
%
%   Parameter CARRIER must be of type <a href="matlab:
%   help('nrCarrierConfig')">nrCarrierConfig</a> and
%   CSIRSRESOURCES must be a cell array containing CSI-RS resource
%   configurations, of type <a href="matlab:help('nrCSIRSConfig')">nrCSIRSConfig</a>.
%
%   Example:
%      %  Create first resource of CSI-RS
%      csirs1 = nrCSIRSConfig;
%      csirs1.CSIRSType = 'nzp';
%      csirs1.CSIRSPeriod = [10 1];
%      csirs1.RowNumber = 1;
%      csirs1.Density = 'three';
%      csirs1.SymbolLocations = 6;
%      csirs1.SubcarrierLocations = 0;
%      csirs1.NumRB = 52;
%      csirs1.RBOffset = 0;
%      csirs1.NID = 0;
%
%      % Create a second resource of CSI-RS with a different symbol location
%      csirs2 = csirs1;
%      csirs2.SymbolLocations = 10;
%
%      % Create a default carrier
%      carrier = nrCarrierConfig;
%
%      % Select the CSI-RS resource of interest
%      CSIRSResources = {csirs1, csirs2};
%
%      reservedPattern = srsCSIRS2ReservedCell(carrier, CSIRSResources);
%
%      display(reservedPattern{1})

%   Copyright 2021-2025 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

function reservedList = srsCSIRS2ReservedCell(carrier,CSIRSResources)

if isempty(CSIRSResources)
    reservedList = {};
    return;
end

reservedList = cell(1, length(CSIRSResources));

% For each CSIRS resource.
for CSIRSIndex = 1:length(CSIRSResources)
    % Select CSI-RS resource configuration.
    cfgCSIRS = CSIRSResources{CSIRSIndex};

    % Generate CSI-RS mapping information.
    [~, info] = nrCSIRSIndices(carrier, cfgCSIRS);

    % Parametrize resource element pattern.
    RBStart = cfgCSIRS.RBOffset;
    RBEnd = cfgCSIRS.RBOffset + cfgCSIRS.NumRB;

    % Check if the CSI-RS is configured to start on an even RB.
    isEven = mod(RBStart, 2) == 0;
    
    % If the CSI-RS density is set to odd RB and the RB start is even, or
    % if the CSI-RS density is set to even RB and the RB start is odd,
    % No RE are used in the first RB, and therefore it must be excluded 
    % from the pattern.
    if ((strcmp(cfgCSIRS.Density, 'dot5odd') && isEven) || ...
        (strcmp(cfgCSIRS.Density, 'dot5even') && ~isEven))
        RBStart = RBStart + 1;
    end

    RBStride = 1;

    % Skip one of every two RB if the CSI-RS density is set to 0.5.
    if (strcmp(cfgCSIRS.Density, 'dot5even') || strcmp(cfgCSIRS.Density, 'dot5odd'))
        RBStride = 2;
    end
    
    RBMask = zeros(1,12);
    SymbolMask = zeros(1,14);

    % CDM group RE frequency offsets.
    KPrime = info.KPrime{1};

    % CDM group RE time offsets.
    LPrime = info.LPrime{1};
   
    % Create RE and symbol masks from KBarLbar.
    for KBarLBarIndex = 1:length(info.KBarLBar)
        KBarLBar = info.KBarLBar{KBarLBarIndex};
        for KBarLBarIndex2 = 1:length(KBarLBar)

            % Resource grid RE references for each CDM group.
            KBarLBar2 = KBarLBar{KBarLBarIndex2};

            % Set the REs belonging to the CDM group.
            for KPrimeIndex = 1:length(KPrime)
                RBMask(KBarLBar2(1) + KPrime(KPrimeIndex) + 1) = 1;
            end

            for LPrimeIndex = 1:length(LPrime)
                SymbolMask(KBarLBar2(2) + LPrime(LPrimeIndex) + 1) = 1;
            end
        end
    end

    reservedList{CSIRSIndex} = {RBStart, RBEnd, RBStride, RBMask, SymbolMask};
end % of for CSIRSIndex = 1:length(CSIRSResources)
end % of function reservedList = srsCSIRS2ReservedCell...
