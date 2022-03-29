%SRSCONFIGURECORESET Generates a control resource set object.
%   CORESET = SRSCONFIGURECORESET(VARARGIN) returns a CORESET object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrCORESETConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrCORESETConfig.

function CORESET = srsConfigureCORESET(varargin)

    CORESET = nrCORESETConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        switch(paramName)
            case 'FrequencyResources'
                CORESET.FrequencyResources = varargin{index};
            case 'Duration'
                CORESET.Duration = varargin{index};
            case 'CCEREGMapping'
              CORESET.CCEREGMapping = varargin{index};
            case 'REGBundleSize'
              CORESET.REGBundleSize = varargin{index};
            case 'InterleaverSize'
              CORESET.InterleaverSize = varargin{index};
        end
    end


end
