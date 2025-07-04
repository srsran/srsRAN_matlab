%srsMultiPortChannelEstimator estimates a SIMO channel.
%   User-friendly interface for estimating a single-input multiple-output (SIMO)
%   channel via the MEX static method multiport_channel_estimator_mex, which
%   calls srsRAN port_channel_estimator for each port and combines the outputs.
%
%   CHESTIMATOR = srsMultiPortChannelEstimator creates the SIMO channel estimator
%   object CHESTIMATOR.
%
%   CHESTIMATOR = srsMultiPortChannelEstimator(NAME, VALUE, ...) creates a SIMO channel estimator
%   with properties (see below) set according to the NAME-VALUE pairs.
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
%
%   srsMultiPortChannelEstimator propertires (nontunable):
%
%   ImplementationType - Channel estimator implementation ('MEX', 'noMEX').
%   Smoothing          - Frequency-domain smoothing strategy ('filter', 'mean', 'none').
%   Interpolation      - Time-domain interpolation ('average', 'interpolate').
%   CompensateCFO      - Boolean flat: compensate CFO if true.

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

classdef srsMultiPortChannelEstimator < matlab.System
    properties (Hidden, Access = private)
        stepMethod
    end

    properties (Nontunable)
        %Channel estimator implementation ('MEX', 'noMEX').
        ImplementationType (1, :) char     {mustBeMember(ImplementationType, {'MEX', 'noMEX'})} = 'MEX'
        %Frequency domain smoothing strategy ('filter', 'mean', 'none').
        Smoothing          (1, :) char     {mustBeMember(Smoothing, {'filter', 'mean', 'none'})} = 'filter'
        %Time domain interpolation strategy ('average', 'interpolate').
        Interpolation      (1, :) char     {mustBeMember(Interpolation, {'average', 'interpolate'})} = 'average'
        %Boolean flat: compensate CFO if true.
        CompensateCFO      (1, 1) logical      = true
    end % properties (Nontunable)

    methods
        function obj = srsMultiPortChannelEstimator(varargin)
        %Constructor: sets nontunable properties.
            setProperties(obj, nargin, varargin{:});
        end
    end % of public methods

    methods (Access = protected)
        function setupImpl(obj)
        %Sets the stepMethod according to the implementation type and, if this is 'MEX',
        %   constructs the channel estimator object inside the MEX function.
            if strcmp(obj.ImplementationType, 'MEX')
                obj.stepMethod = @stepMEX;
                obj.multiport_channel_estimator_mex('new', obj.Smoothing, obj.Interpolation, obj.CompensateCFO);
            else
                obj.stepMethod = @stepPLAIN;
            end
        end % of function setupImpl(obj)

        function [channelEst, noiseEst, extra] = stepImpl(obj, rxGrid, ...
            symbolAllocation, refInd, refSym, config)
            arguments
                obj                      (1, 1)     srsMEX.phy.srsMultiPortChannelEstimator
                rxGrid                   (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
                symbolAllocation         (1, 2)     double {mustBeInteger, mustBeNonnegative}
                refInd                   (:, :)     double {mustBeInteger, mustBePositive}
                refSym                   (:, :)     double {mustBeNumeric}
                config.PortIndices       (:, 1)     double {mustBeInteger, mustBeNonnegative} = 0
                config.CyclicPrefix      (1, :)     char   {mustBeMember(config.CyclicPrefix, {'normal', 'extended'})} = 'normal'
                config.SubcarrierSpacing (1, 1)     double {mustBeMember(config.SubcarrierSpacing, [15 30])} = 15
                config.HoppingIndex                 double = []
                config.BetaScaling       (1, 1)     double {mustBePositive} = 1
            end

            assert(symbolAllocation(1) < 14, 'srsran_matlab:srsMultiPortChannelEstimator', 'First allocated symbol out of range.');
            lastSymbol = sum(symbolAllocation) - 1;
            assert(lastSymbol < 14, 'srsran_matlab:srsMultiPortChannelEstimator', 'Last allocated symbol out of range.');

            [nPilots, nLayers] = size(refSym);
            assert(nLayers <= 4, 'srsran_matlab:srsMultiPortChannelEstimator', ...
                'Currently, max 4 layers supported, provided %d.', nLayers);
            assert(nPilots == numel(refInd(:, 1)), 'srsran_matlab:srsMultiPortChannelEstimator', ...
                ['The number of pilots per layer %d and the number of pilot resources %d ', ...
                 'do not match.'], nPilots, numel(refInd));
            assert(nLayers == size(refInd, 2), 'srsran_matlab:srsMultiPortChannelEstimator', ...
                ['The number of layers inferred from the pilots %d and the number of layers inferred ', ...
                 'from the pilot index list %d do not match.'], nPilots, numel(refInd));

            gridSize = size(rxGrid);
            nREs = gridSize(1) * gridSize(2);
            if nLayers > 1
                assert(all(refInd(:, 1) == refInd(:, 2) - nREs), ...
                    'srsran_matlab:srsMultiPortChannelEstimator', ...
                    'Layer 0 and layer 1 are assumed to send DM-RS on the same resources (only DM-RS type 1 supported).');
            end
            if nLayers == 4
                assert(all(refInd(:, 3) == refInd(:, 4) - nREs), ...
                    'srsran_matlab:srsMultiPortChannelEstimator', ...
                    'Layer 2 and layer 3 are assumed to send DM-RS on the same resources (only DM-RS type 1 supported).');
            end

            if ~isempty(config.HoppingIndex)
                validateattributes(config.HoppingIndex, {'double'}, ...
                    {'scalar', 'integer', '>', symbolAllocation(1), '<=', lastSymbol}, mfilename('class'));
            end

            refIndNorm = refInd(:, 1:2:end);
            for iCol = 2:size(refIndNorm, 2)
                refIndNorm(:, iCol) = refIndNorm(:, iCol) - iCol * nREs;
            end

            [channelEst, noiseEst, extra] = obj.stepMethod(obj, rxGrid, symbolAllocation, refIndNorm, refSym, config);
        end
    end

    methods (Access = private)
        function [channelEst, noiseEst, extra] = stepMEX(obj, rxGrid, ...
            symbolAllocation, refInd, refSym, config)
        % Implementation of the step method that uses the MEX.

            if size(refInd, 2) == 2
                assert(all(refInd(:, 2) - refInd(:, 1) == 1), 'srsran_matlab:srsMultiPortChannelEstimator', ...
                    ['Only DM-RS configuration type 1 is supported, layers {0, 1} and {2, 3} should have\n', ...
                     'complementary RE patterns.']);
            end

            nLayers = size(refSym, 2);
            nLayersMEX = srsMEX.phy.srsPUSCHCapabilitiesMEX().NumLayers;
            assert(nLayers <= nLayersMEX, 'srsran_matlab:srsMultiPortChannelEstimator', ...
                'The current MEX version does not support more than %d layers, required %d.', ...
                nLayersMEX, nLayers);

            sz = size(rxGrid);
            pilotMask = false(sz(1:2));
            pilotMask(refInd(:, 1)) = true;

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
                config.RBMask2 = logical([]);
            end

            % Find one RB carrying DM-RS.
            RBindex = find(config.RBMask, 1);
            REpattern = pilotMask((RBindex-1)*12+(1:12), firstDMRSSymbol);
            config.REPatternCDM0 = REpattern;
            if size(refInd, 2) == 2
                config.REPatternCDM1 = ~REpattern;
            else
                config.REPatternCDM1 = logical([]);
            end

            % Call the actual channel estimator.
            [channelEstS, info] = obj.multiport_channel_estimator_mex('step', single(rxGrid), ...
                symbolAllocation, single(refSym), config);

            % Format outputs.
            channelEst = double(squeeze(channelEstS));
            noiseEst = info(end).NoiseVar;
            extra = rmfield(info, 'NoiseVar');

        end % of function stepMEX(obj, rxGrid, refInd, refSym, varargin)

        function [channelEst, noiseEst, extra] ...
                = stepPLAIN(obj, rxGrid, symbolAllocation, refInd, refSym, config)
        % Implementation of the step method that uses SRS matlab implementation.

            import srsLib.phy.upper.signal_processors.srsChannelEstimator
            import srsLib.ran.utils.scs2cps
            import srsTest.helpers.approxbf16

            % Build hop configuration structures.
            gridsize = size(rxGrid);
            totalRBs = gridsize(1) / 12;
            [pSCS, pSyms] = ind2sub(gridsize(1:2), refInd(:));

            DMRSsymbols = false(14, 1);
            DMRSsymbols(unique(pSyms)) = true;

            nDMRSsymbols = sum(DMRSsymbols);
            nLayers = size(refSym, 2);
            pilots = reshape(refSym, [], nDMRSsymbols, nLayers);

            nCDM = ceil(nLayers / 2);
            pSCS = reshape(pSCS, [], nDMRSsymbols, nCDM);
            nPRBs = ceil((pSCS(end, 1, 1) - pSCS(1, 1, 1)) / 12);

            nRBpilots = length(pSCS(:, 1, 1)) / nPRBs;
            DMRSREmask = false(12, nCDM);
            DMRSREmask(mod(pSCS(1:nRBpilots, 1, 1) - 1, 12) + 1, 1) = true;
            if nCDM == 2
                DMRSREmask(mod(pSCS(1:nRBpilots, 1, 2) - 1, 12) + 1, 2) = true;
            end

            maskPRBs = false(totalRBs, 1);
            maskPRBs(unique(ceil(pSCS(:, 1, 1) / 12))) = true;

            hop1 = struct(...
                'DMRSsymbols', DMRSsymbols, ...
                'DMRSREmask', DMRSREmask, ...
                'PRBstart', ceil(pSCS(1, 1, 1) / 12) - 1, ...
                'nPRBs', nPRBs, ...
                'maskPRBs', maskPRBs, ...
                'startSymbol', symbolAllocation(1), ...
                'nAllocatedSymbols', symbolAllocation(2));

            hopIndex = config.HoppingIndex;
            if isempty(hopIndex)
                hop2 = struct(...
                    'DMRSsymbols', [], ...
                    'DMRSREmask', [], ...
                    'PRBstart', [], ...
                    'nPRBs', [], ...
                    'maskPRBs', [], ...
                    'startSymbol', [], ...
                    'nAllocatedSymbols', []);
            else
                hop2 = hop1;

                hop1.DMRSsymbols(hopIndex+1:end) = false;
                hop1.nAllocatedSymbols = hopIndex - hop1.startSymbol;

                hop2.DMRSsymbols(1:hopIndex) = false;
                hop2.PRBstart = ceil(pSCS(1, end, 1) / 12) - 1;
                hop2.maskPRBs(:) = false;
                hop2.maskPRBs(unique(ceil(pSCS(:, end, 1) / 12))) = true;
                hop2.startSymbol = hopIndex;
                hop2.nAllocatedSymbols = hop2.nAllocatedSymbols - hop1.nAllocatedSymbols;
            end

            configNew = struct(...
                'scs', config.SubcarrierSpacing * 1000, ...
                'CyclicPrefixDurations', scs2cps(config.SubcarrierSpacing), ...
                'Smoothing', obj.Smoothing, ...
                'CFOCompensate', obj.CompensateCFO);

            % Check the number of Rx antenna ports.
            nPorts = 1;
            if length(gridsize) == 3
                nPorts = gridsize(3);
            end

            channelEst = nan([gridsize(1:2), nPorts, nLayers]);
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
                [channelEst(:, :, iPort, :), noiseEstTmp, rsrpTmp, epreTmp, taTmp, cfoTmp] = ...
                    srsChannelEstimator(approxbf16(rxGrid(:, :, iPort)), pilots, config.BetaScaling, hop1, hop2, configNew);

                noiseEst = noiseEst + noiseEstTmp / nPorts;
                rsrp = rsrp + rsrpTmp / nPorts;
                epre = epre + epreTmp / nPorts;
                ta = ta + taTmp / nPorts;
                cfo = cfo + cfoTmp;

                extra(iPort).RSRP = rsrpTmp;
                extra(iPort).EPRE = epreTmp;
                extra(iPort).SINR = rsrpTmp * nLayers / config.BetaScaling^2 / noiseEstTmp;
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
