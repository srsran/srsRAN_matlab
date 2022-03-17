%WRITEUINT8FILE:
%  Function generating a new binary file containing a set of input data values, formatted to match
%    the 'file_vector<uint8_t>' structures used by the SRS gNB.
%
%  Call details:
%    WRITEUINT8FILE(FILENAME, DATA) receives the input parameters
%        * string FILENAME   - name of the file to be generated
%        * double array DATA - set of data values to be written

function writeUint8File(filename, data)
    fileID = fopen(filename, 'w');
    data_length = length(data);
    for idx = 1:data_length
        fwrite(fileID, data(idx), 'uint8');
    end
    fclose(fileID);
end
