%CELLARRAY2STR Converts any cell array type into a string.
%   OUTPUTSTRING = CELLARRAY2STR(ARG) converts the input INPUTCELLARRAY 
%   into its character representation OUTPUTSTRING.

function [outputString] = cellarray2str(inputCellArray)
outputString = '{';

for arg = inputCellArray(1:end-1)
    outputString = [outputString, cell2str(arg), ', '];
end

outputString = [outputString, cell2str(inputCellArray(end)), '}'];

end