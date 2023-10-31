%srsResourceGridAnalyzer Plots the heat map of a resource grid.
%   srsResourceGridAnalyzer(NRBS, CYCLICPREFIX, RGFILENAME, RGOFFSET, RGSIZE)
%   displays the content (amplitude) of a resource grid of NRBS resource blocks
%   (frequency domain) and one slot (time domain).  The number of symbols in
%   the slot is determined from the cyclic prefix type CYCLICPREFIX. RGOFFSET
%   and RGSIZE are the offset and size, as
%   a number of single-precision complex floating point numbers, of the slot
%   to be analyzed inside the binary file.
%
%   RG = srsResourceGridAnalyzer(...) also returns a matrix RG with the complex-
%   valued samples of the resource grid (rows are subcarriers, columns are symbols).

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

function RG = srsResourceGridAnalyzer(nRBs, cyclicPrefix, rgFilename, rgOffset, rgSize)
    arguments
        nRBs (1, 1) double {mustBeInteger, mustBePositive}
        cyclicPrefix char {mustBeMember(cyclicPrefix, {'normal', 'extended'})}
        rgFilename char {mustBeFile}
        rgOffset (1, 1) double {mustBeInteger, mustBeNonnegative}
        rgSize (1, 1) double {mustBeInteger, mustBePositive}
    end

    nSubcarriers = nRBs * 12;
    nSymbols = 14;
    nPorts = floor(rgSize / (nSubcarriers * nSymbols));

    assert(nSubcarriers * nSymbols * nPorts == rgSize, ['The dimensions of the resource grid ', ...
        '(%d x %d) are not consistent with the buffer size %d.'], nSubcarriers, nSymbols, rgSize);

    % Read file containing the resource grid.
    rxGrid = reshape(srsTest.helpers.readComplexFloatFile(rgFilename, rgOffset, rgSize), ...
        [nSubcarriers, nSymbols, nPorts]);

    % Plot the heat map of the RG amplitude.
    figure("Name", "srsResourceGridAnalyzer");
    tiledlayout('flow');

    for iPort = 1:nPorts
        nexttile
        imagesc(0, 0, abs(rxGrid(:,:,iPort)));
        % By default, imagesc reverses the y axis.
        set(gca, 'YDir','normal');
        colorbar;
        xlabel('Symbol')
        ylabel('Subcarrier')
    end

    if nargout == 1
        RG = rxGrid;
    end
