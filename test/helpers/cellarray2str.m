function [str_out] = cellarray2str(args)
str_out = '{';

for arg = args(1:end-1)
    str_out = [str_out, cell2str(arg), ', '];
end

str_out = [str_out, cell2str(args(end)), '}'];

end