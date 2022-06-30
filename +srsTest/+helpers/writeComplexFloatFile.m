%writeComplexFloatFile Writes complex symbols to a binary file.
%   writeComplexFloatFile(FILENAME, DATA) generates a new binary file FILENAME
%    containing a set of complex symbols, formatted to match the 'file_vector<cf_t>'
%    object used by the SRS gNB.

function writeComplexFloatFile(filename, data)
    % Convert data to single precission floating point with interleaved
    % real and imaginary parts.
    singleRealData = nan(1, 2 * numel(data), 'single');
    singleRealData(1:2:end) = real(data);
    singleRealData(2:2:end) = imag(data);

    % Open file, write data and close file.
    fileID = fopen(filename, 'w');
    fwrite(fileID, singleRealData, 'float32');
    fclose(fileID);
end
