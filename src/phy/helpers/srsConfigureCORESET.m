%SRSCONFIGURECORESET Generates a control resource set object.
%   CORESET = SRSCONFIGURECORESET(FREQUENCYRESOURCES, DURATION, CCEREGMAPPING, ...
%       REGBUNDLESIZE, INTERLEAVERSIZE)
%   returns a CORESET object with the requested configuration.
%
%   See also nrCORESETConfig.

function coreset = srsConfigureCORESET(frequencyResources, duration, CCEREGMapping, REGBundleSize, interleaverSize)

    coreset = nrCORESETConfig;
    coreset.FrequencyResources = frequencyResources;
    coreset.Duration = duration;
    coreset.CCEREGMapping = CCEREGMapping;
    coreset.REGBundleSize = REGBundleSize;
    coreset.InterleaverSize = interleaverSize;

end
