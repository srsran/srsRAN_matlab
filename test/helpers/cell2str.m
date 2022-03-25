%CELL2STR Converts an any cell type value into a string.
%   OUTPUTSTRING = CELL2STR(ARG) converts the input INPUTCELL into its 
%   character representation OUTPUTSTRING.

function [outoutString] = cell2str(inputCell)
    mat = cell2mat(inputCell);

    if iscellstr(inputCell)
        outoutString = mat;
    elseif length(mat) == 1
        outoutString = num2str(mat);
    else
        outoutString = ['{', array2str(mat), '}'];
    end
end