%srsMultiportChannelEstimator estimates a SIMO channel.
%   User-friendly interface for estimating a single-input multiple-output (SIMO)
%   channel via the MEX static method multiport_channel_estimator_mex, which
%   calls srsRAN port_channel_estimator for each port and combines the outputs.
%
%   CHESTIMATOR = srsMultiPortChannelEstimator creates the SIMO channel estimator
%   object CHESTIMATOR.
%
%   CHESTIMATOR = srsMultiPortChannelEstimator('noMEX') creates a SIMO channel estimator
%   that is implemented in MATLAB exclusively, without recurring to the MEX.
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
    properties (Hidden, Access = private)
        stepMethod
    end

    methods
        function obj = srsMultiPortChannelEstimator(type)
            arguments
                type (1, :) char {mustBeMember(type, {'MEX', 'noMEX'})} = 'MEX'
            end

            if strcmp(type, 'MEX')
                obj.stepMethod = @stepMEX;
            else
                obj.stepMethod = @stepPLAIN;
            end
        end
    end % of public methods

    methods (Access = protected)
        function [channelEst, noiseEst, extra] ...
                = stepImpl(obj, rxGrid, symbolAllocation, refInd, refSym, config)
            arguments
                obj                      (1, 1)     srsMEX.phy.srsMultiPortChannelEstimator
                rxGrid                   (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
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

            if ~isempty(config.HoppingIndex)
                validateattributes(config.HoppingIndex, {'double'}, ...
                    {'scalar', 'integer', '>', symbolAllocation(1), '<=', lastSymbol}, mfilename('class'));
            end

            [channelEst, noiseEst, extra] = obj.stepMethod(obj, rxGrid, symbolAllocation, refInd, refSym, config);
        end
    end

    methods (Access = private)
        function [channelEst, noiseEst, extra] ...
                = stepMEX(obj, rxGrid, symbolAllocation, refInd, refSym, config)
        % Implementation of the step method that uses the MEX.

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
            if (isscalar(config.PortIndices))
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
            extra.CFO = infoOut.CFO;

        end % of function stepMEX(obj, rxGrid, refInd, refSym, varargin)

        function [channelEst, noiseEst, extra] ...
                = stepPLAIN(~, rxGrid, symbolAllocation, refInd, refSym, config)
        % Implementation of the step method that uses SRS matlab implementation.

            import srsLib.phy.upper.signal_processors.srsChannelEstimator
            import srsLib.ran.utils.scs2cps

            % Build hop configuration structures.
            gridsize = size(rxGrid);
            totalRBs = gridsize(1) / 12;
            [pSCS, pSyms] = ind2sub(gridsize(1:2), refInd);

            DMRSsymbols = false(14, 1);
            DMRSsymbols(unique(pSyms)) = true;

            nDMRSsymbols = sum(DMRSsymbols);
            pilots = reshape(refSym, [], nDMRSsymbols);

            pSCS = reshape(pSCS, [], nDMRSsymbols);
            nPRBs = ceil((pSCS(end, 1) - pSCS(1, 1)) / 12);

            nRBpilots = length(pSCS(:, 1)) / nPRBs;
            DMRSREmask = false(12, 1);
            DMRSREmask(mod(pSCS(1:nRBpilots, 1) - 1, 12) + 1) = true;

            maskPRBs = false(totalRBs, 1);
            maskPRBs(unique(ceil(pSCS(:, 1) / 12))) = true;

            hop1 = struct(...
                'DMRSsymbols', DMRSsymbols, ...
                'DMRSREmask', DMRSREmask, ...
                'PRBstart', ceil(pSCS(1, 1) / 12) - 1, ...
                'nPRBs', nPRBs, ...
                'maskPRBs', maskPRBs, ...
                'startSymbol', symbolAllocation(1), ...
                'nAllocatedSymbols', symbolAllocation(2));

            hop2 = struct(...
                'DMRSsymbols', [], ...
                'DMRSREmask', [], ...
                'PRBstart', [], ...
                'nPRBs', [], ...
                'maskPRBs', [], ...
                'startSymbol', [], ...
                'nAllocatedSymbols', []);

            configNew = struct(...
                'DMRSREmask', DMRSREmask, ...
                'DMRSSymbolMask', DMRSsymbols, ...
                'scs', config.SubcarrierSpacing * 1000, ...
                'CyclicPrefixDurations', scs2cps(config.SubcarrierSpacing));

            hopIndex = config.HoppingIndex;
            if ~isempty(hopIndex)
                hop2 = hop1;

                hop1.DMRSsymbols(hopIndex+1:end) = false;
                hop1.nAllocatedSymbols = hopIndex - hop1.startSymbol;

                hop2.DMRSsymbols(1:hopIndex) = false;
                hop2.PRBstart = ceil(pSCS(1, end) / 12) - 1;
                hop2.maskPRBs(:) = false;
                hop2.maskPRBs(unique(ceil(pSCS(:, end) / 12))) = true;
                hop2.startSymbol = hopIndex;
                hop2.nAllocatedSymbols = hop2.nAllocatedSymbols - hop1.nAllocatedSymbols;
            end

            % Check the number of Rx antenna ports.
            nPorts = 1;
            if length(gridsize) == 3
                nPorts = gridsize(3);
            end

            channelEst = nan(gridsize);
            if nPorts == 1
                extra = struct('RSRP', 0, 'EPRE', 0, 'SINR', 0, 'TimeAlignment', 0, 'CFO', []);
            else
                extra(nPorts + 1) = struct('RSRP', 0, 'EPRE', 0, 'SINR', 0, 'TimeAlignment', 0, 'CFO', []);
            end

            % Set up tracking of average metrics across ports.
            noiseEst = 0;
            rsrp = 0;
            epre = 0;
            ta = 0;
            cfo = [];

            for iPort = 1:nPorts
                [channelEst(:, :, iPort), noiseEstTmp, rsrpTmp, epreTmp, taTmp, cfoTmp] = ...
                    srsChannelEstimator(rxGrid(:, :, iPort), pilots, config.BetaScaling, hop1, hop2, configNew);

                noiseEst = noiseEst + noiseEstTmp / nPorts;
                rsrp = rsrp + rsrpTmp / nPorts;
                epre = epre + epreTmp / nPorts;
                ta = ta + taTmp / nPorts;
                cfo = cfo + cfoTmp;

                extra(iPort).RSRP = rsrpTmp;
                extra(iPort).EPRE = epreTmp;
                extra(iPort).SINR = rsrpTmp / config.BetaScaling^2 / noiseEstTmp;
                extra(iPort).TimeAlignment = taTmp;
                extra(iPort).CFO = cfoTmp;
            end

            % If multiple ports, also report the average metrics.
            if nPorts > 1
                extra(end).RSRP = rsrp;
                extra(end).EPRE = epre;
                extra(end).SINR = nan; % Global SINR is meaningless here.
                extra(end).TimeAlignment = ta;
                extra(end).CFO = cfo;
            end
        end % of function stepPLAIN(obj, rxGrid, refInd, refSym, varargin)

    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = multiport_channel_estimator_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPortChannelEstimator < matlab.System
