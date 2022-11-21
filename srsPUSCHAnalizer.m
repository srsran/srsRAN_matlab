%% Prepare workspace.
clear;
close all;

%% Prepare configuration.
% Carrier configuration.
carrier = nrCarrierConfig;
carrier.NCellID = 55;
carrier.SubcarrierSpacing = 15;
carrier.CyclicPrefix = 'normal';
carrier.NSizeGrid = 106;
carrier.NStartGrid = 0;
carrier.NSlot = 0;
carrier.NFrame = 29;

% PUSCH configuration.
pusch = nrPUSCHConfig;
pusch.NSizeBWP = 106;
pusch.NStartBWP = 0;
pusch.Modulation = '16QAM';
pusch.NumLayers = 1;
pusch.SymbolAllocation = [0, 14];
pusch.PRBSet = 0:105;
pusch.NID = 55;
pusch.RNTI = hex2dec('4601');
pusch.DMRS.NIDNSCID = 55;
pusch.DMRS.NSCID = 0;
pusch.DMRS.NumCDMGroupsWithoutData = 2;
pusch.DMRS.DMRSAdditionalPosition = 2;
pusch.DMRS.CustomSymbolSet = [2, 7, 11];

% Other parameters.
MultipleHARQProcesses = false;
TargetCodeRate = 340 / 1024;
TransportBlockLength = 2304 * 8;
RV = 0;

% Select file.
rgFilename = sprintf('/tmp/ul_rg_%d.bin', carrier.NFrame * carrier.SlotsPerFrame + carrier.NSlot);

% Create segmentation information.
ulschInfo = nrULSCHInfo(TransportBlockLength, TargetCodeRate);

%% Load resource grid.
import srsTest.helpers.readComplexFloatFile

% Read file containing the resource grid.
rgSamples = readComplexFloatFile(rgFilename);

% Create resource grid.
grid = nrResourceGrid(carrier);
gridDimensions = size(grid);

% Map the samples from the file to the grid.
grid(:) = rgSamples;

% Free unused samples.
clear rgSamples;

%% Estimate channel.

dmrsInd = nrPUSCHDMRSIndices(carrier, pusch);
dmrsSym = nrPUSCHDMRS(carrier, pusch);

[H, nVar, estInfo] = nrChannelEstimate(carrier, grid, dmrsInd, dmrsSym);

%% Equalize.
[dataInd, puschInfo] = nrPUSCHIndices(carrier, pusch);
rxSym = grid(dataInd);
Hest = H(dataInd);

[equalized, csi] = nrEqualizeMMSE(rxSym, Hest, nVar);

%% Decode
import srsMatlabWrappers.phy.helpers.srsConfigureULSCHDecoder

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
surf(symbolIndexes, subcIndexes, abs(grid), 'LineStyle','none', 'FaceColor','flat');
view(0, 90);
shading flat;
colormap parula;
colorbar;
title('Resource grid amplitude');
xlabel('Symbol');
ylabel('Subcarrier');
axis([0, gridDimensions(2) - 1, 0, gridDimensions(1) - 1, min(abs(grid(:))), max(abs(grid(:)))]);

% Plot estimated channel magnitude.
subplot(NumYPlots, NumXPlots, 2);
subcIndexes = 0:gridDimensions(1) - 1;
symbolIndexes = 0:gridDimensions(2) - 1;
[symbolIndexes, subcIndexes] = meshgrid(symbolIndexes, subcIndexes);
surf(symbolIndexes, subcIndexes, abs(H), 'LineStyle','none', 'FaceColor','flat');
shading flat;
colormap parula;
colorbar;
title('Channel estimate magnutude');
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
title('Channel estimate magnutude');
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
title('Equalised constellation');

% Plot soft bits histogram.
subplot(NumYPlots, NumXPlots, 5);
histogram(rxcw);
grid on;
xlabel('Soft bits');
ylabel('Soft bit count');
title('Received soft bit distribution');
