%SRSCONFIGUREPDSCHDMRS Generates a configuration object for the PDSCH demodulation reference signals.
%   DMRSCONFIG = SRSCONFIGUREPDSCHDMRS(VARARGIN) returns a PDSCH DMRS configuration object.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPDSCHDMRSConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPDSCHDMRSConfig.

function DMRSconfig = srsConfigurePDSCHdmrs(varargin)

    DMRSconfig = nrPDSCHDMRSConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        switch(paramName)
            case 'DMRSConfigurationType'
                DMRSconfig.DMRSConfigurationType = varargin{index};
            case 'DMRSTypeAPosition'
                DMRSconfig.DMRSTypeAPosition = varargin{index};
            case 'DMRSAdditionalPosition'
                DMRSconfig.DMRSAdditionalPosition = varargin{index};
            case 'DMRSLength'
                DMRSconfig.DMRSLength = varargin{index};
            case 'NIDNSCID'
                DMRSconfig.NIDNSCID = varargin{index};
            case 'NSCID'
              DMRSconfig.NSCID = varargin{index};
            case 'NumCDMGroupsWithoutData'
              DMRSconfig.NumCDMGroupsWithoutData = varargin{index};
        end
    end

end
