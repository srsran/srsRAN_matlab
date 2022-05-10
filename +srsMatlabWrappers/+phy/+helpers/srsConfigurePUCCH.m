%srsConfigurePUCCH Generates a physical uplink control channel object.
%   PUCCH = srsConfigurePUCCH(FORMAT, VARARGIN) returns a PUCCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPUCCHConfig{N} (with N = 1,2 3 or 4)
%
%   See also nrPUCCH1Config, nrPUCCH2Config, nrPUCCH3Config and nrPUCCH4Config.

function pucch = srsConfigurePUCCH(format, varargin)

    pucchConstructor = str2func(sprintf('nrPUCCH%dConfig', format));
    pucch = pucchConstructor();
    propertyList = properties(pucch);
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = inputname(index + 1);
        if ~ismember(paramName, propertyList)
            continue;
        end
        pucch.(paramName) = varargin{index};
    end
end