%srsPRACHDetector MATLAB interface to srsRAN PRACH detector.
%   User-friendly interface to the srsRAN PRACH detector class, which is wrapped
%   by the MEX static method prach_detector_mex.
%
%   PRACHDET = srsPRACHDetector(DELAYSAMPLES) creates a PHY PRACH Detector
%   object with a fixed DFT size of 1536, which is meant to be tested with
%   a frequency-domain singal featuring a delay of DELAYSAMPLES samples.
%
%   srsPRACHDetector Properties (Nontunable):
%
%   delaySamples     - Number of delay samples passed during the MEX calls.
%
%   srsPRACHDetector Methods:
%
%   step               - Detects a PRACH preamble (if any is present).
%   configurePRACH     - Static helper method for filling the PRACHCONFIG input of "step".
%
%   Step method syntax
%
%   PRACHDETECTIONRESULT = step(PRACHDETECTOR, PRACHSYMBOLS, PRACHCONFIG) uses
%   the object PRACHDETECTOR to detect a PRACH preamble in the frequency-domain
%   signal PRACHSYMBOLS and returns the detection result PRACHDETECTIONRESULT.
%   PRACHSYMBOLS is a complex array which comprises the outputs of the PRACH
%   demodulator stage. Structure PRACHCONFIG describes the utilized PRACH
%   configuration parameters. The fields are
%      format                - the PRACH preamble format;
%      root_sequence_index   - the root sequence index;
%      restricted_set        - the restricted set configuration;
%      zero_correlation_zone - the zero correlation zone configuration index;
%      preamble_index        - the PRACH preamble index.
%   Structure PRACHDETECTIONRESULT provides the PRACH detection result. The
%   fields are
%      nof_detected_preambles - number of detected PRACH preambles (should be one);
%      preamble_index         - index of the detected PRACH preamble;
%      time_advance           - timing advance between the observed arrival time
%                               (for the considered UE) and the reference uplink time;
%      power_dB               - average RSRP value in dB;
%      snr_dB                 - average SNR value in dB;
%      rssi_dB                - average RSSI value in dB;
%      time_resolution        - detector time resolution;
%      time_advance_max       - detector maximum tine in advance.

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

classdef srsPRACHDetector < matlab.System
    properties (Nontunable)
          %Delay in samples.
          DelaySamples    (1, 1) double {mustBeInteger} = 0
    end % properties (Nontunable)

    methods
        function obj = srsPRACHDetector(varargin)
        %Constructor: sets nontunable properties.
            setProperties(obj, nargin, varargin{:});
        end % constructor
    end % of methods

    methods (Access = protected)
        function setupImpl(obj)
            % No setup.
        end % of setupImpl

        function PRACHdetectionResult = stepImpl(obj, PRACHSymbols, PRACHConfig)
            arguments
                obj          (1, 1) srsMEX.phy.srsPRACHDetector
                PRACHSymbols (:, 1) double
                PRACHConfig  (1, 1) struct
            end

            fcnName = [class(obj) '/step'];

            formatList = {'0', '1', '2', '3', 'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2'};
            validatestring(PRACHConfig.format, formatList, fcnName, 'FORMAT');
            validateattributes(PRACHConfig.root_sequence_index, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                 fcnName, 'ROOT_SEQUENCE_INDEX');
            restrictedSetList = {'UnrestrictedSet', 'RestrictedSetTypeA', 'RestrictedSetTypeB'};
            validatestring(PRACHConfig.restricted_set, restrictedSetList, fcnName, 'RESTRICTED_SET');
            validateattributes(PRACHConfig.zero_correlation_zone, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                 fcnName, 'ZERO_CORRELATION_ZONE');
            validateattributes(PRACHConfig.preamble_index, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                 fcnName, 'PREAMBLE_INDEX');
 
            PRACHdetectionResult = obj.prach_detector_mex('step', PRACHSymbols, PRACHConfig);
        end % function step(...)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = prach_detector_mex(varargin)
    end % of methods (Access = private)

   methods (Static)
        function PRACHCfg = configurePRACH(prach)
        %configurePRACH Static helper method for filling the PRACHCONFIG input of "step"
        %   PRACHCFG = configurePRACH(PRACH)
        %   generates a PRACH configuration for the preamble FORMAT,RESTRICTEDSET, 
        %   ZEROCORRLEATIONZONE, SEQUENCEINDEX AND PREAMBLEINDEX provided by the
        %   nrPRACHConfig PRACH object.
            arguments
                prach          (1, 1) nrPRACHConfig
            end

            PRACHCfg.format = prach.Format;
            PRACHCfg.root_sequence_index = prach.SequenceIndex;
            PRACHCfg.restricted_set = prach.RestrictedSet;
            PRACHCfg.zero_correlation_zone = prach.ZeroCorrelationZone;
            PRACHCfg.preamble_index = prach.PreambleIndex;
        end % of function configurePRACH = configurePRACH(...)
   end % of methods (Static)
end % of classdef srsPRACHDetector < matlab.System
