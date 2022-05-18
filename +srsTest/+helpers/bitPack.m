%bitPack Simple data-packing function.
%   PACKEDDATA = bitPack(DATA) converts a set of unpacked uint8 input values
%   DATA (i.e., only the LSB of each uint8 carries useful data) into a set of
%   packed uint8 values PACKEDDATA (i.e., all 8 bits carry useful data).

function packedData = bitPack(data)
    packedData = reshape(double(data), 8, [])' * 2.^(7:-1:0)';
end
