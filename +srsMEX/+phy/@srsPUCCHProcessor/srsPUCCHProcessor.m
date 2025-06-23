%srsPUCCHProcessor retrieves UCI messages from a PUCCH transmission.
%   User-friendly interface for processing a PUCCH transmission via the MEX static
%   method pucch_processor_mex, which calls srsRAN pucch_processor.
%
%   PROCESSOR = srsPUCCHProcessor creates the PUCCH processor object PROCESSOR.
%
%   srsPUCCHProcessor Methods:
%
%   step  - Processes a PUCCH transmission.
%
%   Step method syntax
%
%   UCI = step(OBJ, CARRIER, PUCCH, RXGRID, NAME, VALUE, NAME, VALUE, ...) recovers
%   the UCI messages from the PUCCH transmission in the resource grid RXGRID.
%   Input CARRIER is an nrCarrierConfig object describing the carrier configuration
%   (the only used fields are SubcarrierSpacing, NSlot, and CyclicPrefix). Input
%   PUCCH can be any nrPUCCHxConfig object (x = 0,...,4) containing the
%   configuration of the PUCCH transmission. The Name-Value pairs are used to
%   specify the length of the UCI messages (default is 0 for all of them):
%
%   'NumHARQAck'   - Number of HARQ ACK bits (0...1706).
%   'NumSR'        - Number of SR bits (0...4).
%   'NumCSIPart1'  - Number of CSI Part 1 bits (0...1706).
%   'NumCSIPart2'  - Number of CSI Part 2 bits (0...1706).
%   'MuxFormat1'   - A structure array with fields 'InitialCyclicShift', 'OCCI'
%                    and 'NumBits' specifying a list of multiplexed PUCCH Format 1
%                    transmissions. This input can only be present when PUCCH is
%                    an nrPUCCH1Config object, and it overwrites the 'InitialCyclicShift'
%                    and the 'OCCI' provided in the PUCCH configuration, as well as
%                    the number of bits provided with 'NumHARQAck'.
%
%   The output UCI is a structure array (one entry per each PUCCH Format 1 configured
%   in 'MuxFormat1', a singleton if 'MuxFormat1' is empty) with fields:
%
%   'isValid'             - Boolean flag: true if the PUCCH transmission was
%                           processed correctly.
%   'HARQAckPayload'      - Column array of HARQ ACK bits (possibly empty, int8).
%   'SRPayload'           - Column array of SR bits (possibly empty, int8).
%   'CSI1Payload'         - Column array of CSI Part 1 bits (possibly empty, int8).
%   'CSI2Payload'         - Column array of CSI Part 2 bits (possibly empty, int8).
%   'InitialCyclicShift'  - Initial cyclic shift (only when input 'MuxFormat1' is not empty).
%   'OCCI'                - Time domain orthogonal cover code index (only when
%                           input 'MuxFormat1' is not empty).
%
%   See also nrPUCCHDecode, nrUCIDecode, nrPUCCH0Config, nrPUCCH1Config, nrPUCCH2Config, nrCarrierConfig.

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

