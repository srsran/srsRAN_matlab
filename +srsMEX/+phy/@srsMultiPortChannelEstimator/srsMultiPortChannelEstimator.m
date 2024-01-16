%srsrMultiportChannelEstimator estimates a SIMO channel.
%   User-friendly interface for estimating a single-input multiple-output (SIMO)
%   channel via the MEX static method multiport_channel_estimator_mex, which
%   calls srsRAN port_channel_estimator for each port and combines the outputs.
%
%   CHESTIMATOR = srsMultiPortChannelEstimator creates the SIMO channel estimator
%   object CHESTIMATOR.
%
%   srsMultiPortChannelEstimator Methods:
%
%   step  - Estimates a SIMO channel.
%
%   Step method syntax
%
%   [H, NVAR, EXTRA] = step(OBJ, RXGRID, SYMBOLALLOCATION, REFIND, REFSYM) estimates
%   a SISO channel from the received resource grid RXGRID by using the reference
%   symbols REFSYM at locations REFIND, for all OFDM symbols specified in SYMBOLALLOCATION.
%   The function returns the channel estimate H (with zeros in the REs out of range),
%   the estimated noise variance NVAR and the EXTRA structure with the estimated
%   RSRP, EPRE, SINR and time alignment (in the fields with the corresponding names).
%
%   [H, NVAR, EXTRA] = step(..., NAME, VALUE, ...) specifies additional options as
%   NAME, VALUE pairs:
%
%   'PortIndices'         - Column vector of Rx port indices (default is [0]).
%   'CyclicPrefix'        - Cyclic prefix, either 'normal' (default) or 'extended'.
%   'SubcarrierSpacing'   - Subcarrier spacing in kHz, either 15 (default) or 30.
%   'HoppingIndex'        - First OFDM symbol after intraslot frequency hopping (default
%                           is [] for no frequency hopping).
%   'BetaScaling'         - DM-RS to data amplitude gain (default is 1).

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

classdef srsMultiPortChannelEstimator < matlab.System

    methods (Access = protected)
        function [channelEst, noiseEst, extra] ...
                = stepImpl(obj, rxGrid, symbolAllocation, refInd, refSym, config)
            arguments
                obj                      (1, 1)     srsMEX.phy.srsMultiPortChannelEstimator
                rxGrid                   (:, 14, :) double {mustBeNumeric}
                symbolAllocation         (1, 2)     double {mustBeInteger, mustBeNonnegative}
                refInd                   (:, 1)     double {mustBeInteger, mustBePositive}
                refSym                   (:, 1)     double {mustBeNumeric}
                config.PortIndices       (:, 1)     double {mustBeInteger, mustBeNonnegative} = 0
                config.CyclicPrefix      (1, :)     char   {mustBeMember(config.CyclicPrefix, {'normal', 'extended'})} = 'normal'
                config.SubcarrierSpacing (1, 1)     double {mustBeMember(config.SubcarrierSpacing, [15 30])} = 15
                config.HoppingIndex                 double = []
                config.BetaScaling       (1, 1)     double {mustBePositive} = 1
            end

            assert(symbolAllocation(1) < 14, 'First allocated symbol out of range.');
            lastSymbol = sum(symbolAllocation) - 1;
            assert(lastSymbol < 14, 'Last allocated symbol out of range.');

            sz = size(rxGrid);
            pilotMask = false(sz(1:2));
            pilotMask(refInd) = true;

            % OFDM symbols carrying DM-RS.
            config.Symbols = any(pilotMask, 1);

            % DM-RS RB mask for first hop.
            firstDMRSSymbol = find(config.Symbols, 1);
            nRBs = sz(1) / 12;
            config.RBMask = false(nRBs, 1);
            for iRB = 1:nRBs
                config.RBMask(iRB) = any(pilotMask((iRB-1)*12+(1:12), firstDMRSSymbol));
            end

            if ~isempty(config.HoppingIndex)
                validateattributes(config.HoppingIndex, {'double'}, ...
                    {'scalar', 'integer', '>', symbolAllocation(1), '<=', lastSymbol}, mfilename('class'));

                % DM-RS RB mask for second hop (if it exists).
                firstDMRSSymbol2 = find(config.Symbols(config.HoppingIndex+1:end), 1) + config.HoppingIndex;
                config.RBMask2 = false(nRBs, 1);
                for iRB = 1:nRBs
                    config.RBMask2(iRB) = any(pilotMask((iRB-1)*12+(1:12), firstDMRSSymbol2));
                end
            else
                config.RBMask2 = [];
            end

            % Find one RB carrying DM-RS.
            RBindex = find(config.RBMask, 1);
            config.REPattern = pilotMask((RBindex-1)*12+(1:12), firstDMRSSymbol);

            % Call the actual channel estimator.
            [channelEstS, info] = obj.multiport_channel_estimator_mex('step', single(rxGrid), ...
                symbolAllocation, single(refSym), config);

            % Format outputs.
            channelEst = double(channelEstS);
            if (length(config.PortIndices) == 1)
                % If there was a single port, use its info.
                infoOut = info(1);
            else
                % If there were multiple ports, use the global info.
                infoOut = info(end);
            end
            noiseEst = infoOut.NoiseVar;
            extra.RSRP = infoOut.RSRP;
            extra.EPRE = infoOut.EPRE;
            extra.SINR = infoOut.SINR;
            extra.TimeAlignment = infoOut.TimeAlignment;

        end % of function stepImpl(obj, rxGrid, refInd, refSym, varargin)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = multiport_channel_estimator_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPortChannelEstimator < matlab.System
