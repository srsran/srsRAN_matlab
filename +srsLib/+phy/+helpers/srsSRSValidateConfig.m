%srsSRSValidateConfig SRS configuration validator.
%   ISVALID = srsSRSValidateConfig(NRCARRIER, SRS) checks whether 
%   the SRS configuration provided in SRS is valid for the
%   carrier NRCARRIER.
%
%   See also nrCarrierConfig, nrSRSConfig.

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

function isValid = srsSRSValidateConfig(nrCarrier, srs)

    isValid = true;

    % Skip any other check if the structure does not have any field.
    if isempty(fieldnames(srs))
        isValid = false;
        return;
    end

    % Validate input.
    SymbolStart = srs.SymbolStart;
    NumSRSSymbols = srs.NumSRSSymbols;
    if (SymbolStart + NumSRSSymbols) > nrCarrier.SymbolsPerSlot
        isValid = false;
        return;
    end 

 
    % In NR, Extended CP is only used with 60 kHz subcarrier spacing.
    if (strcmp(nrCarrier.CyclicPrefix, 'extended') && (nrCarrier.SubcarrierSpacing ~= 60))
        isValid = false;
        return;
    end

    try
        nrSRSIndices(nrCarrier, srs, 'IndexStyle', 'subscript', 'IndexBase', '0based');
    catch
        isValid = false;
        return;
    end
   
end
