%srsPUCCHAnalyzer Analyzes a PUCCH transmission from a resource grid.
%   srsPUCCHAnalyzer(CARRIER, PUCCH, RGFILENAME, RGOFFSET, RGSIZE) analyzes the
%   NR Physical Uplink Control Channel transmission detailed by the carrier
%   configuration CARRIER and by the control channel configuration PUCCH (either
%   Format 1 or Format 2). The resource grid IQ samples are stored in the
%   binary file RGFILENAME. RGOFFSET and RGSIZE are the offset and size, as
%   a number of single-precision complex floating point numbers, of the slot
%   containing the PUCCH transmission inside the binary file.
%
%   Example:
%   % The relevant data can be found in the log file generated by the srsRAN gNB:
%   % look for lines like the following
%   %    2023-06-07T20:54:24.502414 [Upper PHY] [I] [  584.19] RX_SYMBOL: sector=0 offset=636504 size=45864
%   %    2023-06-07T20:54:24.502277 [UL-PHY2 ] [D] [  584.19] PUCCH: rnti=0x4601 format=1 ...
%
%   % Use srsParseLogs to populate the carrier and PUCCH configuration objects
%   % (you will be asked to select the PUCCH entry of the logs):
%   [carrier, pucch] = srsParseLogs
%
%   % Launch the analyzer
%   srsPUCCHAnalyzer(carrier, pucch, 'rx_symbols.bin', 636504, 45864)
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

function srsPUCCHAnalyzer(carrier, pucch, rgFilename, rgOffset, rgSize)
    arguments
        carrier    (1, 1) nrCarrierConfig
        pucch      (1, 1) {mustBeA(pucch, ["nrPUCCH1Config", "nrPUCCH2Config"])}
        rgFilename (1, :) char {mustBeFile}
        rgOffset   (1, 1) double {mustBeInteger, mustBePositive}
        rgSize     (1, 1) double {mustBeInteger, mustBePositive}
    end

    % Create resource grid.
    rxGrid = nrResourceGrid(carrier);
    gridDimensions = size(rxGrid);

    assert(prod(gridDimensions) == rgSize, ['The dimensions of the resource grid ', ...
        '(%d x %d) are not consistent with the buffer size %d.'], gridDimensions(1), gridDimensions(2), rgSize);

    % Read file containing the resource grid.
    rxGrid = reshape(srsTest.helpers.readComplexFloatFile(rgFilename, rgOffset, rgSize), ...
        gridDimensions);

    dmrsInd = nrPUCCHDMRSIndices(carrier, pucch);
    dmrsSym = nrPUCCHDMRS(carrier, pucch);

    [estChannel, noiseEst] = nrChannelEstimate(carrier, rxGrid, dmrsInd, dmrsSym);

    % Get PUCCH REs from received grid and estimated channel grid.
    pucchIndices = nrPUCCHIndices(carrier, pucch);
    [pucchRx, pucchHest] = nrExtractResources(pucchIndices, rxGrid, estChannel);

    % Perform equalization.
    pucchEq = nrEqualizeMMSE(pucchRx, pucchHest, noiseEst);

    % % Decode PUCCH symbols
    % % TODO: For this, we need to log the number of uncoded UCI bits, which is not
    % %       done at the moment.
    % [uciLLRs, rxSymbols] = nrPUCCHDecode(carrier, pucch, ouci, pucchEq, noiseEst);

    % Plots.
    NumXPlots = 2;
    NumYPlots = 2;

    figure("Name", "srsPUCCHAnalyzer");
    clf;

    % Plot resource grid power.
    subplot(NumYPlots, NumXPlots, 1);
    imagesc(0, 0, abs(rxGrid));
    % By default, imagesc reverses the y axis.
    set(gca, 'YDir','normal');
    colorbar;
    xlabel('Symbol')
    ylabel('Subcarrier')

    % Plot estimated channel magnitude.
    subplot(NumYPlots, NumXPlots, 3);
    [symbolIndices, subcIndices] = meshgrid(0:gridDimensions(2) - 1, 0:gridDimensions(1) - 1);
    surf(symbolIndices, subcIndices, abs(estChannel), 'LineStyle','none', 'FaceColor','flat');
    shading flat;
    colorbar;
    title('Channel estimate magnitude');
    xlabel('Symbol');
    ylabel('Subcarrier');
    zlabel('Magnitude');
    axis([0, gridDimensions(2) - 1, 0, gridDimensions(1) - 1, min(abs(estChannel(:))) * 0.9, max(abs(estChannel(:))) * 1.1]);

    % Plot estimated channel magnitude.
    subplot(NumYPlots, NumXPlots, 4);
    surf(symbolIndices, subcIndices, angle(estChannel), 'LineStyle','none', 'FaceColor','flat');
    shading flat;
    colorbar;
    title('Channel estimate phase');
    xlabel('Symbol');
    ylabel('Subcarrier');
    zlabel('Angle [rad]');
    axis([0, gridDimensions(2) - 1, 0, gridDimensions(1) - 1, min(angle(estChannel(:))) * 0.9, max(angle(estChannel(:))) * 1.1]);

    % Plot detected constellation.
    subplot(NumYPlots, NumXPlots, 2);
    plot(real(pucchEq), imag(pucchEq), 'x');
    grid on;
    xlabel('Real');
    ylabel('Imaginary');
    title('Equalized constellation');

    % % Plot soft bits histogram.
    % subplot(NumYPlots, NumXPlots, 5);
    % histogram(uciLLRs, 'Normalization', 'pdf');
    % grid on;
    % xlabel('Soft bits');
    % ylabel('Soft bit count');
    % title('Received soft bit distribution');
