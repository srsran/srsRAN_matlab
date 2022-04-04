%cell2str Converts an any cell type value into a string.
%   OUTPUTSTRING = cell2str(ARG) converts the input INPUTCELL into its
%   character representation OUTPUTSTRING.

function [outoutString] = cell2str(inputCell)
    import srsTest.helpers.array2str

    mat = cell2mat(inputCell);

    if isstring(inputCell) || iscellstr(inputCell)
        outoutString = mat;
    elseif length(mat) == 1
        outoutString = num2str(mat);
    else
        outoutString = ['{', array2str(mat), '}'];
    end
end
