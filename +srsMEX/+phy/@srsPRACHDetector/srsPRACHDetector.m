%srsPRACHDetector MATLAB interface to srsRAN PRACH detector.
%   User-friendly interface to the srsRAN PRACH detector class, which is wrapped
%   by the MEX static method prach_detector_mex.
%
%   PRACHDETECTOR = srsPRACHDetector creates a PHY PRACH Detector object.
%
%   srsPRACHDetector Methods:
%
%   step               - Detects a PRACH preamble (if any is present).
%
%   Step method syntax
%
%   DETECTIONRESULTS = step(PRACHDETECTOR, PRACH, SYMBOLS) uses
%   the object PRACHDETECTOR to detect a PRACH preamble in the frequency-domain
%   signal SYMBOLS and returns the detection results DETECTIONRESULTS.
%
%   PRACH is a PRACH configuration object, nrPRACHConfig. Only these object properties
%   are relevant for this function:
%      Format                - the PRACH preamble format;
%      SequenceIndex         - the root sequence index;
%      RestrictedSet         - the restricted set configuration;
%      ZeroCorrelationZone   - the zero correlation zone configuration index;
%      SubcarrierSpacing     - the PRACH subcarrier spacing.
%
%   SYMBOLS is a complex array which comprises the outputs of the PRACH
%   demodulator stage.
%
%   Structure DETECTIONRESULTS provides the PRACH detection results. The
%   fields are
%      NumDetectedPreambles - number of detected PRACH preambles;
%      RSSIDecibel          - average RSSI value in dB;
%      TimeResolution       - detector time resolution;
%      MaxTimeAdvance       - detector maximum tolerated time advance;
%      PreambleIndices      - array of indices of the detected PRACH preambles;
%      TimeAdvance          - array of timing advance values between the observed arrival time
%                             (for the corresponding preamble indices) and the reference uplink time;
%      NormalizedMetric     - array of detection metrics, normalized with respect to the
%                             detection threshold.

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

classdef srsPRACHDetector < matlab.System
    methods (Access = protected)
        function PRACHdetectionResult = stepImpl(obj, prach, symbols)
            arguments
                obj     (1, 1)    srsMEX.phy.srsPRACHDetector
                prach   (1, 1)    nrPRACHConfig
                symbols (:, :, :) double
            end

            PRACHCfg = struct(...
                'Format', prach.Format, ...
                'SequenceIndex', prach.SequenceIndex, ...
                'RestrictedSet', prach.RestrictedSet, ...
                'ZeroCorrelationZone', prach.ZeroCorrelationZone, ...
                'SubcarrierSpacing', prach.SubcarrierSpacing ...
                );

            PRACHdetectionResult = obj.prach_detector_mex('step', symbols, PRACHCfg);
        end % function step(...)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = prach_detector_mex(varargin)
    end % of methods (Access = private)

end % of classdef srsPRACHDetector < matlab.System
