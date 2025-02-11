%FormatDetailsF3 PUCCH Format 3 detail class for PUCCHPERF.
%
%   Helper class for the PUCCH performance simulator PUCCHPERF. It provides
%   metrics and method implementations specific for PUCCH Format 3 (most of them
%   are inherited from the FormatDetailsF2 class). The class is not meant to be
%   used outside PUCCHPERF.
%
%   FormatDetailsF3 properties (read-only):
%
%   SNRrange                  - SNR range in dB.
%   TotalBlocksCtr            - Counter of transmitted UCI messages.
%   BlockErrorRateMATLAB      - UCI block error rate (MATLAB case).
%   BlockErrorRateSRS         - UCI block error rate (SRS case).
%
%   See also PUCCHPERF, FormatDetailsF2.

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

classdef FormatDetailsF3 < FormatDetailsF2
    % This class is meant to be used only inside a PUCCHPERF simulation - restrict the constructor
    % and the methods that modify the properties.
    methods (Access = ?PUCCHPERF)
        function obj = FormatDetailsF3(nACKBits, nSRBits, nCSI1Bits, nCSI2Bits)
            % BLER tests work the same as detection tests.
            isdetection = true;
            obj@FormatDetailsF2(nACKBits, nSRBits, nCSI1Bits, nCSI2Bits, isdetection);
            obj.PUCCHFormat = 3;
        end % of function FormatDetailsF3(isdetection)
    end % of methods (Access = ?PUCCHPERF)

    methods (Static)
        function checkSymbolAllocation(symbolAllocation)
            if (symbolAllocation(2) < 4)
                error('PUCCH Format3 only allows the allocation of at least 4 OFDM symbols - requested %d.', symbolAllocation(2));
            end
        end
    end % of methods (Static)
end % of classdef FormatDetailsF3 < FormatDetailsF2

