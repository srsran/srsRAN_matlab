% Returns the duration (in ms) of the CPs for one slot depending on the SCS.
function cpDurations = scs2cps(scs)
    if (scs == 15)
        cpDurations = [160 144 144 144 144 144 144 160 144 144 144 144 144 144];
    elseif (scs == 30)
        cpDurations = [160 144 144 144 144 144 144 144 144 144 144 144 144 144];
    end
    cpDurations = cpDurations / sum(cpDurations) / scs;
end
