%srsSSBgetFirstSymbolIndex Calculates the position of the first subcarrier of the SS/PBCH
%   block relative to the bottom of the grid (pointA).
%   SSBFIRSTSUBCARRIERINDEX = srsSSBgetFirstSubcarrierIndex(NUMEROLOGY, POINTAOFFSET, SSBOFFSET)
%   returns a subcarrier index SSBFIRSTSUBCARRIERINDEX, given a subcarrier spacing NUMEROLOGY,
%   a bottom grid value POINTAOFFSET and an SSB offset SSBOFFSET.

function SSBfirstSubcarrierIndex = srsSSBgetFirstSubcarrierIndex(numerology, pointAoffset, SSBoffset)

  NRE = 12; % number of RE per RB
  SSBfirstSubcarrierIndex = pointAoffset * NRE + (SSBoffset / (2 .^ numerology));

end