classdef srsPUCCHProcessor < matlab.System
    methods (Access = protected)
        function uci = stepImpl(obj, carrierConfig, pucchConfig, rxGrid, uciSizes)
            arguments
                obj                   (1, 1) srsMEX.phy.srsPUCCHProcessor
                carrierConfig         (1, 1) nrCarrierConfig
                pucchConfig           (1, 1)        {mustBeA(pucchConfig, ["nrPUCCH0Config", ...
                                                     "nrPUCCH1Config", "nrPUCCH2Config", ...
                                                     "nrPUCCH3Config", "nrPUCCH4Config"])}
                rxGrid            (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
                uciSizes.NumHARQAck   (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
                uciSizes.NumSR        (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
                uciSizes.NumCSIPart1  (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
                uciSizes.NumCSIPart2  (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
                uciSizes.MuxFormat1   (:, 1)        {mustBeMultiplexList} = []
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
            nidhopping = carrierConfig.NCellID;

            if isa(pucchConfig, 'nrPUCCH0Config')
                if ~isempty(pucchConfig.HoppingID)
                    nid = pucchConfig.HoppingID;
                end
                mexConfig = struct( ...
                    'Format', 0, ...
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
                    'NumSR', uciSizes.NumSR, ...
                    'InitialCyclicShift', pucchConfig.InitialCyclicShift, ...
                    'OCCI', [], ...             only PUCCH F1 and F4
                    'NumPRBs', [], ...          only PUCCH F2 and F3
                    'RNTI', [], ...             only PUCCH F2
                    'NID0', [], ...             only PUCCH F2, F3 and F4
                    'NumCSIPart1', [], ...      only PUCCH F2, F3 and F4
                    'NumCSIPart2', [], ...      only PUCCH F2, F3 and F4
                    'AdditionalDMRS', [], ...   only PUCCH F3 and F4
                    'Pi2BPSK', [], ...          only PUCCH F3 and F4
                    'NIDHopping', [], ...       only PUCCH F3 and F4
                    'NIDScrambling', [], ...    only PUCCH F3 and F4
                    'SpreadingFactor', [] ...   only PUCCH F4
                );

                assert(isempty(uciSizes.MuxFormat1), 'srsRAN-matlab:srsPUCCHProcessor', 'Input MuxFormat1 should be empty for PUCCH Format 0');
            elseif isa(pucchConfig, 'nrPUCCH1Config')
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
                    'NumPRBs', [], ...          only PUCCH F2 and F3
                    'RNTI', [], ...             only PUCCH F2, F3 and F4
                    'NID0', [], ...             only PUCCH F2
                    'NumSR', [], ...            only PUCCH F0 and F2
                    'NumCSIPart1', [], ...      only PUCCH F2, F3 and F4
                    'NumCSIPart2', [], ...      only PUCCH F2, F3 and F4
                    'AdditionalDMRS', [], ...   only PUCCH F3 and F4
                    'Pi2BPSK', [], ...          only PUCCH F3 and F4
                    'NIDHopping', [], ...       only PUCCH F3 and F4
                    'NIDScrambling', [], ...    only PUCCH F3 and F4
                    'SpreadingFactor', [] ...   only PUCCH F4
                    );
            elseif isa(pucchConfig, 'nrPUCCH2Config')
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
                    'InitialCyclicShift', [], ... only PUCCH F0 and F1
                    'OCCI', [], ...               only PUCCH F1 and F4
                    'AdditionalDMRS', [], ...     only PUCCH F3 and F4
                    'Pi2BPSK', [], ...            only PUCCH F3 and F4
                    'NIDHopping', [], ...         only PUCCH F3 and F4
                    'NIDScrambling', [], ...      only PUCCH F3 and F4
                    'SpreadingFactor', [] ...     only PUCCH F4
                    );

                assert(isempty(uciSizes.MuxFormat1), 'srsRAN-matlab:srsPUCCHProcessor', 'Input MuxFormat1 should be empty for PUCCH Format 2');
            elseif isa(pucchConfig, 'nrPUCCH3Config')
                if ~isempty(pucchConfig.NID)
                    nid = pucchConfig.NID;
                end
                if ~isempty(pucchConfig.HoppingID)
                    nidhopping = pucchConfig.HoppingID;
                end

                mexConfig = struct(...
                    'Format', 3, ...
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
                    'NIDHopping', nidhopping, ...
                    'NIDScrambling', nid, ...
                    'NumHARQAck', uciSizes.NumHARQAck, ...
                    'NumSR', uciSizes.NumSR, ...
                    'NumCSIPart1', uciSizes.NumCSIPart1, ...
                    'NumCSIPart2', uciSizes.NumCSIPart2, ...
                    'AdditionalDMRS', pucchConfig.AdditionalDMRS, ...
                    'Pi2BPSK', strcmp(pucchConfig.Modulation, 'pi/2-BPSK'), ...
                    'InitialCyclicShift', [], ... only PUCCH F0 and F1
                    'OCCI', [], ...               only PUCCH F1 and F4
                    'NID0', [], ...               only PUCCH F2
                    'SpreadingFactor', [] ...     only PUCCH F4
                    );

                assert(isempty(uciSizes.MuxFormat1), 'srsRAN-matlab:srsPUCCHProcessor', 'Input MuxFormat1 should be empty for PUCCH Format 3');
            else
                if ~isempty(pucchConfig.NID)
                    nid = pucchConfig.NID;
                end
                if ~isempty(pucchConfig.HoppingID)
                    nidhopping = pucchConfig.HoppingID;
                end

                mexConfig = struct(...
                    'Format', 4, ...
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
                    'RNTI', pucchConfig.RNTI, ...
                    'NIDHopping', nidhopping, ...
                    'NIDScrambling', nid, ...
                    'NumHARQAck', uciSizes.NumHARQAck, ...
                    'NumSR', uciSizes.NumSR, ...
                    'NumCSIPart1', uciSizes.NumCSIPart1, ...
                    'NumCSIPart2', uciSizes.NumCSIPart2, ...
                    'AdditionalDMRS', pucchConfig.AdditionalDMRS, ...
                    'Pi2BPSK', strcmp(pucchConfig.Modulation, 'pi/2-BPSK') , ...
                    'OCCI', pucchConfig.OCCI, ...
                    'SpreadingFactor', pucchConfig.SpreadingFactor, ...
                    'InitialCyclicShift', [], ... only PUCCH F0 and F1
                    'NumPRBs', [], ...            only PUCCH F2 and F3
                    'NID0', [] ...                only PUCCH F2
                    );

                assert(isempty(uciSizes.MuxFormat1), 'srsRAN-matlab:srsPUCCHProcessor', 'Input MuxFormat1 should be empty for PUCCH Format 4');
            end

            uci = obj.pucch_processor_mex('step', single(rxGrid), mexConfig, uciSizes.MuxFormat1);

            nResults = length(uci);

            assert((nResults == 1) || (mexConfig.Format == 1) && (length(uciSizes.MuxFormat1) == nResults));
        end % of function [uci, csi] = stepImpl(obj, pucchConfig, carrierConfig)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pucch_processor_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPUCCHProcessor < matlab.System

% Checks that the list of multiplexed PUCCH transmissions is valid.
function mustBeMultiplexList(a)
    arguments
        a (:, 1) struct
    end

    % The multiplex list is allowed to be empty.
    if isempty(a)
        return;
    end

    % Check that each element of the list is a struct with the proper fields.
    if ~isempty(setxor(fieldnames(a), {'InitialCyclicShift', 'OCCI', 'NumBits'}))
        eidType = 'mustBeMultiplexList:wrongFormat';
        msgType = ['All multiplexList entries should be structures with fields ''InitialCyclicShift'', ', ...
            '''OCCI'' and ''NumBits''.'];
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the initial cyclic shifts are within bounds.
    isICSDefined = all(arrayfun(@(x) ~isempty(x.InitialCyclicShift), a));
    allShifts = [a.InitialCyclicShift];
    isICSInteger = isICSDefined && all(mod(allShifts, 1) == 0);
    isICSInRange = isICSInteger && all(allShifts >= 0) && all(allShifts <= 11);
    if  ~isICSInRange
        eidType = 'mustBeMultiplexList:wrongInitialCyclicShift';
        msgType = 'All initial cyclic shifts must be integers between 0 and 11 included.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the OCCIs are within bounds (unfortunately, we can only check that the OCCI
    % is at most 6, not the true upperbound that depends on the allocated grant).
    isOCCIDefined = all(arrayfun(@(x) ~isempty(x.OCCI), a));
    allOCCI = [a.OCCI];
    isOCCIInteger = isOCCIDefined && all(mod(allOCCI, 1) == 0);
    isOCCIInRange = isOCCIInteger && all(allOCCI >= 0) && all(allOCCI <= 6);
    if  ~isOCCIInRange
        eidType = 'mustBeMultiplexList:wrongOCCI';
        msgType = 'All OCCI must be integers between 0 and 6 included.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the payload size.
    isBitsDefined = all(arrayfun(@(x) ~isempty(x.NumBits), a));
    allBits = [a.NumBits];
    isBitsInteger = isBitsDefined && all(mod(allBits, 1) == 0);
    isBitsInRange = isBitsInteger && all(allBits >= 0) && all(allBits <= 2);
    if  ~isBitsInRange
        eidType = 'mustBeMultiplexList:wrongNumBits';
        msgType = 'All number of bits must be integers between 0 and 2 included.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Cannot mix SR and ACK PUCCHs.
    nSR = sum(allBits == 0);
    if ((nSR > 0) && (nSR < numel(allBits)))
        eidType = 'mustBeMultiplexList:mixedPUCCHTypes';
        msgType = 'Cannot mix PUCCH carrying HARQ-ACK bits and PUCCH carrying SR bits.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the uniqueness of the entries.
    aHash = 12 * allShifts + allOCCI;
    if numel(unique(aHash)) ~= numel(a)
        eidType = 'mustBeMultiplexList:duplicatedEntry';
        msgType = 'Cyclic shift-OCCI pairs should not be repeated.';
        throwAsCaller(MException(eidType, msgType));
    end
end % of function mustBeMultiplexList(a)
