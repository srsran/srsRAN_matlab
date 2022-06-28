%writeComplexFloatFile Writes complex symbols to a binary file.
%   writeComplexFloatFile(FILENAME, DATA) generates a new binary file FILENAME
%    containing a set of complex symbols, formatted to match the 'file_vector<cf_t>'
%    object used by the SRS gNB.

function writeComplexFloatFile(filename, data)
    fileID = fopen(filename, 'w');
    dataLength = length(data);

    re_data = real(data);
    im_data = imag(data);

    for idx = 1:dataLength
        fwrite(fileID, re_data(idx), 'float32');
        fwrite(fileID, im_data(idx), 'float32');
    end
    fclose(fileID);
end
