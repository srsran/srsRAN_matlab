%srsPUSCHAnalizer Analyzes a PUSCH transmission from a resource grid.
%   srsPUSCHAnalizer(JSONCONFIG, RGFILENAME) Analyzes a NR Physical Uplink
%   Shared Channel transmission described JSONCONFIG and a resource grid
%   stored in a binary file with the name RGFILENAME. 
%
%   Example:
%   jsonConfig = ['{' ...
%       '"slot": 290,' ...
%       '"scs": 15,' ...
%       '"rnti": "4601",' ...
%       '"grid_size_rb": 106,' ...
%       '"bwp_size_rb": 106,' ...
%       '"bwp_start_rb": 0,' ...
%       '"cp": "normal",' ...
%       '"modulation": "16QAM",' ...
%       '"target_code_rate": 0.3320,' ...
%       '"bg": 1,' ...
%       '"rv": 0,' ...
%       '"ndi": true,' ...
%       '"uci": {},' ...
%       '"n_id": 55,' ...
%       '"nof_tx_layers": 1,' ...
%       '"rx_ports": 0,' ...
%       '"dmrs_symbol_pos": [2, 7, 11],', ...
%       '"dmrs": 1,' ...
%       '"scrambling_id": 55,' ...
%       '"n_scid": 0,' ...
%       '"nof_cdm_groups_without_data": 2,' ...
%       '"freq_alloc": [0, 106],' ...
%       '"time_alloc": [0, 14],' ...
%       '"tbs": 18432'...
%       '}'];
%   
%   srsTest.analizers.srsPUSCHAnalizer(jsonConfig, '/tmp/ul_rg_0.bin');
%   

function srsPUSCHAnalizer(jsonConfig, rgFilename, rgOffset, rgSize)
%% Imprt dependencies.
import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
import srsMatlabWrappers.phy.helpers.srsConfigurePUSCH
import srsMatlabWrappers.phy.helpers.srsConfigureULSCHDecoder
import srsTest.helpers.readComplexFloatFile

%% Prepare configuration.
% Parse JSON configuration.
config = jsondecode(jsonConfig);

% Carrier configuration.
carrier = srsConfigureCarrier();
carrier.SubcarrierSpacing = config.scs;
carrier.CyclicPrefix = config.cp;
carrier.NSizeGrid = config.grid_size_rb;
carrier.NStartGrid = 0;
carrier.NSlot = config.slot;
carrier.NFrame = config.frame;

% PUSCH configuration.
pusch = srsConfigurePUSCH();
pusch.NSizeBWP = config.bwp_size_rb;
pusch.NStartBWP = config.bwp_start_rb;
pusch.Modulation = config.modulation;
pusch.NumLayers = config.nof_tx_layers;
pusch.SymbolAllocation = [config.time_alloc(1), config.time_alloc(2)];
pusch.PRBSet = config.freq_alloc(1):(sum(config.freq_alloc) - 1);
pusch.NID = config.n_id;
pusch.RNTI = hex2dec(config.rnti);
pusch.DMRS.NIDNSCID = config.scrambling_id;
pusch.DMRS.NSCID = config.n_scid;
pusch.DMRS.NumCDMGroupsWithoutData = config.nof_cdm_groups_without_data;
pusch.DMRS.CustomSymbolSet = config.dmrs_symbol_pos;

% Other parameters.
MultipleHARQProcesses = false;
TargetCodeRate = config.target_code_rate;
RV = config.rv;
TransportBlockLength = config.tbs;

% Create segmentation information.
ulschInfo = nrULSCHInfo(TransportBlockLength, TargetCodeRate);

%% Load resource grid.
% Read file containing the resource grid.
rgSamples = readComplexFloatFile(rgFilename, rgOffset, rgSize);

% Create resource grid.
rxGrid = nrResourceGrid(carrier);
gridDimensions = size(rxGrid);

% Map the samples from the file to the grid.
rxGrid(:) = rgSamples(:);

% Free unused samples.
clear rgSamples;

%% Estimate channel.

dmrsInd = nrPUSCHDMRSIndices(carrier, pusch);
dmrsSym = nrPUSCHDMRS(carrier, pusch);

[H, nVar, estInfo] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym);

