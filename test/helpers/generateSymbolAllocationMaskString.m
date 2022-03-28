%GENERATESYMBOLALLOCATIONMASKSTRING Generates a new RB allocation bitmask string.
%   OUTPUTSTRING = GENERATESYMBOLALLOCATIONMASKSTRING(SYMBOLINDICESVECTOR)
%   generates a symbol bitmask allocation string OUTPUTSTRING from a vector of indices
%   SYMBOLINDICESVECTOR.

function outputString = generateSymbolAllocationMaskString(symbolIndicesVector)

    symbolAllocation = zeros(14, 1); % maximum possible number of symbols
    for symbolIndex = symbolIndicesVector(:, 2)
      symbolAllocation(symbolIndex + 1) = 1;
    end
    outputString = cellarray2str({symbolAllocation}, false);

end
