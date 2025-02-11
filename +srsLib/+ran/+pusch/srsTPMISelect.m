%srsTPMISelect Selects a transmission precoding matrix indicator for PUSCH transmissions.
%
%   INFO = srsTPMISelect(H, CodebookSubset, NoiseVar) selects the best
%   transmit precoding matrix indicators (TPMIs) for the given channel
%   matrix H, codebook subset CodebookSubset and noise variance NoiseVar.
%   H is an N-by-M array, where N is the number of receive ports and M is
%   the number of transmit ports. The output INFO is a structure array of
%   size min(N, M) providing, for each possible transmission layer, the
%   best TPMI and the resulting estimated SINR.
%
%   See also nrPUSCHCodebook.

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

function info = srsTPMISelect(H, CodebookSubset, NoiseVar)
arguments
    H              (:, :) double {mustBeNumeric}
    CodebookSubset (1, :) char   {mustBeMember(CodebookSubset, {'fully_and_partial_and_non_coherent', 'partial_and_non_coherent' 'non_coherent'})}
    NoiseVar       (1, 1) double {mustBePositive}
end

% Extract number of transmit ports.
NumTxPorts = size(H, 2);

% Extract number of receive ports.
NumRxPorts = size(H, 1);

% The maximum number of supported layers is the minimum between the number
% of transmit and receive ports.
MaxNumLayers = min(NumRxPorts, NumTxPorts);

% Initialize function outputs.
info = struct("TPMI", num2cell(nan(MaxNumLayers, 1)), "SINR", nan);

% Iterate the possible number of layers.
for NumLayers = 1:MaxNumLayers
    % Get the codebook size from the number of transmission ports, layers
    % and codebook subset.
    CodebookSize = getCodebookSize(NumTxPorts, NumLayers, CodebookSubset);

    % Parameters for best SINR.
    bestSINR = -inf;
    bestTPMI = 0;

    % Iterate all possible TPMI for the codebook.
    for CurrentTPMI = 0:CodebookSize-1
        % Extract precoding matrix.
        W = nrPUSCHCodebook(NumLayers, NumTxPorts, CurrentTPMI).';

        % Calculate SINR for the precoding matrix.
        CurrentSINR = calculateSINR(H, W, NoiseVar);

        %  Update best SINR if it is better than the current one.
        if CurrentSINR > bestSINR
            bestSINR = CurrentSINR;
            bestTPMI = CurrentTPMI;
        end
    end

    info(NumLayers).TPMI = bestTPMI;
    info(NumLayers).SINR = bestSINR;
end

end

function N = getCodebookSize(NumPorts, NumLayers, CodebookSubset)

    if (NumPorts == 2) && (NumLayers == 1)
        if strcmp(CodebookSubset, 'non_coherent')
            N = 2;
        else
            N = 6;
        end
    elseif (NumPorts == 4) && (NumLayers == 1)
        if strcmp(CodebookSubset, 'partial_and_non_coherent')
            N = 12;
        elseif strcmp(CodebookSubset, 'non_coherent')
            N = 4;
        else
            N = 28;
        end
    elseif (NumPorts == 2) && (NumLayers == 2)
        if strcmp(CodebookSubset, 'non_coherent')
            N = 1;
        else
            N = 3;
        end
    elseif (NumPorts == 4) && (NumLayers == 2)
        if strcmp(CodebookSubset, 'partial_and_non_coherent')
            N = 14;
        elseif strcmp(CodebookSubset, 'non_coherent')
            N = 6;
        else
            N = 22;
        end
    elseif (NumPorts == 4) && (NumLayers == 3)
        if strcmp(CodebookSubset, 'partial_and_non_coherent')
            N = 3;
        elseif strcmp(CodebookSubset, 'non_coherent')
            N = 1;
        else
            N = 7;
        end
    elseif (NumPorts == 4) && (NumLayers == 4)
        if strcmp(CodebookSubset, 'partial_and_non_coherent')
            N = 3;
        elseif strcmp(CodebookSubset, 'non_coherent')
            N = 1;
        else
            N = 5;
        end
    else
        error('Invalid number of ports (i.e., %d) and layers (i.e., %d)', NumPorts, NumLayers);
    end

end


function meanSINR = calculateSINR(H, W, NoiseVar)

    % Number of layers.
    NLayers = size(W, 2);

    % Number of transmit ports.
    NTxPorts = size(H, 2);
    assert(NLayers <= NTxPorts);
    assert(NTxPorts == size(W, 1));

    % Number of receive ports.
    NRxPorts = size(H, 1);
    assert(NLayers <= NRxPorts);

    % Calculate SINR denominator.
    HW = H * W;
    den = NoiseVar * inv(HW' * HW + (NoiseVar * eye(NLayers))); %#ok<MINV>

    % Calculate the SINR for each layer.
    SINR = real((1 ./ diag(den)) - 1);

    % Calculate the mean SINR for all layers.
    meanSINR = 10 * log10(mean(SINR));

end
