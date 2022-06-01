%rbAllocationIndexes2String Generates RB allocation string object
%compatible with srsgnb.
%   OUTPUTSTRING = rbAllocationIndexes2String(VRBINDEXES)
%   generates an RB allocation string OUTPUTSTRING from a vector of VRB
%   indexes VRBINDEXES.
%
%   In order to save space the function detects if the allocation is
%   contiguous for a number of VRB. In that case, it constructs a type1
%   allocation with a start and end.
%
%   If the allocation is not contiguous, it constructs a custom allocation.
%
function [output] = rbAllocationIndexes2String(vrbIndexes)
firstRB = vrbIndexes(1);
lastRB = vrbIndexes(end);
countRB = lastRB - firstRB + 1;
if length(vrbIndexes) == countRB
    output = sprintf('rb_allocation::make_type1(%d, %d)', firstRB, ...
        countRB);
else
    output = ['rb_allocation::make_custom({', ...
        array2str(pdschConfig.PRBSet), '})'];
end

end

