%srsTransformDeprecode Reverts transform precoding.
%   [data, noise] = srsTransformDeprecode(eqDataSymb, eqNoiseVar, numPRB, numLayers) 
%   reverts the transform precoding operation and estimates the equivalent
%   noise variant.
%
%   See also nrTransformDeprecode.

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

function [dataSymb, noiseVar] = srsTransformDeprecode(eqDataSymb, eqNoiseVar, numPRB, numLayers)
    % Deduce the number of subcarriers and OFDM symbols.
    numSubC = 12 * numPRB;
    numSymbols = length(eqNoiseVar) / numSubC;

    % Revert transform precoding.
    dataSymb = nrTransformDeprecode(eqDataSymb, numPRB);

    % Process noise variance.
    % Reorganize noise variance in OFDM symbols.
    noiseVar = reshape(eqNoiseVar, numSubC, numLayers * numSymbols);
    % Average across OFDM symbols.
    noiseVar = ones(size(noiseVar)) .* mean(noiseVar, 1);
    % Reorganize to match the original shape.
    noiseVar = reshape(noiseVar, numSubC * numSymbols, numLayers);
end

