%bitPack Packs the input data so that each byte contains 8 data bits.
%   PACKEDDATA = bitPack(DATA) packs in groups of eight the LSBs the
%   input uint8 DATA values.

function packedData = bitPack(data)
    packedData = reshape(data, 8, [])' * 2.^(7:-1:0)';  
end
