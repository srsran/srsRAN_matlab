%approxbf16 Approximates a brain floating point 16 conversion.
%   Y = approxbf16(X) mimicks the effect of converting vector X into the brain
%   floating point 16 (bfloat16) format and back to the original floating point
%   precision of X (either single or double). If X is a complex-valued vector,
%   its real and imaginary parts are approximated independently.
%
%   Example:
%      format long
%      Y = approxbf16(pi)
%      Y =
%        3.140625000000000
%
%      Y = approxbf16(single(pi))
%      Y =
%        3.1406250

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

function outbf16 = approxbf16(in)
    arguments
        in {mustBeFloat}
    end

    dims = size(in);

    inLong = in(:);
    if ~isreal(inLong)
        inLong = [real(inLong); imag(inLong)];
    end

    if isa(in, 'single')
        tmp = singlecase(inLong);
    else % if double
        tmp = doublecase(inLong);
    end

    if ~isreal(in)
        nn = numel(tmp) / 2;
        outbf16 = tmp(1:nn) + 1j * tmp(nn + 1:end);
    else
        outbf16 = tmp;
    end

    outbf16 = reshape(outbf16, dims);
end

% Only the 7 most significant bits of the fractional part are kept. The remainng
% bits (16 in the single-precision case and 45 in the double-precision case) are
% rounded off according to the "half to nearest even" method: when the removed
% part is exactly 0.5 (i.e., a single one followed by all zeros), we take the
% closest even value. In base-10 notation, this means that 2.5 is rounded to 2,
% while 3.5 is rounded to 4. All other values are rounded to the closest integer
% (e.g., 3.4 to 3 and 3.8 to 4).

function out = singlecase(inLong)
    inInt = typecast(inLong, 'uint32');
    inInt = inInt + uint32(0x7FFF) + bitand(bitshift(inInt, -16), 1);
    inInt = bitand(inInt, 0xFFFF0000);

    out = typecast(inInt, 'single');
end

function out = doublecase(inLong)
    inInt = typecast(inLong, 'uint64');
    inInt = inInt + uint64(0xFFFFFFFFFFF) + bitand(bitshift(inInt, -45), 1);
    inInt = bitand(inInt, 0xFFFFE00000000000);

    out = typecast(inInt, 'double');
end
