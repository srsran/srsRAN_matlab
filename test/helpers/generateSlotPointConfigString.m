%GENERATESLOTPOINTCONFIGSTRING Generates a new 'slot_point' configuration string.
%   OUTPUTSTRING = GENERATESLOTPOINTCONFIGSTRING(NUMEROLOGY, NFRAME, NSLOT, SLOTSPERSUBFRAME)
%   generates a configuration string OUTPUTSTRING for to the 'slot_point' class.

function outputString = generateSlotPointConfigString(numerology, NFrame, NSlot, slotsPerSubframe)

    outputString = sprintf('%d, %d, %d, %d', numerology, NFrame, floor(NSlot / slotsPerSubframe), rem(NSlot, slotsPerSubframe));

end
