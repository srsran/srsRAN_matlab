%matlab2srsCyclicPrefix Generates a Cyclic Prefix string.
%   CYCLICPREFIXSTR = matlab2srsCyclicPrefix(CYCLICPREFIX) returns a
%   CYCLICPREFIXSTR string that can be used to specify the Cyclic Prefix in
%   the test header files. CYCLICPREFIX must be in the format specified by 
%   nrCarrierConfig.
%
%   See also nrCarrierConfig.CyclicPrefix.

function CyclicPrefixStr = matlab2srsCyclicPrefix(CyclicPrefix)
    CyclicPrefixStr = 'cyclic_prefix::';
    if (strcmp(CyclicPrefix, 'normal'))
        CyclicPrefixStr = [CyclicPrefixStr  'NORMAL'];
    elseif (strcmp(CyclicPrefix, 'extended'))
        CyclicPrefixStr = [CyclicPrefixStr  'EXTENDED'];
    else
        error('matlab2srsCP:InvalidCP', 'Invalid CP type.');
    end
