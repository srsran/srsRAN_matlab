%srsSelectPRACHConfigurationIndex selects a valid configuration index.
%   CONFIGURATIONINDEX = srsSelectPRACHConfigurationIndex(DUPLEXMODE, PREAMBLEFORMAT)
%   Gets the first configuration index CONFIGURATIONINDEX in a configurations table 
%   selected by the duplex mode DUPLEXMODE with the given preamble format PREAMBLEFORMAT.
function ConfigurationIndex = srsSelectPRACHConfigurationIndex(DuplexMode, PreambleFormat)
    % Select table from the corresponding duplex mode.
    if strcmp(DuplexMode, 'FDD')
        table = nrPRACHConfig.Tables.ConfigurationsFR1PairedSUL;
    elseif strcmp(DuplexMode, 'TDD')
        table = nrPRACHConfig.Tables.ConfigurationsFR1Unpaired;
    else
        error('Unhandled duplex mode %s.', DuplexMode);
    end
    
    % Find a row index in the table that matches the preamble format.
    for rowIndex = 1:height(table)
        if strcmp(table.PreambleFormat{rowIndex}, PreambleFormat)
            ConfigurationIndex = table.ConfigurationIndex(rowIndex);
            return;
        end
    end
end
