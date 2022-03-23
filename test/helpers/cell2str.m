function [str_out] = cell2str(arg)
    mat = cell2mat(arg);

    if iscellstr(arg)
        str_out = mat;
    elseif length(mat) == 1
        str_out = num2str(mat);
    else
        str_out = ['{', array2str(mat), '}'];
    end
end