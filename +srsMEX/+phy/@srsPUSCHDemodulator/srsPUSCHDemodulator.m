%srsPUSCHDemodulator MATLAB interface to srsRAN PUSCH demodulator.
%   User-friendly interface to the srsRAN PUSCH demodulator class, which is wrapped
%   by the MEX static method pusch_demodulator_mex.
%
%   PUSCHDEM = srsPUSCHDemodulator creates a PHY PUSCH Demodulator object which
%   is meant to be tested with a frequency-domain PUSCH transmission signal.
%
%   srsPUSCHDemodulator Properties (Nontunable):
%
%   NOISEVAR - Noise variance.
%
%   srsPUSCHDemodulator Methods:
%
%   step               - Demodulates a PUSCH transmission.
%   configurePUSCHDem  - Static helper method for filling the PRUSCHDEMCONFIG input of "step".
%
%   Step method syntax
%
%   SCHSOFTBITS = step(PUSCHDEMODULATOR, RXSYMBOLS, PUSCHINDICES, CE, PUSCHDEMCONFIG) uses the
%   object PUSCHDEMODULATOR to demodulate a PUSCH transmissiong in the frequency-domain
%   signal RXSYMBOLS and returns the recovered soft bits SCHSOFTBITS.
%   RXSYMBOLS is a complex array which comprises the REs allocated to the PUSCH
%   transmission, which use the RE indices PUSCHINDICES. A channel estimate CE for those
%   REs is also provided to the demodulator. Structure PUSCHDEMCONFIG describes the basic
%   configuration parameters to be utilized by the PUSCH demodulator. The fields are
%      rnti                    - radio network temporary identifier;
%      rbMask                  - allocation RB list;
%      modulation              - modulation scheme used for transmission;
%      startSymbolIndex        - start symbol index of the time domain allocation within a slot;
%      nofSymbols              - number of symbols of the time domain allocation within a slot;
%      dmrsSymbPos             - boolean mask flagging the OFDM symbols containing DM-RS;
%      dmrsConfigType          - DMRS configuration type;
%      nofCdmGroupsWithoutData - number of DMRS CDM groups without data;
%      nId                     - scrambling identifier;
%      nofTxLayers             - number of transmit layers;
%      placeholders            - ULSCH Scrambling placeholder list;
%      rxPorts                 - receive antenna port indices the PUSCH transmission is mapped to;

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
    methods
        function obj = srsPUSCHDemodulator(varargin)
        %Constructor: sets nontunable properties.
        end % constructor
    end % of methods

    methods (Access = protected)
        function schSoftBits = stepImpl(obj, rxSymbols, puschIndices, ce, PUSCHDemConfig, noiseVar)
            arguments
                obj            (1, 1) srsMEX.phy.srsPUSCHDemodulator
                rxSymbols      (:, 1) double
                puschIndices   (:, 3) double
                ce             (:, 1) double
                PUSCHDemConfig (1, 1) struct
                noiseVar       (1, 1) double
            end

            fcnName = [class(obj) '/step'];

            validateattributes(PUSCHDemConfig.rnti, {'double'}, {'scalar', 'integer'}, fcnName, 'RNTI');
            validateattributes(PUSCHDemConfig.rbMask, {'double'}, {'vector', 'integer', 'nonnegative'}, ...
                  fcnName, 'RBMASK');
            modulationList = {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};
            validatestring(PUSCHDemConfig.modulation, modulationList, fcnName, 'MODULATION');
            validateattributes(PUSCHDemConfig.startSymbolIndex, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                  fcnName, 'STARTSYMBOLINDEX');
            validateattributes(PUSCHDemConfig.nofSymbols, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                  fcnName, 'NOFSYMBOLS');
            validateattributes(PUSCHDemConfig.dmrsSymbPos, {'double'}, {'vector', 'integer', 'nonnegative'}, ...
                  fcnName, 'DMRSSYMBPOS');
            validateattributes(PUSCHDemConfig.dmrsConfigType, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                  fcnName, 'DMRSCONFIGTYPE');
            validateattributes(PUSCHDemConfig.nofCdmGroupsWithoutData, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                  fcnName, 'NOFCDMGROUPSWITHOUTDATA');
            validateattributes(PUSCHDemConfig.nId, {'double'}, {'scalar', 'integer', 'nonnegative'}, fcnName, 'NID');
            validateattributes(PUSCHDemConfig.nofTxLayers, {'double'}, {'vector', 'integer', 'nonnegative'}, ...
                  fcnName, 'NOFTXLAYERS');

            schSoftBits = obj.pusch_demodulator_mex('step', rxSymbols, puschIndices, ce, PUSCHDemConfig, noiseVar);
        end % function step(...)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pusch_demodulator_mex(varargin)
    end % of methods (Access = private)

   methods (Static)
        function PUSCHDemCfg = configurePUSCHDem(pusch, NSizeGrid, puschDmrsIndices, placeholderReIndices, rxPorts)
        %configurePUSCHDem Static helper method for filling the PUSCHDEMCONFIG input of "step"
        %   PUSCHDEMCONFIG = configurePUSCHDem(PUSCH, NSIZEGRID, PUSCHDMRSINDICES, PLACEHOLDERREINDICES)
        %   generates a PUSCH demodulator configuration for the physical uplink
        %   shared channel PUSCH using the DMRS indices PUSCHDMRSINDICES and
        %   placeholder repetition indices PLACEHOLDERREINDICES for a grid of
        %   size NSIZEGRID and mapped to transmit antennas RXPORTS.
            arguments
                pusch                (1, 1) nrPUSCHConfig
                NSizeGrid            (1, 1) double {mustBeInteger, mustBePositive} = 25
                puschDmrsIndices     (:, 3) double {mustBeInteger, mustBeNonnegative} = [0, 0, 0]
                placeholderReIndices (:, 1) double {mustBeInteger, mustBeNonnegative} = [0]
                rxPorts              (:, 1) double {mustBeInteger, mustBeNonnegative} = [0]
            end

            import srsTest.helpers.symbolAllocationMask2string

            % Generate a PUSCH RB allocation mask string.
            rbAllocationMask = zeros(NSizeGrid, 1);
            rbAllocationMask(pusch.PRBSet + 1) = 1;

            % Generate a DM-RS symbol mask.
            dmrsSymbolMask = zeros(14, 1);
            for symbolIndex = puschDmrsIndices(:, 2)
                dmrsSymbolMask(symbolIndex + 1) = 1;
            end

            % Fill the configuration structure.
            PUSCHDemCfg.rnti = pusch.RNTI;
            PUSCHDemCfg.rbMask = rbAllocationMask;
            PUSCHDemCfg.modulation = pusch.Modulation;
            PUSCHDemCfg.startSymbolIndex = pusch.SymbolAllocation(1);
            PUSCHDemCfg.nofSymbols = pusch.SymbolAllocation(2);
            PUSCHDemCfg.dmrsSymbPos = dmrsSymbolMask;
            PUSCHDemCfg.dmrsConfigType = pusch.DMRS.DMRSConfigurationType;
            PUSCHDemCfg.nofCdmGroupsWithoutData = pusch.DMRS.NumCDMGroupsWithoutData;
            PUSCHDemCfg.nId = pusch.NID;
            PUSCHDemCfg.nofTxLayers = pusch.NumAntennaPorts;
            PUSCHDemCfg.placeholders = placeholderReIndices;
            PUSCHDemCfg.rxPorts = rxPorts;
        end % of function PUSCHDemCfg = configurePUSCHDem(...)
   end % of methods (Static)
end % of classdef srsPUSCHDemodulator < matlab.System
