%srsGetModulation Returns the modulation scheme corresponding to a given Qm.
%   MODULATION = srsGetModulation(QM) returns the modulation scheme given a
%   specific modulation order QM (according to the 3GPP convention: i.e., the
%   number of bits per symbol). Two different modulation strings are returned:
%   the first formatted as required by MATLAB, the second as defined by SRS.

function modulation = srsGetModulation(Qm)

    modulation = '';

    switch Qm
        case 1
            modulation = {'pi/2-BPSK', 'BPSK'};
        case 2
            modulation = {'QPSK', 'QPSK'};
        case 4
            modulation = {'16QAM', 'QAM16'};
        case 6
            modulation = {'64QAM', 'QAM64'};
        case 8
            modulation = {'256QAM', 'QAM256'};
    end

end
