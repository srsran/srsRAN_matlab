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

    for arg = inputCellArray(1:end-1)
        % manage subcells within the input cell
        if iscell(arg{1})
            if isStruct
              outputString = [outputString, '{'];
            end
            for subArg = arg{1}(1:end-1)
              outputString = [outputString, cell2str(subArg), ', ']; %#ok<AGROW>
            end
            outputString = [outputString, cell2str(arg{1}(end))];
            if isStruct
                outputString = [outputString, '}, '];
            end
        else
            outputString = [outputString, cell2str(arg), ', ']; %#ok<AGROW>
        end
    end

    outputString = [outputString, cell2str(inputCellArray(end))];
    if isStruct
        outputString = [outputString, '}'];
    end
end
