%GENERATESLOTPOINTCONFIGSTRING:
%  Function generating a configuration string for the 'slot_point' class.
%
%  Call details:
%    OUTPUTSTRING = GENERATESLOTPOINTCONFIGSTRING(NUMEROLOGY, NFRAME, NSLOT, SLOTSPERSUBFRAME) receives the parameters
%      * double numerology       - defines the subcarrier spacing
%      * double NFrame           - system frame number
%      * double NSlot            - slot number
%      * double SLOTSPERSUBFRAME - number of slots per subframe
%    and returns
%      * string OUTPUTSTRING - configuration string for the 'slot_point' class

function outputString = generateSlotPointConfigString(numerology, NFrame, NSlot, slotsPerSubframe)

    outputString = sprintf('%d, %d, %d, %d', numerology, NFrame, floor(NSlot / slotsPerSubframe), rem(NSlot, slotsPerSubframe));

end
