%GENERATERBALLOCATIONMASKSTRING Generates a new RB allocation bitmask string.
%   OUTPUTSTRING = GENERATERBALLOCATIONMASKSTRING(STARTRB, SIZERB)
%   generates a RB bitmask allocation string OUTPUTSTRING where the allocated
%   RBs are those between STARTRB and (STARTRB + SIZERB-1).

function outputString = generateRBallocationMaskString(startRB, sizeRB)

    rbAllocation = zeros(275,1); % maximum possible RB size
    for index = 1:sizeRB
      rbAllocation(startRB + index) = 1;
    end
    outputString = array2str(rbAllocation);

end
