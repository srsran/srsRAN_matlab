%srsSSBgetNumerology Indicates the numerology of a given SSB pattern.
%   NUMEROLOGY = srsSSBgetNumerology(SSBPATTERN) returns a subcarrier space NUMEROLOGY
%   given a SSB pattern SSBPATTERN.

function numerology = srsSSBgetNumerology(SSBpattern)

  numerology = 0; %default 15 kHz SCS
  switch SSBpattern
      case {'B', 'C'}
          numerology = 1; %30 kHz SCS
      case 'D'
          numerology = 3; %120 kHz SCS
      case '3'
          numerology = 4; %240 kHz SCS
  end

end
