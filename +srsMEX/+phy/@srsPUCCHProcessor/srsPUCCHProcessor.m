%srsPUCCHProcessor retrieves UCI messages from a PUCCH transmission.
%   User-friendly interface for processing a PUCCH transmission via the MEX static
%   method pucch_processor_mex, which calls srsRAN pucch_processor. The PUCCH format
%   can be either Format 1 or Format 2.
%
%   PROCESSOR = srsPUCCHProcessor creates the PUCCH processor object PROCESSOR.
%
%   srsPUCCHProcessor Methods:
%
%   step  - Processes a PUCCH transmission.
%
%   Step method syntax
%
%   UCI = step(OBJ, RXGRID, PUCCH, CARRIER, NAME, VALUE, NAME, VALUE, ...) recovers
%   the UCI messages from the PUCCH transmission in the resource grid
%   RXGRID. Input PUCCH is either an nrPUCCH1Config or an nrPUCCH2Config object containing
%   the configuration of the PUCCH transmission. Input CARRIER is an nrCarrierConfig object describing
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
%   See also nrPUCCHDecode, nrUCIDecode, nrPUCCH1Config, nrPUCCH2Config, nrCarrierConfig.

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

classdef srsPUCCHProcessor < matlab.System
    methods (Access = protected)
        function uci = stepImpl(obj, carrierConfig, pucchConfig, rxGrid, uciSizes)
            arguments
                obj                   (1, 1) srsMEX.phy.srsPUCCHProcessor
                carrierConfig         (1, 1) nrCarrierConfig
                pucchConfig           (1, 1)        {mustBeA(pucchConfig, ["nrPUCCH1Config", "nrPUCCH2Config"])}
                rxGrid            (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
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

            numRxPorts = 1;
            if (numel(gridDims) == 3)
                numRxPorts = gridDims(3);
            end

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

            nid = carrierConfig.NCellID;

            if isa(pucchConfig, 'nrPUCCH1Config')
                if ~isempty(pucchConfig.HoppingID)
                    nid = pucchConfig.HoppingID;
                end
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
                    'NumHARQAck', uciSizes.NumHARQAck, ...
                    'InitialCyclicShift', pucchConfig.InitialCyclicShift, ...
                    'OCCI', pucchConfig.OCCI, ...
                    'NumPRBs', [], ...      only PUCCH F2
                    'RNTI', [], ...         only PUCCH F2
                    'NID0', [], ...         only PUCCH F2
                    'NumSR', [], ...        only PUCCH F2
                    'NumCSIPart1', [], ...  only PUCCH F2
                    'NumCSIPart2', [] ...   only PUCCH F2
                    );
            else
                if ~isempty(pucchConfig.NID)
                    nid = pucchConfig.NID;
                end

                mexConfig = struct(...
                    'Format', 2, ...
                    'SubcarrierSpacing', carrierConfig.SubcarrierSpacing, ...
                    'NSlot', mod(carrierConfig.NSlot, carrierConfig.SlotsPerFrame), ...
                    'CP', carrierConfig.CyclicPrefix, ...
                    'NRxPorts', numRxPorts, ...
                    'NSizeBWP', nSizeBWP, ...
                    'NStartBWP', nStartBWP, ...
                    'StartPRB', pucchConfig.PRBSet(1), ...
                    'SecondHopStartPRB', secondHop, ...
                    'NumPRBs', numel(pucchConfig.PRBSet), ...
                    'StartSymbolIndex', pucchConfig.SymbolAllocation(1), ...
                    'NumOFDMSymbols', pucchConfig.SymbolAllocation(2), ...
                    'RNTI', pucchConfig.RNTI, ...
                    'NID', nid, ...
                    'NID0', pucchConfig.NID0, ...
                    'NumHARQAck', uciSizes.NumHARQAck, ...
                    'NumSR', uciSizes.NumSR, ...
                    'NumCSIPart1', uciSizes.NumCSIPart1, ...
                    'NumCSIPart2', uciSizes.NumCSIPart2, ...
                    'InitialCyclicShift', [], ...  only PUCCH F1
                    'OCCI', [] ...                 only PUCCH F1
                    );
            end

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
