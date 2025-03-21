%srsPUSCHDemodulator MATLAB interface to srsRAN PUSCH demodulator.
%   User-friendly interface to the srsRAN PUSCH demodulator class, which is wrapped
%   by the MEX static method pusch_demodulator_mex.
%
%   PUSCHDEM = srsPUSCHDemodulator creates a PHY PUSCH demodulator object.
%
%   PUSCHDEM = srsPUSCHDemodulator(NAME, VALUE, ...) creates a PHY PUSCH demodulator object
%   with properties (see below) set accorgin to the NAME-VALUE pairs.
%
%   srsPUSCHDemodulator Methods:
%
%   step               - Demodulates a PUSCH transmission.
%
%   Step method syntax
%
%   SCHSOFTBITS = step(PUSCHDEMODULATOR, RXSYMBOLS, CE, NOISEVAR, PUSCH, PUSCHINDICES, ...
%                      PUSCHDMRSINDICES, RXPORTS)
%   uses the object PUSCHDEMODULATOR to demodulate an uplink shared channel transmission
%   and returns the recovered soft bits SCHSOFTBITS.
%
%   RXSYMBOLS is a three-dimensional complex array with the received resource grid
%   (dimensions are subcarriers, OFDM symbols and antenna ports).
%
%   CE is also a four-dimensional complex array with the estimated channel (the first
%   three dimensions are the same as before, the fourth one is transmission layers). NOISEVAR
%   is the estimated noise variance.
%
%   PUSCH is an nrPUSCHConfig object (the only relevant properties are PRBSet, RNTI,
%   Modulation, SymbolAllocation, DMRS.DMRSConfigurationType, DMRS.NumCDMGroupsWithoutData,
%   NID, and NumLayers).
%
%   PUSCHINDICES is an array of 1-based linear indices addressing the REs with UL-SCH
%   data in RXSYMBOLS.
%
%   PUSCHDMRSINDICES is an array of 1-based linear indices addressing the REs with
%   DM-RS symbols in RXSYMBOLS.
%
%   RXPORTS is an array of 0-based indices of the Rx-side antenna ports.
%
%   srsPUSCHDemodulator properties (nontunable):
%
%   EqualizerStrategy  - Equalizer strategy ('ZF', 'MMSE').

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

