%srsConfigureCarrier Generates a carrier object.
%   CARRIER = srsConfigureCarrier(VARARGIN) returns a CARRIER object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrCarrierConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrCarrierConfig.

function carrier = srsConfigureCarrier(varargin)

    carrier = nrCarrierConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        switch(paramName)
            case 'NCellID'
                carrier.NCellID = varargin{index};
            case 'SubcarrierSpacing'
                carrier.SubcarrierSpacing = varargin{index};
            case 'NSizeGrid'
                carrier.NSizeGrid = varargin{index};
            case 'NStartGrid'
                carrier.NStartGrid = varargin{index};
            case 'NSlot'
                carrier.NSlot = varargin{index};
            case 'NFrame'
                carrier.NFrame = varargin{index};
            case 'CyclicPrefix'
                carrier.CyclicPrefix = varargin{index};
        end
    end

end
