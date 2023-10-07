%srsPUSCHAnalyzer Analyzes a PUSCH transmission from a resource grid.
%   srsPUSCHAnalyzer(CARRIER, PUSCH, EXTRA, RGFILENAME, RGOFFSET, RGSIZE) analyzes the
%   NR Physical Uplink Shared Channel transmission detailed by the carrier
%   configuration CARRIER, by the shared channel configuration PUSCH and by the
%   content of the EXTRA struct (with fields RV (redundancy version), TargetCodeRate
%   and TransportBlockLength). The resource grid IQ samples are stored in the
%   binary file RGFILENAME. RGOFFSET and RGSIZE are the offset and size, as
%   a number of single-precision complex floating point numbers, of the slot
%   containing the PUSCH transmission inside the binary file.
%
%   Example:
%   % The relevant data can be found in the log file generated by the srsRAN gNB:
%   % look for lines like the following
%   %    2023-02-14T22:29:05.651121 [Upper PHY] [I] [   258.4] RX_SYMBOL: sector=0 offset=1141879 size=17808
%   %    2023-02-14T22:29:05.651257 [UL-PHY1 ] [D] [   258.4] PUSCH: harq_id=0 rnti=0x4601 ...
%
%   % Use srsParseLogs to populate the carrier and PUSCH configuration objects, as
%   % well as the EXTRA struct (you will be asked to select the PUSCH entry of the logs):
%   [carrier, pusch, extra] = srsParseLogs
%
%   % Launch the analyzer
%   srsPUSCHAnalyzer(carrier, pusch, extra, 'rx_symbols.bin', 1141879, 17808)
%
%   See also srsParseLogs.

%   Copyright 2021-2023 Software Radio Systems Limited
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

function srsPUSCHAnalyzer(carrier, pusch, extra, rgFilename, rgOffset, rgSize)
    arguments
        carrier    (1, 1) nrCarrierConfig
        pusch      (1, 1) nrPUSCHConfig
        extra      (1, 1) struct
        rgFilename (1, :) char {mustBeFile}
        rgOffset   (1, 1) double {mustBeInteger, mustBePositive}
        rgSize     (1, 1) double {mustBeInteger, mustBePositive}
    end

%% Imprt dependencies.
import srsLib.phy.helpers.srsConfigureULSCHDecoder
import srsTest.helpers.readComplexFloatFile

%% Prepare configuration.

% Other parameters.
MultipleHARQProcesses = false;
TargetCodeRate = extra.TargetCodeRate;
RV = extra.RV;
TransportBlockLength = extra.TransportBlockLength;

%% Load resource grid.
% Read file containing the resource grid.
rgSamples = readComplexFloatFile(rgFilename, rgOffset, rgSize);

% Create resource grid.
rxGrid = nrResourceGrid(carrier);
gridDimensions = size(rxGrid);

assert(prod(gridDimensions) == rgSize, ['The dimensions of the resource grid ', ...
    '(%d x %d) are not consistent with the buffer size %d.'], gridDimensions(1), gridDimensions(2), rgSize);

% Map the samples from the file to the grid.
rxGrid(:) = rgSamples(:);

% Free unused samples.
clear rgSamples;

%% Estimate channel.

dmrsInd = nrPUSCHDMRSIndices(carrier, pusch);
dmrsSym = nrPUSCHDMRS(carrier, pusch);

[H, nVar, ~] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym);

if pusch.DMRS.NumCDMGroupsWithoutData
    H = H * sqrt(1 / 2);
end

% Remove DC from the grid if it is available.
if ~isempty(extra.dcPosition)
    rxGrid(extra.dcPosition + 1, :) = 0;
end

%% Equalize.
[dataInd, puschInfo] = nrPUSCHIndices(carrier, pusch);
rxSym = rxGrid(dataInd);
Hest = H(dataInd);

[equalized, ~] = nrEqualizeMMSE(rxSym, Hest, nVar);

%% Decode.
% Make sure the TBS is consistent.
TransportBlockLength2 = nrTBS(pusch.Modulation, pusch.NumLayers, length(pusch.PRBSet), puschInfo.NREPerPRB, TargetCodeRate);
if TransportBlockLength ~= TransportBlockLength2
    error('Incosistent configuration: the computed TBS is %d, the provided one is %d.', ...
        TransportBlockLength2, TransportBlockLength);
end

% Demodulate codeword.
[rxcw, ~] = nrPUSCHDecode(carrier, pusch, equalized, nVar);

% Make sure equalized zeros translate to soft zeros.
zerosInd = (equalized == 0);
cwZerosInd = repelem(zerosInd, 6);
rxcw(cwZerosInd) = 0;

% Prepare UL-SCH decoder.
ULSCHDecoder = srsConfigureULSCHDecoder(MultipleHARQProcesses, TargetCodeRate, TransportBlockLength);

% Decode.
[~, blkCRCErr] = ULSCHDecoder(rxcw, pusch.Modulation, pusch.NumLayers, RV);

crcStatus = 'OK';
if (blkCRCErr == 1)
    crcStatus = 'KO';
end
fprintf('The block CRC is %s.\n', crcStatus);

%% Plot analysis.
NumXPlots = 3;
NumYPlots = 2;

figure("Name", "srsPUSCHAnalyzer");
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

end % srsPUSCHAnalyzer
