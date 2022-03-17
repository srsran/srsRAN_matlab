%WRITERESOURCEGRIDENTRYFILE:
%  Function generating a new binary file containing a set of complex symbols and its related indices,
%    formatted to match the 'file_vector<resource_grid_spy::entry_t>' structures used by the SRS gNB.
%
%  Call details:
%    WRITE_RESOURCE_GRID_ENTRY_FILE(FILENAME,  DATA,INDICES) receives the input parameters
%        * string FILENAME           - name of the file to be generated
%        * complex double array DATA - set of data samples to be written
%        * double matrix INDICES     - 3xN matrix with the indices associated to each data sample,
%                                      each entry comprises [antenna port index, OFDM sybmol index, RE index]

function writeResourceGridEntryFile(filename, data, indices)
    fileID = fopen(filename, 'w');
    data_length = length(data);
    for idx = 1:data_length
        fwrite(fileID, indices(idx, 3), 'uint8');
        fwrite(fileID, indices(idx, 2), 'uint8');
        fwrite(fileID, indices(idx, 1), 'uint16');
        fwrite(fileID, real(data(idx)), 'float');
        fwrite(fileID, imag(data(idx)), 'float');
    end
    fclose(fileID);
end
