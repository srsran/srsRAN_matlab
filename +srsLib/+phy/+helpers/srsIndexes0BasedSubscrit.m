%srsIndexes0BasedSubscrit Converts index representation.
%   The absolute 1-based resource grid index representation comprises a
%   single index per resource element. It starts at 1 for the first
%   subcarrier of the first symbol and the first port. It increases with
%   subcarrier, symbol and port.
%
%   The 0-based subscript index representation comprises three indexes per
%   resource element. The indices correspond to subcarrier, symbol and
%   port. These start at 0 for the first subcarrier, symbol and port.
%
%   [OUTPUT] = srsIndexes0BasedSubscrit(INPUT, NSUBC, NSYMB)
%
%   INPUT is the list of absolute 1-based indexes, NSUBC is the number of
%   the resource grid subcarriers and NSYMB is the nymber of symbols in the
%   slot. 

%   Copyright 2021-2023 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

function output = srsIndexes0BasedSubscrit(input, nSubC, nSymb)
    % Initialise output memory.
    output = repmat(input, 1, 3);

    % Convert to 0based.
    indexes = output(:, 1) - 1;

    % Calculate subcarrier indexes.
    output(:, 1) = rem(indexes, nSubC);

    % Subtract the remainder from previous operation to avoid rounding up.
    indexes = (indexes - output(:, 1)) / nSubC;

    % Calculate the symbol indexes.
    output(:, 2) = rem(indexes, nSymb);

    % Subtract the remainder from previous operation to avoid rounding up.
    indexes = (indexes - output(:, 2)) / nSymb;

    % Calculate the port indexes.
    output(:, 3) = indexes;
end
