%mcsDescription2Cell Converts a modulation and target code rate to a cell
%describing the modulation code scheme.
%   MCSDESCR = mcsDescription2Cell(MODULATION, TARGETCODERATE) generates a
%   cell containing the modulation as string and a scaled target code rate.
function mcsDescr = mcsDescription2Cell(modulation, targetCodeRate)

switch modulation
    case 'pi/2-BPSK'
        modString = 'modulation_scheme::PI_2_BPSK';
    case 'QPSK'
        modString = 'modulation_scheme::QPSK';
    case '16QAM'
        modString = 'modulation_scheme::QAM16';
    case '64QAM'
        modString = 'modulation_scheme::QAM64';
    case '256QAM'
        modString = 'modulation_scheme::QAM256';
end

mcsDescr = {modString, round(1024 * targetCodeRate, 1)};

end

