function logicString = logical2str(input)
%logical2str Convert logical to character representation
%   T = logical2str(X) converts the logical X into its character representation
%   ('false' or 'true'). If X is a number, then T is the character representation
%   of X > 0.

    strings = {'false', 'true'};
    logicString = strings{1 + (input > 0)};
