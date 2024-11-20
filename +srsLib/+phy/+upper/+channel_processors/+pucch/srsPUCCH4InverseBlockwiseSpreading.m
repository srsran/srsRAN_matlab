%srsPUCCH4InverseBlockwiseSpreading PUCCH Format 4 blockwise spreading inversion.
%   [originalSymbols, noiseVars] = srsPUCCH4InverseBlockwiseSpreading(...
%       SPREADSYMBOLS, EQNOISEVARS, SPREADINGFACTOR, NOFMODSYMBOLS, OCCI)
%   inverts the blockwise spreading applied to the SPREADSYMBOLS of a 
%   PUCCH Format 4 transmission, returning the unspread ORIGINALSYMBOLS
%   and NOISEVARS.

%   Copyright 2021-2024 Software Radio Systems Limited
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
function [originalSymbols, noiseVars] = srsPUCCH4InverseBlockwiseSpreading(...
    spreadSymbols, eqNoiseVars, spreadingFactor, nofModSymbols, occi)
    % Get the orthogonal sequence.
    if spreadingFactor == 2
        if occi == 0
            wn = [+1 +1 +1 +1 +1 +1 +1 +1 +1 +1 +1 +1].';
        elseif occi == 1
            wn = [+1 +1 +1 +1 +1 +1 -1 -1 -1 -1 -1 -1].';
        else
            error('Invalid SpreadingFactor and OCCI combination: {%d, %d}.', spreadingFactor, occi);
        end
    elseif spreadingFactor == 4
        if occi == 0
            wn = [+1 +1 +1 +1 +1 +1 +1 +1 +1 +1 +1 +1].';
        elseif occi == 1
            wn = [+1 +1 +1 -1j -1j -1j -1 -1 -1 +1j +1j +1j].';
        elseif occi == 2
            wn = [+1 +1 +1 -1 -1 -1 +1 +1 +1 -1 -1 -1].';
        elseif occi == 3
            wn = [+1 +1 +1 +1j +1j +1j -1 -1 -1 -1j -1j -1j].';
        else
            error('Invalid SpreadingFactor and OCCI combination: {%d, %d}.', spreadingFactor, occi);
        end
    else
        error('Invalid SpreadingFactor: %d.', spreadingFactor);
    end

    % Number of subcarriers for PUCCH Format 4.
    nofSubcarriers = 12;
    symbPerOFDMsymb = nofSubcarriers / spreadingFactor;
    lMax = spreadingFactor * nofModSymbols / nofSubcarriers;

    % Reshape spreadSymbols and eqNoiseVars for processing.
    spreadSymbolsMatrix = reshape(spreadSymbols, nofSubcarriers, []);
    eqNoiseVarsMatrix = reshape(eqNoiseVars, nofSubcarriers, []);

    % Apply the orthogonal sequence.
    spreadSymbolsMatrix = spreadSymbolsMatrix ./ wn;

    % Sum the submatrices to get the original symbols.
    originalSymbolsMatrix = complex(zeros(symbPerOFDMsymb, lMax));
    noiseVarsMatrix = zeros(size(originalSymbolsMatrix));
    for i = 0:spreadingFactor-1
        originalSymbolsMatrix = originalSymbolsMatrix ...
            + spreadSymbolsMatrix(i * symbPerOFDMsymb + (1:symbPerOFDMsymb), :);
        noiseVarsMatrix = noiseVarsMatrix ...
            + eqNoiseVarsMatrix(i * symbPerOFDMsymb + (1:symbPerOFDMsymb), :);
    end

    % Reshape into a vector and scale the modulation symbols according to
    % the spreading factor.
    originalSymbols = originalSymbolsMatrix(:) / spreadingFactor;
    noiseVars = noiseVarsMatrix(:);

end % of function pucch4InverseBlockwiseSpreading
