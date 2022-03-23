%SRSGETUNIQUESYMBOLSINDICES Puts all unique symbol and indices pairs of a cell in vector format.
%   [SYMBOLVECTOR, SYMBOLINDICESVECTOR] = SRSGETUNIQUESYMBOLSINDICES(SYMBOLS, SYMBOLINDICES)
%   returns a vector with complex symbols SYMBOLVECTOR and a vector with the relate indices with

function [symbolVector, symbolIndicesVector] = srsGetUniqueSymbolsIndices(symbols, symbolIndices)

    % initialize the output vectors
    symbolVector = zeros(1,1);
    symbolIndicesVector = zeros(1,3);

    % find the number of sets of symbols and indices
    nofSets = size(symbols);
    tmpVector = zeros(1,3);
    nofAddedValues = 0;
    for setIdx = 1:nofSets(1)
        symbolSet = symbols{setIdx};
        indicesSet = symbolIndices{setIdx};

        % find the size of each set
        [nofSymbols, nofSubsets] = size(symbolSet);
        for subsetIdx = 1:nofSubsets
            symbolSubset = symbolSet(:, subsetIdx);
            indicesSubset = indicesSet(:, :, subsetIdx);

            % check if the current symbol is already included in the output vector
            for symbolIx = 1:nofSymbols
                tmpVector(:) = indicesSubset(symbolIx, :);
                valueNotInVector = true;
                if nofAddedValues > 0
                    for tmpIndex = 1:nofAddedValues
                        if isequal(tmpVector(:), symbolIndicesVector(tmpIndex, :).')
                            valueNotInVector = false;
                        end
                    end
                end

                % add a new unique value to the output vectors
                if valueNotInVector
                  nofAddedValues = nofAddedValues + 1;
                  symbolVector(nofAddedValues, 1) = symbolSubset(symbolIx);
                  symbolIndicesVector(nofAddedValues, :) = tmpVector(:);
                end
            end
        end
    end
end
