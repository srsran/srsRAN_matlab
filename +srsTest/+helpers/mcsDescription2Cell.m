%mcsDescription2Cell Converts a modulation and target code rate to a cell
%describing the modulation code scheme.
%   MCSDESCR = mcsDescription2Cell(MODULATION, TARGETCODERATE) generates a
%   cell containing the modulation as string and a scaled target code rate.

%   Copyright 2021-2025 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

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

