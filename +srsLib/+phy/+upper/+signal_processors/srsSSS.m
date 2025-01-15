%srsSSS Secondary synchronization signal.
%   [SSSSYMBOLS, SSSINDICES] = srsSSS(NCELLID) generates the SSS for a
%   given physical cell ID NCELLID and returns the BPSK modulated symbols
%   SSSSYMBOLS as well as a column vector of RE indices.
%
%   See also nrSSS and nrSSSIndices.

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

function [SSSsymbols, SSSindices] = srsSSS(NCellID)

    SSSsymbols = nrSSS(NCellID);
    SSSindices = nrSSSIndices('IndexStyle', 'subscript', 'IndexBase', '0based');

end
