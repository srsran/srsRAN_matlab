%srsPDSCHmodulator Physical Downlink Shared Channel.
%   [MODULATEDSYMBOLS, SYMBOLINDICES] = srsPDSCHmodulator(CARRIER, PDSCH, CWS)
%   modulates up to two PDSCH codewords CWS and returns the complex symbols
%   MODULATEDSYMBOLS as well as a column vector of RE indices.
%
%   See also nrPDSCH, nrPDSCHIndices.

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

function [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws)
    modulatedSymbols = nrPDSCH(carrier, pdsch, cws);

    symbolIndices = nrPDSCHIndices(carrier, pdsch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
