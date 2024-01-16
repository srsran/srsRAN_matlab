%srsPDCCHmodulator Physical Downlink Control channel modulator.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPDCCHmodulator(CW, CARRIER, PDCCH, NID, RNTI)
%   modulates the codeword CW using CARRIER and PDCCH objects and returns 
%   the complex symbols MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPDCCH, nrPDCCHResources.

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

function [modulatedSymbols, symbolIndices] = srsPDCCHmodulator(cw, carrier, pdcch, nID, rnti)
    % get modulated symbols and resource-element indices
    modulatedSymbols = nrPDCCH(cw, nID, rnti);
    symbolIndices = nrPDCCHResources(carrier, pdcch, ...
        'IndexStyle', 'subscript', 'IndexBase', '0based');
end
