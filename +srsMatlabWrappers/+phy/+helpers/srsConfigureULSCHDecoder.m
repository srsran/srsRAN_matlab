%srsConfigureULSCHDecoder Generates a physical uplink shared channel decoder object.
%   ULSCHDECODER = srsConfigureULSCHDecoder(VARARGIN) returns a ULSCH decoder object
%   with the requested configuration. The names of the input parameters are assumed to
%   coincide with those of the properties of nrULSCHDecoder, with the exception of the suffix
%   'Loc' which is accepted.
%
%   See also nrULSCHDecoder.

function ULSCHDecoder = srsConfigureULSCHDecoder(varargin)

    ULSCHDecoder = nrULSCHDecoder;
    nofInputParams = length(varargin);
    for index = 1:nofInputParams
        paramName = erase(inputname(index), 'Loc');
        ULSCHDecoder.(paramName) = varargin{index};
    end

end
