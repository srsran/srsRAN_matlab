%srsConfigurePUSCHdmrs Generates a configuration object for the PUSCH demodulation reference signals.
%   DMRSCONFIG = srsConfigurePUSCHdmrs(VARARGIN) returns a PUSCH DMRS configuration object.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPUSCHDMRSConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPUSCHDMRSConfig.

function DMRSconfig = srsConfigurePUSCHdmrs(varargin)

    DMRSconfig = nrPUSCHDMRSConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        DMRSconfig.(paramName) = varargin{index};
    end

end
