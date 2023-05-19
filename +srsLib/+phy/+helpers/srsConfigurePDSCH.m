%srsConfigurePDSCH Generates a physical downlink shared channel object.
%   PDSCH = srsConfigurePDSCH(VARARGIN) returns a PDSCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPDSCHConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPDSCHConfig and nrPDSCHDMRSConfig.

function pdsch = srsConfigurePDSCH(varargin)

    pdsch = nrPDSCHConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        pdsch.(paramName) = varargin{index};
    end

end
