%symbolAllocationMask2string Generates a new OFDM symbol allocation bitmask string.
%   OUTPUTSTRING = symbolAllocationMask2string(SYMBOLINDICESVECTOR)
%   generates a symbol bitmask allocation string OUTPUTSTRING from a vector of indices
%   SYMBOLINDICESVECTOR.

function outputString = symbolAllocationMask2string(symbolIndicesVector)
    import srsTest.helpers.cellarray2str
    symbolAllocation = zeros(14, 1); % maximum possible number of symbols
    for symbolIndex = symbolIndicesVector(:, 2)
      symbolAllocation(symbolIndex + 1) = 1;
    end
    outputString = cellarray2str({symbolAllocation}, false);

end
