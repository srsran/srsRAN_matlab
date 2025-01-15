%srsGetModulation Returns the modulation scheme corresponding to a given Qm.
%   MODULATION = srsGetModulation(QM) returns the modulation scheme given a
%   specific modulation order QM (according to the 3GPP convention: i.e., the
%   number of bits per symbol).
%
%   [MODULATION, SRSMODULATION] = srsGetModulation(QM) also returns the
%   modulation scheme according to SRS convention.
%
%   Remark: Setting QM = 1 returns 'pi/2-BPSK', not plain 'BPSK'.

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

function [modulation, srsmodulation] = srsGetModulation(Qm)
    switch Qm
        case 1
            modulation = 'pi/2-BPSK';
            srsmodulation = 'PI_2_BPSK';
        case 2
            modulation = 'QPSK';
            srsmodulation = 'QPSK';
        case 4
            modulation = '16QAM';
            srsmodulation = 'QAM16';
        case 6
            modulation = '64QAM';
            srsmodulation = 'QAM64';
        case 8
            modulation = '256QAM';
            srsmodulation = 'QAM256';
        otherwise
            error('srsran_matlab:srsGetModulation', ...
                'The supported modulation orders are (1, 2, 4, 6, 8), provided %d', Qm);
    end

end
