%srsPDCCHdmrs Physical control channel demodulation reference signals.
%   [DMRSSYMBOLS, SYMBOLINDICES] = srsPDCCHdmrs(CARRIER, PDCCH)
%   modulates the demodulation reference signals and returns the complex symbols
%   DMRSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrCarrierConfig, nrPDCCHConfig and nrPDCCHSpace.

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

function [DMRSsymbols, symbolIndices] = srsPDCCHdmrs(carrier, pdcch)

    % no need of keeping track of the resource element indices of the PDCCH
    [~,DMRSsymbols,symbolIndices] = nrPDCCHSpace(carrier, pdcch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

end
