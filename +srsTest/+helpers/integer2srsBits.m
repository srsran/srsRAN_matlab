%integer2srsBits Convert a nonnegative integer to an SRSGNB amount of bits.
%   B = integer2srsBits(I) converts the nonnegative integer I to an initialization
%   string of a "srsgnb::units::bits" variable containing I bits.
function bitString = integer2srsBits(int)
    arguments
        int (1, 1) double {mustBeInteger, mustBeNonnegative}
    end

    bitString = sprintf('units::bits(%d)', int);
end
