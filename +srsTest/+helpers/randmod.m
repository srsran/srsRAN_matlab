%randmod Uniformly distributed random modulation points.
%   R = randmod(MOD, N) returns an N-by-N matrix containing pseudorandom points
%   uniformly drawn from the MOD constellation. MOD can be any of 'QPSK', '16QAM',
%   '64QAM' or '256QAM'.
%
%   R = randmod(MOD, [M, N, ...]) returns an M-by-N-by-... array of constellation
%   points.

%   Copyright 2021-2024 Software Radio Systems Limited
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

function x = randmod(mod, dims)

    switch mod
        case 'QPSK'
            n = 2;
            s = sqrt(2);
        case '16QAM'
            n = 4;
            s = sqrt(10);
        case '64QAM'
            n = 8;
            s = sqrt(42);
        case '256QAM'
            n = 16;
            s = sqrt(170);
        otherwise
            error('Unknown modulation %s.', mod);
    end

    x = ((randi(n, dims) - 1) * 2 - n + 1) + 1i * ((randi(n, dims) - 1) * 2 - n + 1);
    x = x / s;
end
