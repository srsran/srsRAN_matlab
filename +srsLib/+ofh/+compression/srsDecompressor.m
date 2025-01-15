%srsDecompressor Generation of a complex array from compressed input IQ data.
%   IQDATA = srsCompressor(CIQDATA, CPARAM, METHOD, CIQWIDTH)
%   decompresses the input compressed IQ data CIQDATA accordig to the
%   compression parameters for each PRB in CPARAM, the requested METHOD, 
%   and input bit width CIQWIDTH and returns the IQ samples in IQDATA.
%
%   See also nrORANBlockDeompress.

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

function iqData = srsDecompressor(cIQData, cParam, method, cIQwidth)
    iqData = nrORANBlockDecompress(cIQData, cParam, method, cIQwidth, 16);
end
