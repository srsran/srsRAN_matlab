%srsConfigureDLSCHEncoder Generates a physical downling shared channel encoder object.
%   DLSCHENCODER = srsConfigureDLSCHEncoder(VARARGIN) returns a DLSCH encoder object
%   with the requested configuration. The names of the input parameters are assumed to
%   coincide with those of the properties of nrDLSCH, with the exception of the suffix
%   'Loc' which is accepted.
%
%   See also nrDLSCH.

function DLSCHEncoder = srsConfigureDLSCHEncoder(varargin)

    DLSCHEncoder = nrDLSCH;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        switch(paramName)
            case 'MultipleHARQProcesses'
                DLSCHEncoder.MultipleHARQProcesses = varargin{index};
            case 'TargetCodeRate'
                DLSCHEncoder.TargetCodeRate = varargin{index};
            case 'LimitedBufferSize'
                DLSCHEncoder.LimitedBufferSize = varargin{index};
        end
    end

end
