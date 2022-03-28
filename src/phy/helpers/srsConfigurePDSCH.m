%SRSCONFIGUREPDSCH Generates a physical shared channel object.
%   PDSCH = SRSCONFIGUREPDSCH(VARARGIN) returns a PDSCH object with the requested configuration.
%   The names of the input parameters are assumed to be coinciding with those of the properties
%   of nrPDSCHConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPDSCHConfig and nrPDSCHDMRSConfig.

function pdsch = srsConfigurePDSCH(varargin)

    pdsch = nrPDSCHConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        switch(paramName)
            case 'DMRS'
                pdsch.DMRS = varargin{index};
            case 'NStartBWP'
                pdsch.NStartBWP = varargin{index};
            case 'NSizeBWP'
                pdsch.NSizeBWP = varargin{index};
            case 'NID'
                pdsch.NID = varargin{index};
            case 'RNTI'
                pdsch.RNTI = varargin{index};
            case 'ReservedRE'
                pdsch.ReservedRE = varargin{index};
            case 'Modulation'
                pdsch.Modulation = varargin{index};
            case 'NumLayers'
                pdsch.NumLayers = varargin{index};
            case 'MappingType'
                pdsch.MappingType = varargin{index};
            case 'SymbolAllocation'
                pdsch.SymbolAllocation = varargin{index};
            case 'PRBSet'
                pdsch.PRBSet = varargin{index};
        end
    end

end
