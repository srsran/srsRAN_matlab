%cellarray2str Converts any cell array type into a string.
%   OUTPUTSTRING = cellarray2str(ARG) converts the input INPUTCELLARRAY
%   into its character representation OUTPUTSTRING.
%    ISSTRUCT argument defines whether to use curly brackets wrapping OUTPUTSTRING

function [outputString] = cellarray2str(inputCellArray, isStruct)
    import srsTest.helpers.cell2str
    if isStruct
        outputString = '{';
    else
        outputString = '';
    end

    addComa = false;
    for arg = inputCellArray(1:end-1)
        % manage subcells within the input cell
        if iscell(arg{1})
            import srsTest.helpers.cellarray2str
            tmp = cellarray2str({arg{1}{:}}, true);
            outputString = [outputString, tmp];
            addComa = true;
        else
            if addComa
                outputString = [outputString, ', '];
            end;
            outputString = [outputString, cell2str(arg), ', ']; %#ok<AGROW>
        end
    end

    outputString = [outputString, cell2str(inputCellArray(end))];
    if isStruct
        outputString = [outputString, '}'];
    end
end
