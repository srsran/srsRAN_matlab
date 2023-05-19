%srsGetBitsSymbol Returns the number of bits per modulation symbol.
%   NBITS = srsGetBitsSymbol(MODULATION) returns the number of bits per symbol
%   for the given MODULATION scheme. MODULATION is a character array identifying
%   a modulation scheme according to either MATLAB convention (i.e., 'BPSK',
%   'pi/2-BPSK', 'QPSK', '16QAM', '64QAM' or '256QAM') or SRS convention (i.e.,
%   'BPSK','PI_2_BPSK', 'QPSK', 'QAM16', 'QAM64' or 'QAM256').

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

function nBits = srsGetBitsSymbol(modulation)
    switch modulation
        case {'BPSK', 'pi/2-BPSK', 'PI_2_BPSK'}
            nBits = 1;
        case 'QPSK'
            nBits = 2;
        case {'16QAM', 'QAM16'}
            nBits = 4;
        case {'64QAM', 'QAM64'}
            nBits = 6;
        case {'256QAM', 'QAM256'}
            nBits = 8;
        otherwise
            error('srsran_matlab:srsGetBitsSymbol', 'Unknown modulation %s.', modulation);
    end
end
