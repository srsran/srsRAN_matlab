%srsConfigureCORESET Generates a control resource set object.
%   CORESET = srsConfigureCORESET(VARARGIN) returns a CORESET object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrCORESETConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrCORESETConfig.

function CORESET = srsConfigureCORESET(varargin)

    CORESET = nrCORESETConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        CORESET = setfield(CORESET, paramName, varargin{index});
    end

end
