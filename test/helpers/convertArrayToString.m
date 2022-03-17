% CONVERTARRAYTOSTRING:
%   Function converting an array of numeric values to a string.
%
%   Call details:
%     OUTPUTSTRING = CONVERTARRAYTOSTRING(INPUTARRAY) receives the input parameters
%         * double array INPUTARRAY - set of numeric values
%     and returns
%         * string OUTPUTSTRING - string generated from the input numeric values

function outputString = convertArrayToString(inputArray)
    outputString = '';
    for data_value = inputArray
        outputString = [outputString, sprintf('%d,', data_value)];
    end
    outputString = outputString(1:end-1);
end
