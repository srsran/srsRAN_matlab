%srsConfigureCarrier Generates a carrier object.
%   CARRIER = srsConfigureCarrier(VARARGIN) returns a CARRIER object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrCarrierConfig, with the exception of the suffix 'Loc' which is accepted.
%   If the requested configuration is invalid, CARRIER is returned empty.
%
%   See also nrCarrierConfig.

function carrier = srsConfigureCarrier(varargin)

    carrier = nrCarrierConfig;
    try
        nofInputParams = length(varargin);
        for index = 1:nofInputParams
            paramName = erase(inputname(index), 'Loc');
            carrier.(paramName) = varargin{index};
        end
    catch
        carrier = [];
    end
end
