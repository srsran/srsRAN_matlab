%array2str Converts an array of numeric values to a string.
%   OUTPUTSTRING = array2str(INPUTARRAY) converts the numeric array INPUTARRAY
%   into its character representation OUTPUTSTRING.

function outputString = array2str(inputArray)
    if isempty(inputArray)
        outputString = '{}';
        return;
    end

    if any(mod(inputArray,1) > 0)
        fmt = '%.3f';
    else
        fmt = '%d';
    end
    inputArray = inputArray(:)'; % ensure it's a row
    outputString = [num2str(inputArray(1:end-1), [fmt, ', ']), ' ', num2str(inputArray(end), fmt)];
  end
