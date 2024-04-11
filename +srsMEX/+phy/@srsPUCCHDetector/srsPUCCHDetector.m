%srsPUCCHDetector detects a PUCCH Format 1 transmission from complex symbols.
%   User-friendly interface for detecting a PUCCH Format 1 transmission via the MEX static
%   method pucch_detector_mex, which calls srsRAN pucch_detector.
%
%   DETECTOR = srsPUCCHDetector creates the PUCCH detector object DETECTOR.
%
%   srsPUCCHDetector Methods:
%
%   step - Detects a PUCCH Format 1 transmission.
%
%   Step method syntax
%
%   UCI = step(OBJ, CARRIER, PUCCH, NUMHARQACK, RXGRID, CHEST, NOISEVAR) recovers
%   the UCI messages from the PUCCH transmission in the resource grid RXGRID.
%   Input CARRIER is an nrCarrierConfig object describing the carrier configuration
%   (the only used fields are SubcarrierSpacing, NSlot, and CyclicPrefix). Input
%   PUCCH is an nrPUCCH1Config object containing the configuration of the
%   PUCCH transmission. NUMHARQACK is the expected number of HARQ-ACK bits.
%   CHEST contains the estimated channel coefficients (same format as RXGRID).
%   NOISEVAR contains the estimated noise variance.
%
%   The output UCI is a structure with fields:
%
%   'isValid'         - Boolean flag: true if the PUCCH transmission was processed correctly.
%   'HARQAckPayload'  - Column array of HARQ ACK bits (possibly empty).
%   'SRPayload'       - SR bit (possibly empty).
%
%   See also nrPUCCHDecode, nrPUCCH1Config, nrCarrierConfig.

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

classdef srsPUCCHDetector < matlab.System
    methods (Access = protected)
        function uci = stepImpl(obj, carrierConfig, pucchConfig, nHARQAck, rxGrid, ...
                chEstimates, noiseVars)
            arguments
                obj                   (1, 1) srsMEX.phy.srsPUCCHDetector
                carrierConfig         (1, 1) nrCarrierConfig
                pucchConfig           (1, 1) nrPUCCH1Config
                nHARQAck              (1, 1) double {mustBeMember(nHARQAck, 0:2)}
                rxGrid            (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
                chEstimates       (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
                noiseVars                    double {mustBeVector, mustBeNonnegative}
            end

            assert(all(size(rxGrid) == size(chEstimates)), 'srsran_matlab:srsPUCCHDetector', ...
                'Resource grid and channel estimates sizes do not match.');

            numRxPorts = size(chEstimates, 3);

            assert(length(noiseVars) == numRxPorts, 'srsran_matlab:srsPUCCHDetector', ...
                'The number of noise variances does not match the number of Rx ports.');

            if ~isempty(pucchConfig.NSizeBWP)
                nSizeBWP = pucchConfig.NSizeBWP;
            else
                nSizeBWP = carrierConfig.NSizeGrid;
            end

            if ~isempty(pucchConfig.NStartBWP)
                nStartBWP = pucchConfig.NStartBWP;
            else
                nStartBWP = carrierConfig.NStartGrid;
            end

            secondHop = [];
            if ~strcmp(pucchConfig.FrequencyHopping, 'neither')
                secondHop = pucchConfig.SecondHopStartPRB;
            end

            nid = carrierConfig.NCellID;

            mexConfig = struct(...
                'Format', 1, ...
                'SubcarrierSpacing', carrierConfig.SubcarrierSpacing, ...
                'NSlot', mod(carrierConfig.NSlot, carrierConfig.SlotsPerFrame), ...
                'CP', carrierConfig.CyclicPrefix, ...
                'NRxPorts', numRxPorts, ...
                'NSizeBWP', nSizeBWP, ...
                'NStartBWP', nStartBWP, ...
                'StartPRB', pucchConfig.PRBSet(1), ...
                'SecondHopStartPRB', secondHop, ...
                'StartSymbolIndex', pucchConfig.SymbolAllocation(1), ...
                'NumOFDMSymbols', pucchConfig.SymbolAllocation(2), ...
                'NID', nid, ...
                'NumHARQAck', nHARQAck, ...
                'InitialCyclicShift', pucchConfig.InitialCyclicShift, ...
                'OCCI', pucchConfig.OCCI, ...
                'Beta', 1 ...
                );
            [status, harq, sr] = obj.pucch_detector_mex('step', single(rxGrid), single(chEstimates), ...
                single(noiseVars), mexConfig);

            isvalid = strcmp(status, 'valid');
            % Because of a MEX issue with returning empty arrays, we set the bit fields to 9 as a tag to
            % denote empty arrays.
            if (harq == 9)
                harq = int8.empty(0, 1);
            end
            if (sr == 9)
                sr = int8.empty(0, 1);
            end

            uci = struct('isValid', isvalid, 'HARQAckPayload', int8(harq), 'SRPayload', int8(sr));
        end % of function stepImpl(obj)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pucch_detector_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPUCCHProcessor < matlab.System
