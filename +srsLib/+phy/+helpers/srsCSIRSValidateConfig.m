%srsCSIRSValidateConfig CSI-RS configuration validator.
%   ISVALID = srsCSIRSValidateConfig(NRCARRIER, CSIRSCONFIG) checks whether 
%   the CSI-RS configuration provided in CSIRSCONFIG is valid for the
%   carrier NRCARRIER.
%
%   See also nrCarrierConfig, nrCSIRSConfig.

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

function isValid = srsCSIRSValidateConfig(nrCarrier, CSIRSConfig)

    isValid = true;
     
    % In NR, Extended CP is only used with 60 kHz subcarrier spacing.
    if (strcmp(nrCarrier.CyclicPrefix, 'extended') && (nrCarrier.SubcarrierSpacing ~= 60))
        isValid = false;
        return;
    end
    
    % Check that the Density is valid for the selected mapping table row.
    switch (CSIRSConfig.RowNumber)
        case 1
            if (~strcmp(CSIRSConfig.Density, 'three'))
                isValid = false;
                return;
            end
        case {2, 3, 11, 12}
            if (~(strcmp(CSIRSConfig.Density, 'one' ) || ...
                    strcmp(CSIRSConfig.Density, 'dot5even') || ...
                    strcmp(CSIRSConfig.Density, 'dot5odd')))
                isValid = false;
                return;
            end
        case {4, 5, 6, 7, 8, 9, 10}
            if (~strcmp(CSIRSConfig.Density, 'one'))
                isValid = false;
                return;
            end
    end
    
    % Check that the RE locations are not outside PRB boundaries.
    nofRE = 12;
    nofSymbols = 14;
    
    if (strcmp(nrCarrier.CyclicPrefix, 'extended'))
        nofSymbols = 12;
    end
    
    maxSubcarrier = max(cell2mat(CSIRSConfig.SubcarrierLocations));
    maxSymbol = max(cell2mat(CSIRSConfig.SymbolLocations));
    
    % Density three adds two additional RE's to the pattern.
    if (strcmp(CSIRSConfig.Density, 'three'))
        maxSubcarrier = maxSubcarrier + 8;
    end
    
    % FD-CDM increases the maximum occupied subcarrier index.
    if (CSIRSConfig.RowNumber >= 3)
        maxSubcarrier = maxSubcarrier + 1;
    end
    
    % TD-CDM increases the maximum occupied symbol index.
    if ((CSIRSConfig.RowNumber == 8) || (CSIRSConfig.RowNumber == 10) || ...
            (CSIRSConfig.RowNumber == 12))
        maxSymbol = maxSymbol + 1;
    end
    
    % Some mapping table rows increase the maximum occupied symbol index.
    if ((CSIRSConfig.RowNumber == 5) || (CSIRSConfig.RowNumber == 7) || ...
            (CSIRSConfig.RowNumber == 11))
        maxSymbol = maxSymbol + 1;
    end
    
    if ((maxSymbol >= nofSymbols) || (maxSubcarrier >= nofRE))
        isValid = false;
    end
