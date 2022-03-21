%TRANSLATETOSIMULATORNAMING:
%  Function translating from SRS gNB naming convention to the one used by this simulator.
%
%  Call details:
%    SIMULATORNAME = TRANSLATETOSIMULATORNAMING(SRSPHYBLOCK) receives the input parameters
%        * string SRSPHYBLOCK - name of the PHY block in the SRS gNB implementation
%    and returns
%        * string SIMULATORNAME - name of the PHY block according to the simulator naming convention

function simulatorName = translateToSimulatorNaming(srsPHYblock)
    simulatorName = '';
    prevStringIndex = 0;
    stringIndices = strfind(srsPHYblock, '_');
    for stringIndex = stringIndices
        switch prevStringIndex
            case 0
                namePart = srsPHYblock(1:stringIndex-1);
                simulatorName = upper(namePart);
            case stringIndices(1)
                namePart = srsPHYblock(prevStringIndex+1:stringIndex-1);
                simulatorName = [simulatorName lower(namePart)];
             otherwise
                namePart = srsPHYblock(prevStringIndex+1:stringIndex-1);
                simulatorName = [simulatorName upper(namePart(1)) lower(namePart(2:end))];
        end
        prevStringIndex = stringIndex;
    end
    namePart = srsPHYblock(prevStringIndex+1:end);
    if prevStringIndex == stringIndices(1)
        simulatorName = [simulatorName lower(namePart)];
    else
        simulatorName = [simulatorName upper(namePart(1)) lower(namePart(2:end))];
    end
end
