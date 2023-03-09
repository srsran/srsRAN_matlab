%srsConfigureSearchSpace Generates a search space object.
%   SEARCHSPACE = srsConfigureSearchSpace(VARARGIN) returns a search space object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrSearchSpaceConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrCORESETConfig.

function SearchSpace = srsConfigureSearchSpace(varargin)

    SearchSpace = nrSearchSpaceConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        SearchSpace.(paramName) = varargin{index};
    end

end
