%srsConfigureULSCHEncoder Generates a physical uplink shared channel encoder object.
%   ULSCHENCODER = srsConfigureULSCHEncoder(VARARGIN) returns a ULSCH encoder object
%   with the requested configuration. The names of the input parameters are assumed to
%   coincide with those of the properties of nrULSCH, with the exception of the suffix
%   'Loc' which is accepted.
%
%   See also nrULSCH.

function ULSCHEncoder = srsConfigureULSCHEncoder(varargin)

    ULSCHEncoder = nrULSCH;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        ULSCHEncoder.(paramName) = varargin{index};
    end

end
