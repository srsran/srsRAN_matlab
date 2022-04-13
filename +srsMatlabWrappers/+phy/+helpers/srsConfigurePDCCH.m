%srsConfigurePDCCH Generates a physical control channel object.
%   PDCCH = srsConfigurePDCCH(VARARGIN) returns a PDCCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPDCCHConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPDCCHConfig.

function pdcch = srsConfigurePDCCH(varargin)

    pdcch = nrPDCCHConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        if strcmp(paramName, 'SearchSpaceType')
            pdcch.SearchSpace.SearchSpaceType = varargin{index};
        else
            pdcch = setfield(pdcch, paramName, varargin{index});
        end
    end

end
