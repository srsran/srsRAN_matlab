%GENERATERBALLOCATIONMASKSTRING Generates a new RB allocation bitmask string.
%   OUTPUTSTRING = GENERATERBALLOCATIONMASKSTRING(SYMBOLINDICESVECTOR)
%   generates a RB bitmask allocation string OUTPUTSTRING from a vector of indices
%   SYMBOLINDICESVECTOR.

function outputString = generateRBallocationMaskString(symbolIndicesVector)

    rbAllocation = zeros(275, 1); % maximum possible RB size
    for index = 1:length(symbolIndicesVector)
      REidx = symbolIndicesVector(index, 1);
      rbIdx = floor(REidx / 12);
      rbAllocation(rbIdx + 1) = 1;
    end
    outputString = array2str(rbAllocation);

end
