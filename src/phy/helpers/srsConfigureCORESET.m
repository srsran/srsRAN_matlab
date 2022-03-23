%SRSCONFIGURECORESET:
%  Function generating a nrCORESETConfig object with the requested configuration.
%
%  Call details:
%    CORESET = SRSCONFIGURECORESET(FREQUENCYRESOURCES, DURATION, CCEREGMAPPING, REGBUNDLESIZE, INTERLEAVERSIZE) receives the parameters
%      * binary row vector FREQUENCYRESOURCES - bitmask indicating the frequency domain resource allocation
%      * double DURATION                      - CORESET duration
%      * string CCEREGMAPPING                 - CCE-to-REG mapping
%      * double REGBUNDLESIZE                 - size of REG bundles
%      * double INTERLEAVERSIZE               - interleaver size
%    and returns
%      * nrCORESET CORESET - configured coreset object

function coreset = srsConfigureCORESET(frequencyResources, duration, CCEREGMapping, REGBundleSize, interleaverSize)

    coreset = nrCORESETConfig;
    coreset.FrequencyResources = frequencyResources;
    coreset.Duration = duration;
    coreset.CCEREGMapping = CCEREGMapping;
    coreset.REGBundleSize = REGBundleSize;
    coreset.InterleaverSize = interleaverSize;

end
