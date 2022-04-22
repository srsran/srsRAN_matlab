%srsConfigurePDSCHdmrs Generates a configuration object for the PDSCH demodulation reference signals.
%   DMRSCONFIG = srsConfigurePDSCHdmrs(VARARGIN) returns a PDSCH DMRS configuration object.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPDSCHDMRSConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPDSCHDMRSConfig.

function DMRSconfig = srsConfigurePDSCHdmrs(varargin)

    DMRSconfig = nrPDSCHDMRSConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        DMRSconfig.(paramName) = varargin{index};
    end

end
