%ARRAY2STR:
%  Function converting an array of numeric values to a string.
%
%  Call details:
%    OUTPUTSTRING = ARRAY2STR(INPUTARRAY) receives the input parameters
%        * double array INPUTARRAY - set of numeric values
%    and returns
%        * string OUTPUTSTRING - string generated from the input numeric values

function outputString = array2str(inputArray,inputIsFloat)
    if inputIsFloat
        fmt = '%.3f';
    else
        fmt = '%d';
    end
    inputArray = inputArray(:)'; % ensure it's a row
    outputString = [num2str(inputArray(1:end-1), [fmt, ', ']), ' ' num2str(inputArray(end), fmt)];
  end