classdef srsPUSCHDemodulator < matlab.System
    properties (Nontunable)
        EqualizerStrategy (1, :) char {mustBeMember(EqualizerStrategy, {'ZF', 'MMSE'})} = 'ZF'
    end

    methods
        function obj = srsPUSCHDemodulator(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods (Access = protected)
        function setupImpl(obj)
            % Construct the PUSCH demodulator object inside the MEX function.
            obj.pusch_demodulator_mex('new', obj.EqualizerStrategy);
        end

        function schSoftBits = stepImpl(obj, rxSymbols, cest, noiseVar, pusch, puschIndices, puschDMRSIndices, rxPorts)
            arguments
                obj               (1, 1)        srsMEX.phy.srsPUSCHDemodulator
                rxSymbols         (:, 14, :)    double {srsTest.helpers.mustBeResourceGrid}
                cest              (:, 14, :, :) double {srsTest.helpers.mustBeResourceGrid(cest, MultiLayer=1)}
                noiseVar          (1, 1)        double {mustBePositive}
                pusch             (1, 1)        nrPUSCHConfig
                puschIndices                    double {mustBeInteger, mustBePositive}
                puschDMRSIndices                double {mustBeInteger, mustBePositive}
                rxPorts           (:, 1)        double {mustBeInteger, mustBeNonnegative}
            end

            gridSize = size(rxSymbols);
            ceSize = size(cest);
            assert(all(gridSize(1:2) == ceSize(1:2)), 'srsran_matlab:srsPUSCHDemodulator', ...
                'Resource grid and channel estimates sizes do not match.');
            if (numel(gridSize) > 2)
                assert(numel(ceSize) > 2, 'srsran_matlab:srsPUSCHDemodulator', ...
                    'Resource grid and channel estimates sizes do not match.');
                assert(all(gridSize(3) == ceSize(3)), 'srsran_matlab:srsPUSCHDemodulator', ...
                    'Resource grid and channel estimates sizes do not match.');
                assert(numel(rxPorts) <= gridSize(3), 'srsran_matlab:srsPUSCHDemodulator', ...
                    'The number of PUSCH ports, %d, cannot be larger than the number of Rx antenna ports, %d.', ...
                    numel(rxPorts), gridSize(3));
            else
                assert(numel(ceSize) == 2, 'srsran_matlab:srsPUSCHDemodulator', ...
                    'Resource grid and channel estimates sizes do not match.');
                assert(isscalar(rxPorts), 'srsran_matlab:srsPUSCHDemodulator', ...
                    'The number of PUSCH ports, %d, cannot be larger than the number of Rx antenna ports, 1.', ...
                    numel(rxPorts));
            end

            assert(size(puschIndices, 2) == pusch.NumLayers, 'srsran_matlab:srsPUSCHDemodulator', ...
                'The number of columns of puschIndices should be equal to the number of layers.');
            assert(size(puschDMRSIndices, 2) == pusch.NumLayers, 'srsran_matlab:srsPUSCHDemodulator', ...
                'The number of columns of puschDMRSIndices should be equal to the number of layers.');

            for iLayer = 2:pusch.NumLayers
                assert(all(puschIndices(:, 1) == puschIndices(:, iLayer) - gridSize(1) * gridSize(2) * (iLayer - 1)), ...
                    'srsran_matlab:srsPUSCHDemodulator', ...
                    'All layers are assumed to send data on the same resources.');
            end

            if pusch.NumLayers > 1
                assert(all(puschDMRSIndices(:, 1) == puschDMRSIndices(:, 2) - gridSize(1) * gridSize(2)), ...
                    'srsran_matlab:srsPUSCHDemodulator', ...
                    'Layer 0 and layer 1 are assumed to send DM-RS on the same resources.');
            end
            if pusch.NumLayers == 4
                assert(all(puschDMRSIndices(:, 3) == puschDMRSIndices(:, 4) - gridSize(1) * gridSize(2)), ...
                    'srsran_matlab:srsPUSCHDemodulator', ...
                    'Layer 2 and layer 3 are assumed to send DM-RS on the same resources.');
            end

            [~, puschDMRSIndicesSyms, ~] = ind2sub(gridSize(1:2), puschDMRSIndices(:, 1));

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = false(gridSize(1) / 12, 1);
            rbAllocationMask(pusch.PRBSet + 1) = true;

            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = false(14, 1);
            dmrsSymbolMask(unique(puschDMRSIndicesSyms)) = true;

            % Fill the configuration structure.
            PUSCHDemConfig = struct( ...
                'RNTI', pusch.RNTI, ...
                'RBMask', rbAllocationMask, ...
                'Modulation', pusch.Modulation, ...
                'StartSymbolIndex', pusch.SymbolAllocation(1), ...
                'NumSymbols', pusch.SymbolAllocation(2), ...
                'DMRSSymbPos', dmrsSymbolMask, ...
                'DMRSConfigType', pusch.DMRS.DMRSConfigurationType, ...
                'NumCDMGroupsWithoutData', pusch.DMRS.NumCDMGroupsWithoutData, ...
                'NID', pusch.NID, ...
                'NumLayers', pusch.NumLayers, ...
                'TransformPrecoding', pusch.TransformPrecoding, ...
                'RxPorts', rxPorts, ...
                'NumOutputLLR', numel(puschIndices) * srsLib.phy.helpers.srsGetBitsSymbol(pusch.Modulation));

            schSoftBits = obj.pusch_demodulator_mex('step', single(rxSymbols), cest, noiseVar, ...
                PUSCHDemConfig);
        end % function step(...)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pusch_demodulator_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPUSCHDemodulator < matlab.System