if pusch.DMRS.NumCDMGroupsWithoutData
    H = H * sqrt(1 / 2);
end
    

%% Equalize.
[dataInd, puschInfo] = nrPUSCHIndices(carrier, pusch);
rxSym = rxGrid(dataInd);
Hest = H(dataInd);

[equalized, csi] = nrEqualizeMMSE(rxSym, Hest, nVar);

%% Decode.
% Make sure the TBS is consistent.
TransportBlockLength2 = nrTBS(pusch.Modulation, pusch.NumLayers, length(pusch.PRBSet), puschInfo.NREPerPRB, TargetCodeRate);
if TransportBlockLength ~= TransportBlockLength2
    error('Incosistent configuration. It resulted in %d != %d.', TransportBlockLength, TransportBlockLength2);
end

% Demodulate codeword.
[rxcw, symb] = nrPUSCHDecode(carrier, pusch, equalized, nVar);

% Prepare UL-SCH decoder.
ULSCHDecoder = srsConfigureULSCHDecoder(MultipleHARQProcesses, TargetCodeRate, TransportBlockLength);

% Decode.
[rxBits, blkCRCErr] = ULSCHDecoder(rxcw, pusch.Modulation, pusch.NumLayers, RV);

fprintf('The block CRC error is %d. (1 is KO)\n', blkCRCErr);

%% Plot analis.
NumXPlots = 3;
NumYPlots = 2;

figure("Name", "srsPUSCHAnalizer");
clf;

% Plot resource grid power.
subplot(NumYPlots, NumXPlots, 1);
subcIndexes = 0:gridDimensions(1) - 1;
symbolIndexes = 0:gridDimensions(2) - 1;
[symbolIndexes, subcIndexes] = meshgrid(symbolIndexes, subcIndexes);
surf(symbolIndexes, subcIndexes, abs(rxGrid), 'LineStyle','none', 'FaceColor','flat');
view(0, 90);
shading flat;
colormap parula;
colorbar;
title('Resource grid amplitude');
xlabel('Symbol');
ylabel('Subcarrier');
axis([0, gridDimensions(2) - 1, 0, gridDimensions(1) - 1, min(abs(rxGrid(:))), max(abs(rxGrid(:)))]);

% Plot estimated channel magnitude.
subplot(NumYPlots, NumXPlots, 2);
subcIndexes = 0:gridDimensions(1) - 1;
symbolIndexes = 0:gridDimensions(2) - 1;
[symbolIndexes, subcIndexes] = meshgrid(symbolIndexes, subcIndexes);
surf(symbolIndexes, subcIndexes, abs(H), 'LineStyle','none', 'FaceColor','flat');
shading flat;
colormap parula;
colorbar;
title('Channel estimate magnitude');
xlabel('Symbol');
ylabel('Subcarrier');
zlabel('Magnitude');
axis([0, gridDimensions(2) - 1, 0, gridDimensions(1) - 1, min(abs(H(:))) * 0.9, max(abs(H(:))) * 1.1]);

% Plot estimated channel magnitude.
subplot(NumYPlots, NumXPlots, 3);
subcIndexes = 0:gridDimensions(1) - 1;
symbolIndexes = 0:gridDimensions(2) - 1;
[symbolIndexes, subcIndexes] = meshgrid(symbolIndexes, subcIndexes);
surf(symbolIndexes, subcIndexes, angle(H), 'LineStyle','none', 'FaceColor','flat');
shading flat;
colormap parula;
colorbar;
title('Channel estimate phase');
xlabel('Symbol');
ylabel('Subcarrier');
zlabel('Angle [rad]');
axis([0, gridDimensions(2) - 1, 0, gridDimensions(1) - 1, min(angle(H(:))) * 0.9, max(angle(H(:))) * 1.1]);

% Plot detected constellation.
subplot(NumYPlots, NumXPlots, 4);
plot(real(equalized), imag(equalized), 'x');
grid on;
xlabel('Real');
ylabel('Imaginary');
title('Equalized constellation');

% Plot soft bits histogram.
subplot(NumYPlots, NumXPlots, 5);
histogram(rxcw, 'Normalization', 'pdf');
grid on;
xlabel('Soft bits');
ylabel('Soft bit count');
title('Received soft bit distribution');

end % srsPUSCHAnalizer