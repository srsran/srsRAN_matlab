%writeComplexFloatFile Writes complex symbols to a binary file.
%   writeComplexFloatFile(FILENAME, DATA) generates a new binary file FILENAME
%    containing a set of complex symbols, formatted to match the 'file_vector<cf_t>'
%    object used by the SRS gNB.

function writeComplexFloatFile(filename, data)
    fileID = fopen(filename, 'w');
    for value = data
        fwrite(fileID, real(value), 'float32');
        fwrite(fileID, imag(value), 'float32');
    end
    fclose(fileID);
end
