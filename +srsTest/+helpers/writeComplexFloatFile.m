%WRITECOMPLEXFLOATFILE:
%  Function generating a new binary file containing a set of input data values, formatted to match
%    the 'file_vector<cf_t>' object used by the SRS gNB.
%
%  Call details:
%    WRITECOMPLEXFLOATFILE(FILENAME, DATA) receives the input parameters
%        * string FILENAME   - name of the file to be generated
%        * float array DATA  - set of data values to be written

function writeComplexFloatFile(filename, data)
    fileID = fopen(filename, 'w');
    dataLength = length(data);
    for idx = 1:dataLength
        fwrite(fileID, real(data(idx)), 'float32');
        fwrite(fileID, imag(data(idx)), 'float32');
    end
    fclose(fileID);
end
