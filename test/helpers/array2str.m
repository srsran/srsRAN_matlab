%ARRAY2STR:
%  Function converting an array of numeric values to a string.
%
%  Call details:
%    OUTPUTSTRING = ARRAY2STR(INPUTARRAY, INPUTISFLOAT) receives the input parameters
%        * double array INPUTARRAY - set of numeric values
%        * boolean INPUTISFLOAT    - specifies if the input array has integer (false) or float (true) values
%    and returns
%        * string OUTPUTSTRING - string generated from the input numeric values

function outputString = array2str(inputArray, inputIsFloat)
    if any(mod(inputArray,1))>0
        fmt = '%.3f';
    else
        fmt = '%d';
    end
    inputArray = inputArray(:)'; % ensure it's a row
    outputString = [num2str(inputArray(1:end-1), [fmt, ', ']), ' ' num2str(inputArray(end), fmt)];
  end
