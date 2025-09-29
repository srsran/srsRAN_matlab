%% Cell planning: Channel State Information (CSI) configuration
% This script demonstrates how to configure Non-Zero Power CSI Reference
% Signals (NZP-CSI-RS) in 5G NR to optimize inter-cell interference
% coordination through static CSI-RS resource mapping.
%
% The srsRAN gNB automates the CSI-RS configuration based on the physical
% cell identifier (PCI). This approach reduces parameter complexity per
% cell and enables self-optimizing network behavior by eliminating the need
% for manual CSI-RS allocation tuning.
%
% The CSI-RS generation and mapping procedures are defined in TS38.211
% Section 7.4.1.5. The primary use cases for CSI-RS include:
%
% * channel measurements;
% * tracking;
% * L1-RSRP computation;
% * mobility.
%
% The key parameters used in the CSI-RS configuration are listed next.
%
% * |RowNumber|: Row number of TS38.211 Table 7.4.1.5.3-1, which provides
%                all possible CSI-RS configurations.
% * |SubcarrierLocations|: Frequency-domain locations of a CSI-RS resource.
% * |Density|: CSI-RS resource frequency density.
% * |SubcarrierLocations|: Frequency-domain locations of a CSI-RS resource
%                          - $k_i$ elements in Column 5 of TS38.211 Table
%                          7.4.1.5.3-1.
% * |SymbolLocations|: Time-domain locations of a CSI-RS resource - $l_0$
%                      and $l_1$ values in Column 5 of TS38.211 Table
%                      7.4.1.5.3-1.

%% CSI-RS for channel measurements - 1 transmit port
% These reference signals are used for generating Channel State Information
% (CSI) reports.
%
% The density of the CSI-RS resources for channel measurement is one (i.e.,
% |Density = 'one'|) and they are located in the fifth symbol within the
% slot (i.e., |SymbolLocations = 4|) for avoiding overlap with other
% signals.
%
% The number of antenna ports determines the row index in TS38.211 Table
% 7.4.1.5.3-1. For instance, row 2 is selected for one transmit port.
% This means that each NZP-CSI-RS resource takes one resource element per
% resource block without any code multiplex.
%
%
% Because of this there are twelve possible frequency domain locations.

% Prepare carrier configuration.
carrier = nrCarrierConfig;

% Create base configuration for TRS.
csirs = nrCSIRSConfig;
csirs.RowNumber = 2;
csirs.SymbolLocations = 4;
csirs.Density = 'one';

resGrid = nrResourceGrid(carrier, csirs.NumCSIRSPorts);

% Given the NZP-CSI-RS density, the frequency domain locations are reused
% every twelve PCI.
numPhysCellId = 12;
physCellIds = 0:(numPhysCellId - 1);

% Iterate over the different PCI and symbol locations.
for thisCellId = physCellIds
    % Configure CSI-RS with the dedicated physical cell parameters
    % depending on the PCI.
    csirs.NID = thisCellId;
    csirs.SubcarrierLocations = mod(thisCellId, numPhysCellId);

    % Generate indices.
    indices = nrCSIRSIndices(carrier, csirs);

    % Generate resource grid.
    resGrid(indices) = thisCellId + 1;
end

% Render resource grid.
renderResourceGrid(resGrid, physCellIds);
title('CSI-RS for Channel Measurement (1 Port, 12 PCI Offsets)');

%% CSI-RS for channel measurements - 2 transmit ports
% For two downlink transmit ports, select row 3: Each NZP-CSI-RS resource
% takes two resource elements per resource block with frequency domain code
% multiplexing.
%
% Because of this there are six possible frequency domain locations.

% Prepare carrier configuration.
carrier = nrCarrierConfig;

% Create base configuration for TRS.
csirs = nrCSIRSConfig;
csirs.RowNumber = 3;
csirs.SymbolLocations = 4;
csirs.Density = 'one';

resGrid = nrResourceGrid(carrier, csirs.NumCSIRSPorts);

% Given the NZP-CSI-RS density, the frequency domain locations are reused
% every six PCI.
numPhysCellId = 6;
physCellIds = 0:(numPhysCellId - 1);

% Iterate over the different PCI and symbol locations.
for thisCellId = physCellIds
    % Configure CSI-RS with the dedicated physical cell parameters
    % depending on the PCI.
    csirs.NID = thisCellId;
    csirs.SubcarrierLocations = 2 * mod(thisCellId, numPhysCellId);

    % Generate indices.
    indices = nrCSIRSIndices(carrier, csirs);

    % Generate resource grid.
    resGrid(indices) = thisCellId + 1;
end

renderResourceGrid(resGrid, physCellIds);
title('CSI-RS for Channel Measurement (2 Port, 6 PCI Offsets)');


