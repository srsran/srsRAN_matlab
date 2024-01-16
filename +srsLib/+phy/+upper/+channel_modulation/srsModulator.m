%srsModulator Generation of modulated symbols from an input bit array.
%   MODULATEDSYMBOLS = srsModulator(CW, SCHEME)
%   modulates the input bit sequence accordig to the requested SCHEME
%   and returns the complex symbols MODULATEDSYMBOLS.
%
%   See also nrPBCHDMRS, nrPBCHDMRSIndices.

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

function modulatedSymbols = srsModulator(cw, scheme)
    modulatedSymbols = nrSymbolModulate(cw, scheme, 'OutputDataType', 'single');
end
