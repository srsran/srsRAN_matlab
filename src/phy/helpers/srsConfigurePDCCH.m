%SRSCONFIGUREPDCCH Generates a physical control channel object.
%   PDCCH = SRSCONFIGUREPDCCH(VARARGIN) returns a PDCCH object with the requested configuration.
%   The names of the input parameters are assumed to coincide with those of the properties of
%   nrPDCCHConfig, with the exception of the suffix 'Loc' which is accepted.
%
%   See also nrPDCCHConfig.

function pdcch = srsConfigurePDCCH(varargin)

    pdcch = nrPDCCHConfig;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        switch(paramName)
            case 'CORESET'
                pdcch.CORESET = varargin{index};
            case 'NStartBWP'
                pdcch.NStartBWP = varargin{index};
            case 'NSizeBWP'
                pdcch.NSizeBWP = varargin{index};
            case 'RNTI'
                pdcch.RNTI = varargin{index};
            case 'AggregationLevel'
                pdcch.AggregationLevel = varargin{index};
            case 'SearchSpaceType'
                pdcch.SearchSpace.SearchSpaceType = varargin{index};
            case 'AllocatedCandidate'
                pdcch.AllocatedCandidate = varargin{index};
            case 'DMRSScramblingID'
                pdcch.DMRSScramblingID = varargin{index};
        end
    end

end
