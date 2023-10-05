%srsPUSCHDemodulator MATLAB interface to srsRAN PUSCH demodulator.
%   User-friendly interface to the srsRAN PUSCH demodulator class, which is wrapped
%   by the MEX static method pusch_demodulator_mex.
%
%   PUSCHDEM = srsPUSCHDemodulator creates a PHY PUSCH demodulator object.
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
%   CE is also a three-dimensional complex array with the estimated channel (dimensions
%   are the same as before, currently only one transmission layer is supported). NOISEVAR
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

classdef srsPUSCHDemodulator < matlab.System
    methods (Access = protected)
        function schSoftBits = stepImpl(obj, rxSymbols, cest, noiseVar, pusch, puschIndices, puschDMRSIndices, rxPorts)
            arguments
                obj               (1, 1)     srsMEX.phy.srsPUSCHDemodulator
                rxSymbols         (:, 14, :) double
                cest              (:, 14, :) double
                noiseVar          (1, 1)     double {mustBePositive}
                pusch             (1, 1)     nrPUSCHConfig
                puschIndices      (:, 1)     double {mustBeInteger, mustBePositive}
                puschDMRSIndices  (:, 1)     double {mustBeInteger, mustBePositive}
                rxPorts           (:, 1)     double {mustBeInteger, mustBeNonnegative}
            end

            gridSize = size(rxSymbols);
            assert(all(gridSize == size(cest)), 'srsran_matlab:srsPUSCHDemodulator', ...
                'Resource grid and channel estimates sizes do not match.');

            [~, puschDMRSIndicesSyms, ~] = ind2sub(gridSize, puschDMRSIndices);

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = false(gridSize(1) / 12, 1);
            rbAllocationMask(pusch.PRBSet + 1) = true;

            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = false(14, 1);
            dmrsSymbolMask(unique(puschDMRSIndicesSyms)) = true;

            % Fill the configuration structure.
            PUSCHDemConfig.RNTI = pusch.RNTI;
            PUSCHDemConfig.RBMask = rbAllocationMask;
            PUSCHDemConfig.Modulation = pusch.Modulation;
            PUSCHDemConfig.StartSymbolIndex = pusch.SymbolAllocation(1);
            PUSCHDemConfig.NumSymbols = pusch.SymbolAllocation(2);
            PUSCHDemConfig.DMRSSymbPos = dmrsSymbolMask;
            PUSCHDemConfig.DMRSConfigType = pusch.DMRS.DMRSConfigurationType;
            PUSCHDemConfig.NumCDMGroupsWithoutData = pusch.DMRS.NumCDMGroupsWithoutData;
            PUSCHDemConfig.NID = pusch.NID;
            PUSCHDemConfig.NumLayers = pusch.NumLayers;
            [I1, I2, I3] = ind2sub([gridSize(1:2) pusch.NumLayers], puschIndices);
            PUSCHDemConfig.PUSCHIndices = [I1, I2, I3] - 1;
            PUSCHDemConfig.RxPorts = rxPorts;

            puschSymbols = nrExtractResources(puschIndices, rxSymbols);

            schSoftBits = obj.pusch_demodulator_mex('step', single(puschSymbols), cest, noiseVar, ...
                PUSCHDemConfig);
        end % function step(...)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pusch_demodulator_mex(varargin)
    end % of methods (Access = private, Static)
end % of classdef srsPUSCHDemodulator < matlab.System
