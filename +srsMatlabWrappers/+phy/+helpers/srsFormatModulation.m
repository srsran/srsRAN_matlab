%srsFormatModulation Translates a MATLAB modulation string to the SRS nomenclature.
%   MODULATION = srsFormatModulation(MATLABMODULATION) returns the modulation scheme,
%   specified according to SRS nomenclature.

function modulation = srsFormatModulation(MATLABModulation)

    modulation = MATLABModulation;
    switch MATLABModulation
        case 'pi/2-BPSK'
            modulation = 'BPSK';
        case '16QAM'
            modulation = 'QAM16';
        case '64QAM'
            modulation = 'QAM64';
        case '256QAM'
            modulation = 'QAM256';
    end

end
