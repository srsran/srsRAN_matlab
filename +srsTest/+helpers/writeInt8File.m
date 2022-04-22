%writeInt8File Generates a new binary file with 'int8_t' entries.
%   writeInt8File(FILENAME, DATA) writes the numeric array DATA to the binary
%   file FILENAME (pathname). The format matches the 'file_vector<int8_t>' object
%   used by SRSGNB.

function writeInt8File(filename, data)
    fileID = fopen(filename, 'w');
    fwrite(fileID, data, 'int8');
    fclose(fileID);
end
