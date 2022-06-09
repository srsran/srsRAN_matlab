%srsSSBgetFirstSymbolIndex Calculates the position of the first SS/PBCH subcarrier.
%   SSBFIRSTSUBCARRIERINDEX = srsSSBgetFirstSubcarrierIndex(NUMEROLOGY, POINTAOFFSET, SSBOFFSET)
%   returns a subcarrier index SSBFIRSTSUBCARRIERINDEX, given a subcarrier spacing NUMEROLOGY,
%   a bottom grid value POINTAOFFSET and an SSB offset SSBOFFSET. Note that
%   SSBFIRSTSUBCARRIERINDEX is relative to POINTAOFFSET.

function SSBfirstSubcarrierIndex = srsSSBgetFirstSubcarrierIndex(numerology, pointAoffset, SSBoffset)

  NRE = 12; % number of RE per RB
  SSBfirstSubcarrierIndex = pointAoffset * NRE + (SSBoffset / (2 .^ numerology));

end
