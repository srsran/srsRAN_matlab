%WRITERESOURCEGRIDENTRYFILE Writes resource grid symbols to a binary file.
%   WRITERESOURCEGRIDENTRYFILE(FILENAME, DATA, INDICES) generates a new binary
%   file FILENAME containing a set of complex symbols and its related indices,
%   formatted to match the 'file_vector<resource_grid_spy::entry_t>' structures
%   used by the SRSGNB.
%
%   Input parameters:
%      FILENAME  - Name of the generated file (string).
%      DATA      - Complex valued symbols (double array of size N).
%      INDICES   - 3xN matrix with the indices associated to each data sample.
%                  Each entry comprises [antenna port index, OFDM sybmol index, RE index].

function writeResourceGridEntryFile(filename, data, indices)
    fileID = fopen(filename, 'w');
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
