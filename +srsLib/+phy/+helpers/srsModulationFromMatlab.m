%srsModulationFromMatlab Converts MATLAB modulation labels to SRS ones.
%   SRSMOD = srsModulationFromMatlab(MATLABMOD) returns the SRS modulation label
%   equivalent to the MATLAB modulation label MATLABMOD.
%
%   SRSMOD = srsModulationFromMatlab(MATLABMOD, 'full') prepends the modulation
%   label with the namespace 'modulation_scheme::'.
%
%   Examples
%      srsModulationFromMatlab('pi/2-BPSK')     % 'PI_2_BPSK'
%      srsModulationFromMatlab('QPSK', 'full')  % 'modulation_scheme::QPSK'

%   Copyright 2021-2024 Software Radio Systems Limited
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

function srsmod = srsModulationFromMatlab(matlabmod, fullname)
    switch matlabmod
        case 'pi/2-BPSK'
            srsmod = 'PI_2_BPSK';
        case '16QAM'
            srsmod = 'QAM16';
        case '64QAM'
            srsmod = 'QAM64';
        case '256QAM'
            srsmod = 'QAM256';
        case {'BPSK', 'QPSK'}
            srsmod = matlabmod;
        otherwise
            error('srsran_matlab:srsModulationFromMatlab', ...
                'Unknown modulation %s.', matlabmod);
    end

    if (nargin == 2) && strcmp(fullname, 'full')
        srsmod = ['modulation_scheme::', srsmod];
    end

end

