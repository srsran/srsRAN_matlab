%WRITEUINT8FILE Generates a new binary file with 'uint8_t' entries.
%   WRITEUINT8FILE(FILENAME, DATA) writes the numeric array DATA to the binary
%   file FILENAME (pathname).

function writeUint8File(filename, data)
    fileID = fopen(filename, 'w');
    dataLength = length(data);
    for idx = 1:dataLength
        fwrite(fileID, data(idx), 'uint8');
    end
    fclose(fileID);
end