%writeResourceGridEntryFile Writes resource grid symbols to a binary file.
%   writeResourceGridEntryFile(FILENAME, DATA, INDICES) generates a new binary
%   file FILENAME containing a set of complex symbols and its related indices,
%   formatted to match the 'file_vector<resource_grid_spy::entry_t>' structures
%   used by the SRSGNB.

function writeResourceGridEntryFile(filename, data, indices)
    fileID = fopen(filename, 'w');
    data = data(:);
    dataLength = length(data);
    for idx = 1:dataLength
        fwrite(fileID, indices(idx, 3), 'uint8');
        fwrite(fileID, indices(idx, 2), 'uint8');
        fwrite(fileID, indices(idx, 1), 'uint16');
        fwrite(fileID, real(data(idx)), 'float');
        fwrite(fileID, imag(data(idx)), 'float');
    end
    fclose(fileID);
end
