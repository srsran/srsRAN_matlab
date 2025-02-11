%input Overloads MATLAB input function.
%   input(~, ~, ANSWER) stores the content of ANSWER to be used as output for the
%   second form of the function (see below). ANSWER is a cell array containing all
%   the answer to successive calls of the input function.
%
%   RESULT = input(PROMPT) prompts for user input, as MATLAB's internal input
%   function, except that RESULT is taken from the previously recorded set of answers.
%
%   Example:
%
%      % Store a set of answers.
%      input('', '', {'hello', 34});
%      % Now simulate user interaction.
%      greeting = input('Common greeting: ');    % greeting is now 'hello'
%      fibo = input('Ninth Fibonacci number: '); % fibo is now 34
%
%   See also <a href="matlab:doc input">input</a>.

%   Copyright 2021-2025 Software Radio Systems Limited
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

function v = input(~, ~, answer)
    persistent ANSWER i

    if nargin == 3
        ANSWER = answer;
        i = 1;
    else
        v = ANSWER{i};
        i = i + 1;
    end
end
