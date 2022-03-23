%GENERATESLOTPOINTCONFIGSTRING:
%  Function generating a RB allocaton bitmask string.
%
%  Call details:
%    OUTPUTSTRING = GENERATESLOTPOINTCONFIGSTRING(NUMEROLOGY, NFRAME, NSLOT, SLOTSPERSUBFRAME) receives the parameters
%      * double STARTRB - index of the first allocated RB start of BWP resource grid relative to CRB 0
%      * double SIZERB  - number of allocated RBs
%    and returns
%      * string OUTPUTSTRING - RB allocation bitmask string

function outputString = generateRBallocationMaskString(startRB, sizeRB)

    rbAllocation = zeros(275,1); % maximum possible RB size
    for index = 1:sizeRB
      rbAllocation(startRB + index) = 1;
    end
    outputString = array2str(rbAllocation);

end