%% CSI-RS for channel measurements - 4 transmit ports
% For four downlink transmit ports, select row 4: Each NZP-CSI-RS resource
% takes three resource elements per resource block with frequency domain
% code multiplexing.
%
% Because of this there are three possible frequency domain locations.

% Prepare carrier configuration.
carrier = nrCarrierConfig;

% Create base configuration for TRS.
csirs = nrCSIRSConfig;
csirs.RowNumber = 4;
csirs.SymbolLocations = 4;
csirs.Density = 'one';

resGrid = nrResourceGrid(carrier, csirs.NumCSIRSPorts);

% Given the NZP-CSI-RS density, the frequency domain locations are reused
% every six PCI.
numPhysCellId = 3;
physCellIds = 0:(numPhysCellId - 1);

% Iterate over the different PCI and symbol locations.
for thisCellId = physCellIds
    % Configure CSI-RS with the dedicated physical cell parameters
    % depending on the PCI.
    csirs.NID = thisCellId;
    csirs.SubcarrierLocations = 4 * mod(thisCellId, numPhysCellId);

    % Generate indices.
    indices = nrCSIRSIndices(carrier, csirs);

    % Generate resource grid.
    resGrid(indices) = thisCellId + 1;
end

renderResourceGrid(resGrid, physCellIds);
title('CSI-RS for Channel Measurement (4 Port, 3 PCI Offsets)');


%% CSI-RS for tracking - Tracking Reference Signals (TRS)
% TRS related procedures are given in TS38.214 Section 5.1.6.1.1.
%
% For Frequency Range 1, the UE may be configured with one or more NZP
% CSI-RS sets, where a TRS must comprise an NZP-CSI-RS-ResourceSet
% consisting of four periodic NZP CSI-RS resources in two consecutive
% slots, with two periodic NZP CSI-RS resources in each slot.

% Prepare carrier and resource grid.
carrier = nrCarrierConfig;

% Create base configuration for TRS.
csirs = nrCSIRSConfig;
csirs.RowNumber = 1;
csirs.Density = 'three';

resGrid = nrResourceGrid(carrier, csirs.NumCSIRSPorts);

% Given the NZP-CSI-RS density, the frequency domain locations are reused
% every four PCI.
numPhysCellId = 4;
physCellIds = 0:(numPhysCellId - 1);

% Iterate over the different PCI and symbol locations.
for thisCellId = physCellIds
    % Only symbol locations {4,8}, {5,9}, and {6,10} are allowed for TRS.
    for symbolLocations = [4, 8]
        % Configure CSI-RS with the dedicated physical cell parameters
        % depending on the PCI.
        csirs.NID = thisCellId;
        csirs.SubcarrierLocations = mod(thisCellId, numPhysCellId);
        csirs.SymbolLocations = symbolLocations;

        % Generate indices.
        indices = nrCSIRSIndices(carrier, csirs);

        % Generate resource grid.
        resGrid(indices) = thisCellId + 1;
    end
end

% Render resource grid.
renderResourceGrid(resGrid, physCellIds);
title('CSI-RS for Tracking (4 PCI Offsets)');

%% CSI-RS for L1-RSRP computation
% These CSI-RS resources are intended for performing RSRP measurements and
% CSI reports. Similarly to RSRP measurements from the SS/PBCH block, these
% resources extend the measurement bandwidth. These resources are not
% currently configured in srsRAN.

%% CSI-RS for mobility
% Similar to the previous purpose and not configured in srsRAN.

%% Conclusion and final thoughts
% [Write some conclusion and final thoughts here]

%% References
%
% * TS38.211: Physical Channels and Modulation (Section 7.4.1.5)
% * TS38.214: Physical layer procedures for data (Section 5.1.6.1)
% * TS38.331: RRC (System Information and CSI-RS Configuration)
%
% srsRAN Documentation: https://docs.srsran.com/projects/project/en/latest/tutorials/source/matlab/source/index.html#

%% Helper function: Render Resource Grid
% Visualizes CSI-RS placement in a single resource block (12 subcarriers × 14 symbols)

function renderResourceGrid(resGrid, physCellIds)
% Render resource grid.
clf;
imagesc([0.5, 13.5], [0.5, 11.5], max(resGrid(1:12,:,:), [], 3));
set(gca, 'YDir','normal');
axis([0 14 0 12]);
xticks(0:2:14);
title('CSI-RS positioning with a resource block');
xlabel('OFDM symbol index');
ylabel('Resource element');
grid on;

% Fine-tuned color map.
maxColor = max(physCellIds + 1);
jj = jet(256);
colormap(jj(round(linspace(1, 256, maxColor+1)), :));

% Customize the colorbar ticks and labels.
c = colorbar;
c.Ticks = ((0:maxColor) + 0.5) * maxColor / (maxColor + 1);
c.TickLabels = ["Empty"; cellstr(num2str(transpose(physCellIds), 'PCI=%d'))];
end
