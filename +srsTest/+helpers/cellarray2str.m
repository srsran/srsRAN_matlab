%CELLARRAY2STR Converts any cell array type into a string.
%   OUTPUTSTRING = CELLARRAY2STR(ARG) converts the input INPUTCELLARRAY 
%   into its character representation OUTPUTSTRING.
%    ISSTRUCT argument defines whether to use curly brackets wrapping OUTPUTSTRING

function [outputString] = cellarray2str(inputCellArray, isStruct)
    if isStruct
        outputString = '{';
    else
        outputString = '';
    end

    for arg = inputCellArray(1:end-1)
        outputString = [outputString, cell2str(arg), ', '];
    end

    outputString = [outputString, cell2str(inputCellArray(end))];
    if isStruct
        outputString = [outputString, '}'];
    end
end