%matlab2srsCyclicPrefix Generates a Cyclic Prefix string.
%   CYCLICPREFIXSTR = matlab2srsCyclicPrefix(CYCLICPREFIX) returns a
%   CYCLICPREFIXSTR string that can be used to specify the Cyclic Prefix in
%   the test header files. CYCLICPREFIX must be in the format specified by 
%   nrCarrierConfig.
%
%   See also nrCarrierConfig.CyclicPrefix.

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

function CyclicPrefixStr = matlab2srsCyclicPrefix(CyclicPrefix)
    CyclicPrefixStr = 'cyclic_prefix::';
    if (strcmp(CyclicPrefix, 'normal'))
        CyclicPrefixStr = [CyclicPrefixStr  'NORMAL'];
    elseif (strcmp(CyclicPrefix, 'extended'))
        CyclicPrefixStr = [CyclicPrefixStr  'EXTENDED'];
    else
        error('matlab2srsCP:InvalidCP', 'Invalid CP type.');
    end
