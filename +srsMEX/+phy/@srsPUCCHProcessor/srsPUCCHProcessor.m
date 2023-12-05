%srsPUCCHProcessor retrieves UCI messages from a PUCCH Format 2 transmission.
%   User-friendly interface for processing (channel estimation and equalization,
%   demodulation and decoding) a PUCCH Format 2 transmission via the MEX static
%   method pucch_processor_mex, which calls srsRAN pucch_processor.
%
%   PROCESSOR = srsPUCCHProcessor creates the PUCCH Format 2 processor object
%   PROCESSOR.
%
%   srsPUCCHProcessor Methods:
%
%   step  - Processes a PUCCH Format 2 transmission.
%
%   Step method syntax
%
%   UCI = step(OBJ, RXGRID, PUCCH, CARRIER, NAME, VALUE, NAME, VALUE, ...) recovers
%   the UCI messages from the PUCCH Format 2 transmission in the resource grid
%   RXGRID. Input PUCCH is an nrPUCCH2Config object containing the configuration
%   of the PUCCH transmission. Input CARRIER is an nrCarrierConfig object describing
%   the carrier configuration (the only used fields are SubcarrierSpacing, NSlot, and
%   CyclicPrefix). The Name-Value pairs are used to specify the length of the UCI
%   messages (default is 0 for all of them):
%
%   'NumHARQAck'   - Number of HARQ ACK bits (0...1706).
%   'NumSR'        - Number of SR bits (0...4).
%   'NumCSIPart1'  - Number of CSI Part 1 bits (0...1706).
%   'NumCSIPart2'  - Number of CSI Part 2 bits (0...1706).
%
%   The output UCI is a structure with fields:
%
%   'isValid'         - Boolean flag: true if the PUCCH transmission was processed correctly.
%   'HARQAckPayload'  - Column array of HARQ ACK bits (possibly empty).
%   'SRPayload'       - Column array of SR bits (possibly empty).
%   'CSI1Payload'     - Column array of CSI Part 1 bits (possibly empty).
%   'CSI2Payload'     - Column array of CSI Part 2 bits (possibly empty).
%
%   See also nrPUCCHDecode, nrUCIDecode, nrPUCCH2Config, nrCarrierConfig.

%   Copyright 2021-2023 Software Radio Systems Limited
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

classdef srsPUCCHProcessor < matlab.System
    methods (Access = protected)
        function uci = stepImpl(obj, rxGrid, pucchConfig, carrierConfig, uciSizes)
            arguments
                obj                   (1, 1) srsMEX.phy.srsPUCCHProcessor
                rxGrid            (:, 14, :) double {mustBeNumeric, mustBeResourceGrid}
                pucchConfig           (1, 1) nrPUCCH2Config
                carrierConfig         (1, 1) nrCarrierConfig
                uciSizes.NumHARQAck   (1, 1) double {mustBeNonnegative} = 0
                uciSizes.NumSR        (1, 1) double {mustBeNonnegative} = 0
                uciSizes.NumCSIPart1  (1, 1) double {mustBeNonnegative} = 0
                uciSizes.NumCSIPart2  (1, 1) double {mustBeNonnegative} = 0
            end

            gridDims = size(rxGrid);
            secondHop = [];
            if ~strcmp(pucchConfig.FrequencyHopping, 'neither')
                secondHop = pucchConfig.SecondHopStartPRB;
            end
            mexConfig = struct(...
                'SubcarrierSpacing', carrierConfig.SubcarrierSpacing, ...
                'NSlot', carrierConfig.NSlot, ...
                'CP', carrierConfig.CyclicPrefix, ...
                'NRxPorts', gridDims(3), ...
                'NSizeBWP', pucchConfig.NSizeBWP, ...
                'NStartBWP', pucchConfig.NStartBWP, ...
                'StartPRB', pucchConfig.PRBSet(1), ...
                'SecondHopStartPRB', secondHop, ...
                'NumPRBs', numel(pucchConfig.PRBSet), ...
                'StartSymbolIndex', pucchConfig.SymbolAllocation(1), ...
                'NumOFDMSymbols', pucchConfig.SymbolAllocation(2), ...
                'RNTI', pucchConfig.RNTI, ...
                'NID', pucchConfig.NID, ...
                'NID0', pucchConfig.NID0, ...
                'NumHARQAck', uciSizes.NumHARQAck, ...
                'NumSR', uciSizes.NumSR, ...
                'NumCSIPart1', uciSizes.NumCSIPart1, ...
                'NumCSIPart2', uciSizes.NumCSIPart2 ...
                );

            [status, harq, sr, csi1, csi2] = obj.pucch_processor_mex('step', single(rxGrid), mexConfig);

            isvalid = strcmp(status, 'valid');
            % Because of a MEX issue with returning empty arrays, we set the bit fields to 9 as a tag to
            % denote empty arrays.
            if (harq == 9)
                harq = int8.empty(0, 1);
            end
            if (sr == 9)
                sr = int8.empty(0, 1);
            end
            if (csi1 == 9)
                csi1 = int8.empty(0, 1);
            end
            if (csi2 == 9)
                csi2 = int8.empty(0, 1);
            end

            uci = struct('isValid', isvalid, 'HARQAckPayload', int8(harq), 'SRPayload', int8(sr), ...
                'CSI1Payload', int8(csi1), 'CSI2Payload', int8(csi2));
        end % of function [uci, csi] = stepImpl(obj, pucchConfig, carrierConfig)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pucch_processor_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPUCCHProcessor < matlab.System

function mustBeResourceGrid(a)
    dims = size(a);

    % Check number of OFDM symbols (columns).
    if dims(2) ~= 14
        eidType = 'mustBeResourceGrid:wrongNumberOFDMSymbols';
        msgType = sprintf('The resuorce grid should have 14 OFDM symbols (columns), given %d.', dims(2));
        throwAsCaller(MException(eidType, msgType));
    end

    % Check number of REs (rows).
    if mod(dims(1), 12) ~= 0
        eidType = 'mustBeResourceGrid:wrongNumberREs';
        msgType = sprintf(['The number of REs per symbol in the resuorce grid ', ...
            'should be a multiple of 12, given %d.'], dims(1));
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the number of ports is at most 4.
    if dims(3) > 4
        eidType = 'mustBeResourceGrid:wrongNumberRxPorts';
        msgType = sprintf('The maximum supported number of Rx ports is 4, given %d.', dims(3));
        throwAsCaller(MException(eidType, msgType));
    end
end
