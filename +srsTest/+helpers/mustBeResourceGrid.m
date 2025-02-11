%mustBeResourceGrid Validate that value is a resource grid.
%   mustBeResourceGrid(A) throws an error if A is not a valid resource grid, i.e.
%   a 2- or 3-dimensional, complex-valued array with
%      - a number of rows that is divisible by 12 (there are 12 RE per RB);
%      - 14 columns (that is, OFDM symbols per slot);
%      - the third dimension should be of maximum size 4 (maximum supported number
%        of receive antenna ports).
%   MATLAB calls isnumeric and isreal to determine if A has the proper data type.
%
%   mustBeResourceGrid(A, Multilayer=1) accepts 4-dimensional arrays for checking
%   resource grid-like data generated by the channel estimator. Dimensions 1-to-3
%   must satisfy the same assumptions as above, dimension 4 must not be larger than
%   dimension 3 (cannot have more Tx layers than Rx ports).
%
%   See also isnumeric, isreal.

%   Copyright 2021-2025 Software Radio Systems Limited
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

function mustBeResourceGrid(a, options)
    arguments
        a
        options.MultiLayer logical = false
    end

    % Check that the data type is correct.
    if ~isnumeric(a) || isreal(a)
        eidType = 'mustBeResourceGrid:wrongDataType';
        msgType = sprintf('The resuorce grid should be filled with complex-valued values.');
        throwAsCaller(MException(eidType, msgType));
    end

    dims = size(a);

    if (numel(dims) > 4)
        eidType = 'mustBeResourceGrid:wrongNumberDimensions';
        msgType = sprintf('The resuorce grid should have at most 4 dimensions, given %d.', numel(dims));
        throwAsCaller(MException(eidType, msgType));
    end

    if (~options.MultiLayer && ((numel(dims) > 3) || (numel(dims) < 2)))
        eidType = 'mustBeResourceGrid:wrongNumberDimensions';
        msgType = sprintf('Without multilayer, the resuorce grid should have either 2 or 3 dimensions, given %d.', numel(dims));
        throwAsCaller(MException(eidType, msgType));
    end

    % Check number of OFDM symbols (columns).
    if dims(2) ~= 14
        eidType = 'mustBeResourceGrid:wrongNumberOFDMSymbols';
        msgType = sprintf('The resuorce grid should have 14 OFDM symbols (columns), given %d.', dims(2));
        throwAsCaller(MException(eidType, msgType));
    end

    % Check number of REs (rows).
    if mod(dims(1), 12) ~= 0
        eidType = 'mustBeResourceGrid:wrongNumberREs';
        msgType = sprintf(['The number of REs per symbol in the resuorce grid ', ...
            'should be a multiple of 12, given %d.'], dims(1));
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the number of ports is at most 4.
    if (numel(dims) >= 3)
        if (dims(3) > 4)
            eidType = 'mustBeResourceGrid:wrongNumberRxPorts';
            msgType = sprintf('The maximum supported number of Rx ports is 4, given %d.', dims(3));
            throwAsCaller(MException(eidType, msgType));
        end

        if (options.MultiLayer && (numel(dims) == 4))
            % Check the number of layers is at most 2.
            if (dims(4) > 2)
                eidType = 'mustBeResourceGrid:wrongNumberTxLayers';
                msgType = sprintf('The maximum supported number of Tx layers is 2, given %d.', dims(4));
                throwAsCaller(MException(eidType, msgType));
            end

            % Check the number of Rx antennas is not smaller than the number of Tx layers.
            if (dims(4) > dims(3))
                eidType = 'mustBeResourceGrid:TxLayersRxAntennasMismatch';
                msgType = sprintf(['The number of Rx antennas should not be smaller than ', ...
                    'the number of Tx layers, given %d and %d.'], dims(3), dims(4));
                throwAsCaller(MException(eidType, msgType));
            end
        end
    end

end
