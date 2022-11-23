%readComplexFloatFile Reads complex symbols from a binary file.
%   DATA = readComplexFloatFile(FILENAME) opens and reads an existent
%   binary file FILENAME containing a set of complex symbols, formatted to
%   match the 'file_vector<cf_t>' object used by the SRS gNB.

function data = readComplexFloatFile(filename)
    % Open the file.
    fileID = fopen(filename, 'r');

    % Read the samples.
    singleRealData = fread(fileID, 'float32');

    % Close the file.
    fclose(fileID);

    % Convert real data to complex.
    data = singleRealData(1:2:end) + 1i * singleRealData(2:2:end);
end
