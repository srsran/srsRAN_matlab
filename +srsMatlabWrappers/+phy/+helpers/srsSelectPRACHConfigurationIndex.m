%srsSelectPRACHConfigurationIndex selects a valid configuration index.
%   CONFIGURATIONINDEX = srsSelectPRACHConfigurationIndex(CONFIGURATIONSTABLE, PREAMBLEFORMAT)
%   Gets the first configuration index CONFIGURATIONINDEX in a configurations table  CONFIGURATIONSTABLE with the
%   given preamble format PREAMBLEFORMAT.
function ConfigurationIndex = srsSelectPRACHConfigurationIndex(ConfigurationsTable, PreambleFormat)
  for rowIndex = 1:height(ConfigurationsTable)
      if ConfigurationsTable.PreambleFormat{rowIndex} == PreambleFormat
          ConfigurationIndex = ConfigurationsTable.ConfigurationIndex(rowIndex);
          return;
      end
  end
end
