%writeResourceGridEntryFile Writes resource grid symbols to a binary file.
%   writeResourceGridEntryFile(FILENAME, DATA, INDICES) generates a new binary
%   file FILENAME containing a set of complex symbols and its related indices,
%   formatted to match the 'file_vector<resource_grid_spy::entry_t>' structures
%   used by the SRSGNB.

function writeResourceGridEntryFile(filename, data, indices)
    % Make sure data has a good format.
    data = data(:);

    % Flatten coordinates in a 32bit register.
    gridCoordinate = cast(indices(:, 3), 'uint32') ...
        + cast(indices(:, 2), 'uint32') * 2^8 + ...
        + cast(indices(:, 1), 'uint32') * 2^16;

    % Flatten data in a binary format·
    singleRealData = zeros(1, 3 * numel(data), 'uint32');
    singleRealData(1:3:end) = gridCoordinate;
    singleRealData(2:3:end) = typecast(single(real(data)), 'uint32');
    singleRealData(3:3:end) = typecast(single(imag(data)), 'uint32');

    % Write all data once.
    fileID = fopen(filename, 'w');
    fwrite(fileID, singleRealData, 'uint32');
    fclose(fileID);
end
