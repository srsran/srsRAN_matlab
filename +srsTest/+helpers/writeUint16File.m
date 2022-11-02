%writeUint16File Generates a new binary file with 'uint16_t' entries.
%   writeUint16File(FILENAME, DATA) writes the numeric array DATA to the binary
%   file FILENAME (pathname).

function writeUint16File(filename, data)
    fileID = fopen(filename, 'w');
    dataLength = length(data);
    for idx = 1:dataLength
        fwrite(fileID, data(idx), 'uint16');
    end
    fclose(fileID);
end
