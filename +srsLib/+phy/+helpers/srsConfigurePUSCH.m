%srsConfigurePUSCH Generates a physical uplink shared channel object.
%   PUSCH = srsConfigurePUSCH(VARARGIN) returns a PUSCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPUSCHConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPUSCHConfig and nrPUSCHDMRSConfig.

function pusch = srsConfigurePUSCH(varargin)

    pusch = nrPUSCHConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        pusch.(paramName) = varargin{index};
    end

end
