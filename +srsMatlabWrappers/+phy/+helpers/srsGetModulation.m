%srsGetModulation Returns the modulation scheme corresponding to a given Qm.
%   MODULATION = srsGetModulation(QM) returns the modulation scheme, specified as a
%   string, given a specific modulation order QM.

function modulation = srsGetModulation(Qm)

    modulation = '';

    switch Qm
        case 1
            modulation = 'pi/2-BPSK';
        case 2
            modulation = 'QPSK';
        case 4
            modulation = '16QAM';
        case 6
            modulation = '64QAM';
        case 8
            modulation = '256QAM';
    end

end
