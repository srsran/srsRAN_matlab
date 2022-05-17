%SRSINDEXES0BASEDSUBSCRIPT Generates a carrier object.
%   [OUTPUT] = srsIndexes0BasedSubscrit(INPUT, NSUBC, NSYMB) Converts 
%   absolute 1 based input indexes to 0based subscript style. Where INPUT
%   is list of absolute 1based indexes, NSUBC is the number of the resource
%   grid subcarriers and NSYMB is the nymber of symbol in the slot.
function [output] = srsIndexes0BasedSubscrit(input, nSubC, nSymb)
    % Initialise output memory
    output = repmat(input, 3);

    % Convert to 0based
    indexes = output(:,1) - 1;

    % Calculate subcarrier indexes
    output(:,1) = rem(indexes, nSubC);

    % Subtract the remainer from previous operation to avoid rounding up
    indexes = (indexes - output(:,1)) / nSubC;

    % Calculate the symbol indexes
    output(:,2) = rem(indexes, nSymb);

    % Subtract the remainer from previous operation to avoid rounding up
    indexes = (indexes - output(:,2)) / nSymb;

    % Calculate the port indexes
    output(:,3) = indexes;
end
