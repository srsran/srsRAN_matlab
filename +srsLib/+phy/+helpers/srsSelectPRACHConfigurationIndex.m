%srsSelectPRACHConfigurationIndex selects a valid configuration index.
%   CONFIGURATIONINDEX = srsSelectPRACHConfigurationIndex(DUPLEXMODE, PREAMBLEFORMAT)
%   Gets the first configuration index CONFIGURATIONINDEX in a configurations table 
%   selected by the duplex mode DUPLEXMODE with the given preamble format PREAMBLEFORMAT.

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

function ConfigurationIndex = srsSelectPRACHConfigurationIndex(FrequencyRange, DuplexMode, PreambleFormat)
    % Select table from the corresponding duplex mode.
    if strcmp(FrequencyRange, 'FR2')
        assert(strcmp(DuplexMode, 'TDD'))
        table = nrPRACHConfig.Tables.ConfigurationsFR2;
    elseif strcmp(DuplexMode, 'FDD')
        assert(strcmp(FrequencyRange, 'FR1'))
        table = nrPRACHConfig.Tables.ConfigurationsFR1PairedSUL;
    elseif strcmp(DuplexMode, 'TDD')
        assert(strcmp(FrequencyRange, 'FR1'))
        table = nrPRACHConfig.Tables.ConfigurationsFR1Unpaired;
    else
        error('Unhandled duplex mode %s.', DuplexMode);
    end
    
    % Find the first row index in the table that matches the preamble format.
    rowIndex = find(strcmp(table.PreambleFormat, PreambleFormat), 1);
    ConfigurationIndex = table.ConfigurationIndex(rowIndex);
end
