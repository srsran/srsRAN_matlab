%readComplexFloatFile Reads complex symbols from a binary file.
%   DATA = readComplexFloatFile(FILENAME) opens and reads an existent
%   binary file FILENAME containing a set of complex symbols, formatted to
%   match the 'file_vector<cf_t>' object used by the SRS gNB.

function data = readComplexFloatFile(filename)
    % Open file;
    fileID = fopen(filename, 'r');

    % Go to the end to estimate the number of single precission real
    % samples.
    fseek(fileID, 0, 'eof');
    NumSingleRealSamples = ftell(fileID) / 4;


    % Go back to the begining of the file and read the samples.
    fseek(fileID, 0, 'bof');
    singleRealData = fread(fileID, NumSingleRealSamples, 'float32');

    % Close the file.
    fclose(fileID);

    % Convert real data to complex.
    data = singleRealData(1:2:end) + 1i * singleRealData(2:2:end);
end
