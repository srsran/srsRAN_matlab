%clipboard Overloads MATLAB clipboard function.
%   clipboard('', STUFF) stores the content of STUFF in an internal register.
%
%   STR =clipboard('paste') sets variable STR to the content of the internal
%   register (see above).
%
%   Example:
%
%      % Simulate copy-pasting from a system application to a variable.
%      % Store a string - simulates the copy step.
%      clipboard('', 'hello');
%      % Now simulate the pasting of the clipboard content into a variable.
%      greeting = clipboard('past');    % Now greeting is 'hello'.
%
%   See also <a href="matlab:doc clipboard">input</a>.

%   Copyright 2021-2023 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

function str = clipboard(cmd, stuff)
    persistent LOG;

    if nargin == 2
        LOG = stuff;
    elseif strcmp(cmd, 'paste')
        str = LOG;
    else
        error('Operation not allowed.');
    end
end
