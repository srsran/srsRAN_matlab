%srsConfigureCSIRS Generates a Channel State Information Reference Signal object.
%   CSIRSCONFIG = srsConfigureCSIRS(VARARGIN) returns a CSIRS object with the requested configuration.
%   The names of the input parameters must coincide with those of the properties
%   of the nrCSIRSConfig object. If there are errors in the configuration, 
%   CSIRSCONFIG is returned empty.
%   
%   See also nrCSIRSConfig.

function CSIRSconfig = srsConfigureCSIRS(varargin)

    CSIRSconfig = nrCSIRSConfig;   
    try
        nofInputParams = length(varargin);
        for index = 1:nofInputParams
            paramName = inputname(index);
            CSIRSconfig.(paramName) = varargin{index};
        end
    catch
        CSIRSconfig = [];
    end
