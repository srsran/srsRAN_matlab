%PRACHPERF PRACH performance simulator.
%   PRACHSIM = PRACHPERF creates a PRACH simulator object, PRACHSIM. This object
%   simulates transmission and detection of PRACH preambles according to the
%   specified setup (see list of PRACHPERF properties below).
%
%   Step method syntax
%
%   step(PRACHSIM, SNRIN) simulates the transmission of 10 PRACH occasions for
%   each one of the SNR values (dB) specified in SNRIN (a real-valued array).
%   The simulation follows the specifications of the conformance tests in
%   TS38.104 and TS38.141: at most one PRACH preamble is sent in each occasion
%   (none if testing the probability of false alarm), and the timing offset
%   is increased (cyclically) by 0.1 us at each new transmission. When the
%   simulation is over, the results will be available as properties of the
%   PRACHSIM object (see below).
%
%   step(PRACHSIM, SNRIN, NOCCASIONS) simulates the transmission of NOCCASIONS
%   PRACH occasions for each one of the SNR values (dB) specified in SNRIN
%   (a real-valued array).
%
%   Being a MATLAB system object, the PRACHSIM object may be called directly as
%   a function instead of using the step method. For example, step(PRACHSIM, SNRIN)
%   is equivalent to PRACHSIM(SNRIN).
%
%   Note: Successive calls of the step method will result in a combined set of
%   simulation results spanning all the provided SNR values (common SNR values
%   will be overwritten by the last call of the step method). Call the reset
%   method to start a new simulation from scratch without changing parameters.
%
%   Note: Calling the step method locks the object (the locked status can be
%   verified with the logical method isLocked). Once the object is locked,
%   simulation parameters cannot be changed (unless they are marked as tunable)
%   until the release method is called. It is worth mentioning that releasing
%   a PRACHPERF object implies resetting the simulation results.
%
%   Note: PRACHPERF objects can be saved and loaded normally as all MATLAB objects.
%   Saving an unlocked object only stores the simulation configuration. Saving
%   a locked object also stores all simulation results so that the simulation
%   can be resumed after loading the object.
%
%   Note: The default configuration corresponds to the 2-receive-antenna AWGN
%   test for Format 0 specified in TS38.104 Section 8.4.
%
%   PRACHPERF methods:
%
%   step        - Runs a PRACH simulation (see above).
%   release     - Allows property value changes (implies reset).
%   clone       - Creates PUSCHBLER object with same property values.
%   isLocked    - Locked status (logical).
%   reset       - Resets simulated data.
%   plot        - Plots throughput and BLER curves (if simulated data are present).
%
%   PRACHPERF properties (all nontunable, unless otherwise specified):
%
%   Format                  - Preamble format.
%   SequenceIndex           - Logical root sequence index of the target preamble (0...838).
%   PreambleIndex           - Preamble index within cell of the target preamble (0...63).
%   NCS                     - Cyclic shift width.
%   PUSCHSubcarrierSpacing  - PUSCH subcarrier spacing in kHz (15, 30, 120).
%   DelayProfile            - Channel delay profile ('AWGN', 'TDLC300').
%   NumReceiveAntennas      - Number of receive antennas.
%   FrequencyOffset         - Frequency offset in Hz.
%   TimeErrorTolerance      - Time error tolerance in microseconds.
%   TestType                - Test type ('Detection', 'False Alarm').
%   IgnoreCFO               - CFO flag: if true, the detector will assume perfect
%                             frequency synchronization (only for ImplementationType 'matlab').
%   DetectionThreshold      - Custom detection threshold (NaN for default or positive value,
%                             only for ImplementationType 'matlab').
%   ImplementationType      - PRACH detector implementation type('matlab', 'srs'). Default is 'matlab'.
%   QuickSimulation         - Quick-simulation flag: set to true to stop each point
%                             after 100 failures (tunable).
%
%   When the simulation is over, the object allows access to the following
%   results properties (depending on TestType).
%
%   SNRrange                     - Simulated SNR range in dB.
%   Occasions                    - Counter of the generated PRACH occasions (per SNR value).
%   Detected                     - Counter of detected occasions (per SNR value).
%   DetectedPerfect              - Counter of detected occasions (per SNR value).
%   ProbabilityDetection         - Detection probability (per SNR value).
%   ProbabilityDetectionPerfect  - Detection probability (per SNR value).
%   ProbabilityFalseAlarm        - False-alarm probability (per SNR value).
%   OffsetError                  - Mean and standard deviation of the estimation
%                                  error of the timing offset (microseconds).
%
%   Remark: The simulation loop is heavily based on the <a href="https://www.mathworks.com/help/5g/ug/5g-nr-prach-detection-test.html">NR PRACH Detection and False Alarm Test</a> MATLAB example by MathWorks.

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

classdef PRACHPERF < matlab.System
    properties (Nontunable)
        %Preamble format ('0', '1', '2', '3', 'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2').
        %   As defined in TS38.211 Tables 6.3.3.1-1 and 6.3.3.1-2.
        %   Default is '0'.
        Format (1, :) char {mustBeMember(Format, {'0', '1', '2', '3', 'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2'})} = '0'
        %Logical root sequence index of the target preamble (0...838).
        %   Default is 22.
        SequenceIndex (1, 1) double {mustBeInteger, mustBeNonnegative} = 22
        %Preamble index within cell of the target preamble (0...63).
        %   Default is 32.
        PreambleIndex  (1, 1) double {mustBeInteger, mustBeNonnegative} = 32
        %Cyclic shift width.
        %   Parameter NCS as defined in TS38.211 Tables 6.3.3.1-5, 6.3.3.1-6, 6.3.3.1-7.
        %   Default is 0.
        NCS (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
        %PUSCH subcarrier spacing in kHz (15, 30, 120).
        %   Default is 15 kHz.
        PUSCHSubcarrierSpacing (1, 1) double {mustBeMember(PUSCHSubcarrierSpacing, [15 30 120])} = 15
        %Channel delay profile ('AWGN', 'TDLA30', 'TDLC300').
        %   Default is 'AWGN'.
        DelayProfile (1, :) char {mustBeMember(DelayProfile, {'AWGN', 'TDLA30', 'TDLC300'})} = 'AWGN'
        %Number of receive antennas.
        %   Default is 2.
        NumReceiveAntennas (1, 1) double {mustBeInteger, mustBePositive, mustBeFinite} = 2
        %Frequency offset in Hz.
        %   Default is 0 Hz.
        FrequencyOffset (1, 1) double {mustBeReal, mustBeFinite} = 0;
        %Time error tolerance in microseconds.
        %   Default is 1.04 us.
        TimeErrorTolerance (1, 1) double {mustBePositive, mustBeFinite} = 1.04
        %Test type.
        %   Possible values are ('Detection', 'False Alarm'). Default is 'Detection'.
        TestType (1, :) char {mustBeMember(TestType, {'Detection', 'False Alarm'})} = 'Detection'
        %CFO flag: if true, the detector will assume perfect frequency synchronization.
        %   Only applies when ImplementationType is 'matlab'. For ImplementationType 'srs'
        %   this is assumed true.
        IgnoreCFO (1, 1) logical = true
        %Custom detection threshold (only for ImplementationType 'matlab').
        %   If NaN, the detector uses the default threshold value.
        DetectionThreshold (1, 1) double = NaN
        %PRACH detector implementation type('matlab', 'srs'). Default is 'matlab'.
        %   Both implementations refer to the same algorithm, but the 'srs' one runs the MEX version.
        ImplementationType (1, :) char {mustBeMember(ImplementationType, {'matlab', 'srs'})} = 'matlab'
    end

    properties (Access = private, Hidden)
        %Carrier configuration.
        Carrier
        %OFDM information.
        OFDMInfo
        %PRACH configuration.
        PRACH
        %Channel system object.
        Channel

        %Counter for the mean time offset estimation error.
        TimingAvg;
        %Counter for the variance of the time offset estimation error.
        TimingVar;
    end % of properties (Access = private, Hidden)

    properties (Access = private, Dependent, Hidden)
        %Boolean flag test type: true if strcmp(TestType, 'Detection'), false otherwise.
        isDetectionTest
    end % of properties (Access = private, Dependent, Hidden)

    properties (GetAccess = public, SetAccess = private)
        %SNR range in dB.
        SNRrange = []
        %Counter of the generated PRACH occasions (per SNR value).
        Occasions = []
        %Counter of detected occasions (per SNR value).
        %   Number of preambles detected correctly, regardless of the estimated offset.
        Detected = []
        %Counter of perfectly detected occasions (per SNR value).
        %   Number of preambles detected correctly, with the estimated offset within range.
        DetectedPerfect = []
    end % properties (SetAccess = private)

    properties (Dependent)
        %Detection probability (regardless of offset estimation).
        ProbabilityDetection
        %Detection probability (including of offset estimation within range).
        ProbabilityDetectionPerfect
        %False-alarm probability.
        ProbabilityFalseAlarm
        %Mean and standard deviation of the estimation error of the timing offset (microseconds).
        OffsetError
    end % of properties (Dependent)

    properties % Tunable
        %Quick-simulation flag: set to true to stop each SNR point after 100 failures.
        %   A failure is a missed detection when TestType == 'Detection' and a false detection
        %   when TestType == 'False Alarm'.
        QuickSimulation (1, 1) logical = true
    end % of properties Tunable

    methods (Access = private)
        function checkSeqIndexandFormat(obj)
            % Checks that Sequence Index is compatible with Format.
            switch obj.Format
                case {'0', '1', '2', '3'}
                    assert(obj.SequenceIndex < 838, 'srsran_matlab:PRACHPERF', ...
                        'For long formats, the sequence index must be between 0 and 837');
                case {'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2'}
                    assert(obj.SequenceIndex < 138, 'srsran_matlab:PRACHPERF', ...
                        'For long formats, the sequence index must be between 0 and 137');
            end
        end

        function checkNCSandFormat(obj)
            % Checks that NCS is compatible with Format.
            switch obj.Format
                case {'0', '1', '2'}
                    assert(ismember(obj.NCS, [0, 13, 15, 18, 22, 26, 32, 38, 46, 59, 76, 93, 119, 167, 279, 419]), ...
                        'NCS %d is not valid for long formats 0, 1, 2.', obj.NCS);
                case {'3'}
                    assert(ismember(obj.NCS, [0, 13, 26, 33, 38, 41, 49, 55, 64, 76, 93, 119, 139, 209, 279, 419]), ...
                        'NCS %d is not valid for long format 3.', obj.NCS);
                case {'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2'}
                    assert(ismember(obj.NCS, [0:2:12, 13:2:19, 23, 27, 34, 46, 69]), ...
                        'NCS %d is not valid for short formats.', obj.NCS);
            end
        end

        function checkSCSandFormat(obj)
            % Checks that the PUSCH subcarrier spacing is compatible with the Format.
            if (obj.PUSCHSubcarrierSpacing > 30)
                assert(ismember(obj.Format, {'A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'B4', 'C0', 'C2'}), ...
                    'Format %s is not valid in FR2.', obj.Format);
            end
        end % of function checkSCSandFormat(obj)

        function checkSCSandDelayProfile(obj)
            % Typically, it doesn't make much sense to test FR2 with heavy fading.
            if ((obj.PUSCHSubcarrierSpacing == 120) && strcmp(obj.DelayProfile, 'TDLC300'))
                warning('Testing heavy fading channels in FR2 is not recommended.');
            end
        end
    end % of methods (Access = private)

    methods (Access = protected)
        function setupImpl(obj)

            % Carrier configuration.
            obj.Carrier = nrCarrierConfig;
            obj.Carrier.SubcarrierSpacing = obj.PUSCHSubcarrierSpacing;
            obj.Carrier.NSizeGrid = 25; % PRBs

            % Compute the OFDM-related information.
            obj.OFDMInfo = nrOFDMInfo(obj.Carrier);

            % Pick the frequency range based on the PUSCH subcarrier spacing.
            if (obj.PUSCHSubcarrierSpacing <= 30)
                frequencyRange = 'FR1';
            else
                frequencyRange = 'FR2';
            end

            % Pick the duplexing mode based on the subcarrier spacing.
            if (obj.PUSCHSubcarrierSpacing == 15)
                duplexMode = 'FDD';
            else
                duplexMode = 'TDD';
            end


            preambleFormat = obj.Format;
            restrictedSet = 'UnrestrictedSet';

            % Define the value of ZeroCorrelationZone using the NCS table stored in
            % the nrPRACHConfig object.
            % Pick the subcarrier spacing.
            switch preambleFormat
                case {'0','1','2'}
                    ncsTable = nrPRACHConfig.Tables.NCSFormat012;
                    ncsTableCol = (string(ncsTable.Properties.VariableNames) == restrictedSet);
                    subcarrierSpacing = 1.25;
                case '3'
                    ncsTable = nrPRACHConfig.Tables.NCSFormat3;
                    ncsTableCol = (string(ncsTable.Properties.VariableNames) == restrictedSet);
                    subcarrierSpacing = 5;
                otherwise
                    ncsTable = nrPRACHConfig.Tables.NCSFormatABC;
                    ncsTableCol = contains(string(ncsTable.Properties.VariableNames), '139');
                    subcarrierSpacing = obj.PUSCHSubcarrierSpacing;
            end
            zeroCorrelationZone = ncsTable.ZeroCorrelationZone(ncsTable{:,ncsTableCol} == obj.NCS);

            % PRACH Configuration
            obj.PRACH = srsLib.phy.helpers.srsConfigurePRACH(preambleFormat, ...
                RestrictedSet=restrictedSet, ...             % Normal mode
                FrequencyStart=0, ...                        % Frequency location
                SequenceIndex=obj.SequenceIndex, ...         % Logical sequence index
                PreambleIndex=obj.PreambleIndex, ...         % Preamble index
                FrequencyRange=frequencyRange, ...           % Frequency range
                SubcarrierSpacing=subcarrierSpacing, ...     % Subcarrier spacing
                DuplexMode=duplexMode, ...                   % Duplexing mode
                ZeroCorrelationZone=zeroCorrelationZone ...  % Cyclic shift index.
            );

            % Propagation Channel Configuration
            if strcmp(obj.DelayProfile, 'AWGN')
                obj.Channel = TrivialChannel;
                obj.Channel.NumReceiveAntennas = obj.NumReceiveAntennas;
                obj.Channel.SampleRate = obj.OFDMInfo.SampleRate; % Input signal sample rate in Hz
            else
                obj.Channel = nrTDLChannel;
                obj.Channel.DelayProfile = obj.DelayProfile;      % Delay profile
                if strcmp(obj.DelayProfile, 'TDLC300')
                    obj.Channel.MaximumDopplerShift = 100.0;          % Maximum Doppler shift in Hz
                else % if strcmp(obj.DelayProfile, 'TDLA30')
                    obj.Channel.MaximumDopplerShift = 300.0;          % Maximum Doppler shift in Hz
                end
                obj.Channel.SampleRate = obj.OFDMInfo.SampleRate; % Input signal sample rate in Hz
                obj.Channel.MIMOCorrelation = "Low";              % MIMO correlation
                obj.Channel.TransmissionDirection = "Uplink";     % Uplink transmission
                obj.Channel.NumReceiveAntennas = obj.NumReceiveAntennas;
                                                                  % Number of receive antennas
                obj.Channel.NormalizePathGains = true;            % Normalize delay profile power
                % Global stream for a block fading model (each transmission undergoes
                % a different channel IR).
                obj.Channel.RandomStream = 'Global stream';
                obj.Channel.NormalizeChannelOutputs = true;       % Normalize for receive antennas
            end

        end % of function setupImpl(obj)

        function validatePropertiesImpl(obj)
            checkSeqIndexandFormat(obj);
            checkNCSandFormat(obj);
            checkSCSandFormat(obj);
            checkSCSandDelayProfile(obj);
        end

        function stepImpl(obj, SNRdB, nPRACHOccasions)
            arguments
                obj (1, 1) PRACHPERF
                %SNR range in dB.
                SNRdB double {mustBeReal, mustBeFinite, mustBeVector}
                %Number of PRACH occasions (default 10).
                nPRACHOccasions (1, 1) double {mustBeInteger, mustBePositive} = 10
            end

            % Ensure SNRIn has no repetitions and is a row vector.
            SNRdB = unique(SNRdB);
            SNRdB = SNRdB(:).';

            foffset = obj.FrequencyOffset;                 % Frequency offset in Hz.
            timeErrorTolerance = obj.TimeErrorTolerance;   % Time error tolerance in microseconds.

            % Initialize variables storing detection probability at each SNR.
            detectedCount = zeros(length(SNRdB), 1);
            detectedPerfCount = zeros(length(SNRdB), 1);
            occasionCount = nan(length(SNRdB), 1);
            meanOffsetError = zeros(length(SNRdB), 1);
            varOffsetError = zeros(length(SNRdB), 1);

            % Copy heavily-used nontunable objects.
            prach = obj.PRACH;
            ofdmInfo = obj.OFDMInfo;
            channel = obj.Channel;
            carrier = obj.Carrier;
            isDetectTest = obj.isDetectionTest;
            ignoreCFO = obj.IgnoreCFO;
            detectionThreshold = obj.DetectionThreshold;

            % Get the channel characteristic information.
            channelInfo = info(channel);

            % Implementation flag.
            useMEX = strcmp(obj.ImplementationType, 'srs');
            prachDetectorMex = srsMEX.phy.srsPRACHDetector;

            for snrIdx = 1:numel(SNRdB)

                % Display progress in the command window.
                timeNow = char(datetime('now','Format','HH:mm:ss'));
                fprintf([timeNow ': Simulating SNR = %+5.1f dB... '], SNRdB(snrIdx));

                % Set the random number generator settings to default values.
                % This ensures the randomly generated elements will be the same
                % for all SNR points.
                rng('default');

                % Normalize noise power to account for the sampling rate, which is a
                % function of the IFFT size used in OFDM modulation. The SNR is defined
                % per carrier resource element for each receive antenna.
                SNR = 10^(SNRdB(snrIdx)/10);
                N0 = 1/sqrt(2.0*channel.NumReceiveAntennas*double(ofdmInfo.Nfft)*SNR);

                % For each PRACH occasions...
                for iOccasion = 1:nPRACHOccasions

                    % Reset the channel before each transmission, to obtain a
                    % different realization (since we don't use an internal generator).
                    reset(channel);

                    % Generate PRACH waveform for the current occasion.
                    prach.NPRACHSlot = 0;

                    [waveform, gridset, winfo] = srsLib.phy.upper.channel_processors.srsPRACHgenerator(carrier, prach);

                    % Set PRACH timing offset in microseconds as per TS 38.141-1 Figure 8.4.1.4.2-2
                    % and Figure 8.4.1.4.2-3.
                    if (prach.LRA == 839) % Long preamble, values as in Figure 8.4.1.4.2-2.
                        baseOffset = ((winfo.PRACHSymbolsInfo.NumCyclicShifts/2)/prach.LRA)/prach.SubcarrierSpacing*1e3; % (microseconds)
                        timingOffset = baseOffset + mod(iOccasion - 1, 10)/10; % (microseconds)
                    else % Short preamble, values as in Figure 8.4.1.4.2-3.
                        baseOffset = 0; % (microseconds)
                        timingOffset = baseOffset + mod(iOccasion - 1, 9)/10; % (microseconds)
                    end
                    sampleDelay = fix(timingOffset / 1e6 * ofdmInfo.SampleRate);

                    % Generate transmit waveform.
                    txwave = [zeros(sampleDelay,1); waveform];

                    % Pass data through channel model. Append zeros at the end of the
                    % transmitted waveform to flush channel content. These zeros take
                    % into account any delay introduced in the channel. This is a mix
                    % of multipath delay and implementation delay. This value may
                    % change depending on the sampling rate, delay profile and delay
                    % spread.
                    rxwave = channel([txwave; zeros(channelInfo.MaximumChannelDelay, size(txwave,2))]);

                    % Add noise.
                    noise = N0 * complex(randn(size(rxwave)), randn(size(rxwave)));
                    if isDetectTest
                        rxwave = rxwave + noise;
                    else
                        % This is not very efficient, but it's the easiest way to have
                        % structs "gridset" and "winfo" filled in even when testing
                        % false-alarm probability.
                        rxwave = noise;
                    end

                    % Remove the implementation delay of the channel filter.
                    rxwave = rxwave((channelInfo.ChannelFilterDelay + 1):end, :);

                    % Apply frequency offset.
                    t = ((0:size(rxwave, 1)-1)/channel.SampleRate).';
                    rxwave = rxwave .* repmat(exp(1i*2*pi*foffset*t), 1, size(rxwave, 2));

                    % Rx side PRACH configuration.
                    prachRx = prach;
                    % Remove the preamble index, unknown at the Rx.
                    prachRx.PreambleIndex = 0;
                    % Pick the correct PRACH slot.
                    prachRx.NPRACHSlot = winfo.NPRACHSlot;

                    % Demodulate the PRACH waveform.
                    prachDemodulated = srsLib.phy.lower.modulation.srsPRACHdemodulator(carrier, ...
                        prachRx, gridset.Info, rxwave, winfo);

                    if useMEX
                        prachDemodulated = reshape(prachDemodulated, prach.LRA, [], obj.NumReceiveAntennas);
                        prachResults = prachDetectorMex(prachRx, prachDemodulated);
                        indicesMask = false(64, 1);
                        indicesMask(prachResults.PreambleIndices + 1) = true;
                        offsets = nan(64, 1);
                        offsets(prachResults.PreambleIndices + 1) = prachResults.TimeAdvance * 1e6;
                    else
                        % PRACH detection for all cell preamble indices.
                        [indicesMask, offsets] = srsLib.phy.upper.channel_processors.srsPRACHdetector(carrier, prachRx, ...
                            prachDemodulated, ignoreCFO, detectionThreshold);
                    end

                    % Test for preamble detection.
                    if any(indicesMask)
                        if ~isDetectTest
                            % For the false alarm test, any preamble detected is wrong.
                            detectedCount(snrIdx) = detectedCount(snrIdx) + 1;
                        else
                            % Test for correct preamble detection.
                            if indicesMask(prach.PreambleIndex + 1)
                                detectedCount(snrIdx) = detectedCount(snrIdx) + 1; % Detected preamble

                                % Calculate timing estimation error.
                                measuredOffset = offsets(prach.PreambleIndex + 1);
                                timingerror = abs(measuredOffset-timingOffset);
                                meanOffsetError(snrIdx) = meanOffsetError(snrIdx) + timingerror;
                                varOffsetError(snrIdx) = varOffsetError(snrIdx) + timingerror^2;

                                % Test for acceptable timing error
                                if (timingerror <= timeErrorTolerance)
                                    % Detected preamble with timing error within tollerance.
                                    detectedPerfCount(snrIdx) = detectedPerfCount(snrIdx) + 1;
                                end
                            end
                        end
                    end % of if (sum(indicesMask)==1)

                    % To speed the simulation up, we stop after 100 failures.
                    if obj.QuickSimulation && ((isDetectTest && (iOccasion - detectedCount(snrIdx) > 100)) ...
                            || (~isDetectTest && (detectedCount(snrIdx) > 100)))
                        break;
                    end

                end % for iOccasion = 1:nPRACHOccasions

                occasionCount(snrIdx) = iOccasion;

                if isDetectTest
                    % Display the detection probability for this SNR.
                    fprintf('Detection probability (ignoring time error):        %.2f%%\n', ...
                        detectedCount(snrIdx)/iOccasion*100);
                    fprintf('                                       ');
                    fprintf('Detection probability (time error below tolerance): %.2f%%\n', ...
                        detectedPerfCount(snrIdx)/iOccasion*100);
                    meanErr = meanOffsetError(snrIdx) / iOccasion;
                    stdErr = sqrt((varOffsetError(snrIdx) - meanErr^2) / max(1, iOccasion-1));
                    fprintf('                                       ');
                    fprintf('Time error:                                         %.2g +/- %.2g\n', ...
                        meanErr, stdErr);
                else
                    % Display the false alarm probability for this SNR.
                    fprintf('False-alarm probability: %.2f%%\n', detectedCount(snrIdx)/iOccasion*100);
                end

            end % of SNR loop

            % Export results.
            [~, repeatedIdx] = intersect(obj.SNRrange, SNRdB);
            obj.SNRrange(repeatedIdx) = [];
            [obj.SNRrange, sortedIdx] = sort([obj.SNRrange SNRdB]);

            obj.Occasions = joinArrays(obj.Occasions, occasionCount, repeatedIdx, sortedIdx);
            obj.Detected = joinArrays(obj.Detected, detectedCount, repeatedIdx, sortedIdx);
            obj.DetectedPerfect = joinArrays(obj.DetectedPerfect, detectedPerfCount, ...
                repeatedIdx, sortedIdx);
            obj.TimingAvg = joinArrays(obj.TimingAvg, meanOffsetError, repeatedIdx, sortedIdx);
            obj.TimingVar = joinArrays(obj.TimingVar, varOffsetError, repeatedIdx, sortedIdx);
        end % of function setupImpl(obj)

        function flag = isInactivePropertyImpl(obj, property)
            switch property
                case {'SNRrange', 'Occasions', 'Detected'}
                    flag = isempty(obj.SNRrange) || ~obj.isLocked;
                case 'ProbabilityDetection'
                    flag = isempty(obj.Detected) || ~obj.isDetectionTest || ~obj.isLocked;
                case {'DetectedPerfect', 'ProbabilityDetectionPerfect'}
                    flag = isempty(obj.DetectedPerfect) || ~obj.isDetectionTest || ~obj.isLocked;
                case 'ProbabilityFalseAlarm'
                    flag = isempty(obj.Detected) || obj.isDetectionTest || ~obj.isLocked;
                case 'OffsetError'
                    flag = isempty(obj.TimingAvg) || ~obj.isDetectionTest || ~obj.isLocked;
                case {'DetectionThreshold', 'IgnoreCFO'}
                    flag = ~strcmp(obj.ImplementationType, 'matlab');
                otherwise
                    flag = false;
            end
        end % of function flag = isInactivePropertyImpl(obj, property)

        function groups = getPropertyGroups(obj)
            props = properties(obj);
            results = {'SNRrange', 'Occasions', 'Detected', 'DetectedPerfect', ...
                'ProbabilityDetection', 'ProbabilityDetectionPerfect', ...
                'ProbabilityFalseAlarm', 'OffsetError'};
            confProps = setdiff(props, results);
            groups = matlab.mixin.util.PropertyGroup(confProps, 'Configuration');

            resProps = {};
            for i = 1:numel(results)
                tt = results{i};
                if ~isInactivePropertyImpl(obj, tt)
                    resProps = [resProps, tt]; %#ok<AGROW>
                end
            end
            if ~isempty(resProps)
                groups = [groups, matlab.mixin.util.PropertyGroup(resProps, 'Simulation Results')];
            end
        end

        function resetImpl(obj)
            % Reset internal system objects.
            reset(obj.Channel);

            % Reset simulation results.
            obj.SNRrange = [];
            obj.Occasions = [];
            obj.Detected = [];
            obj.DetectedPerfect = [];
            obj.TimingAvg = [];
            obj.TimingVar = [];
        end

        function releaseImpl(obj)
            % Release internal system objects.
            release(obj.Channel);
        end

        function s= saveObjectImpl(obj)
            % Save all public properties.
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                % Save child objects.
                s.Channel = matlab.System.saveObject(obj.Channel);
                s.Carrier = obj.Carrier;
                s.OFDMInfo = obj.OFDMInfo;
                s.PRACH = obj.PRACH;

                % Save counters.
                s.SNRrange = obj.SNRrange;
                s.Occasions = obj.Occasions;
                s.Detected = obj.Detected;
                s.DetectedPerfect = obj.DetectedPerfect;
                s.TimingAvg = obj.TimingAvg;
                s.TimingVar = obj.TimingVar;
            end
        end % of function s= saveObjectImpl(obj)

        function loadObjectImpl(obj, s, wasInUse)
            if wasInUse
                % Load child objects.
                obj.Channel = matlab.System.loadObject(s.Channel);
                obj.Carrier = s.Carrier;
                obj.OFDMInfo = s.OFDMInfo;
                obj.PRACH = s.PRACH;

                % Load counters.
                obj.SNRrange = s.SNRrange;
                obj.Occasions = s.Occasions;
                obj.Detected = s.Detected;
                obj.DetectedPerfect = s.DetectedPerfect;
                obj.TimingAvg = s.TimingAvg;
                obj.TimingVar = s.TimingVar;
            end

            % Load public properties.
            loadObjectImpl@matlab.System(obj, s, wasInUse);
        end % function loadObjectImpl(obj, s, wasInUse)

    end % of methods (Access = protected)

    methods % public
        function pfa = get.ProbabilityFalseAlarm(obj)
            if strcmp(obj.TestType, 'Detection')
                warning('off', 'backtrace');
                warning('The ProababilityFalseAlarm property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                pfa = [];
                return
            end
            pfa = obj.Detected ./ obj.Occasions;
        end

        function pdet = get.ProbabilityDetection(obj)
            if strcmp(obj.TestType, 'False Alarm')
                warning('off', 'backtrace');
                warning('The ProababilityDetection property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                pdet = [];
                return
            end
            pdet = obj.Detected ./ obj.Occasions;
        end

        function pdet = get.ProbabilityDetectionPerfect(obj)
            if strcmp(obj.TestType, 'False Alarm')
                warning('off', 'backtrace');
                warning('The ProababilityDetectionPerfect property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                pdet = [];
                return
            end
            pdet = obj.DetectedPerfect ./ obj.Occasions;
        end

        function offerr = get.OffsetError(obj)
            if strcmp(obj.TestType, 'False Alarm')
                warning('off', 'backtrace');
                warning('The OffsetError property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                offerr = [];
                return
            end
            meanErr = obj.TimingAvg ./ obj.Occasions;
            stdErr = sqrt((obj.TimingVar - meanErr.^2) ./ max(1, obj.Occasions-1));
            offerr = [meanErr stdErr];
        end

        function isDT = get.isDetectionTest(obj)
            isDT = strcmp(obj.TestType, 'Detection');
        end

        function set.DetectionThreshold(obj, value)
            if (isnan(value) || (isfinite(value) && (value > 0)))
                obj.DetectionThreshold = value;
            else
                error('DetectionThreshold should be either positive or NaN for default value.');
            end
        end % of function set.DetectionThreshold(obj, value)

        function plot(obj)
            % Plot detection or false-alarm probability.
            if strcmp(obj.TestType, 'Detection')
                figName = 'Detection Probability';
            else
                figName = 'False-Alarm Probability';
            end

            figure('Name', figName);
            plot(obj.SNRrange, obj.DetectedPerfect ./ obj.Occasions, 'o-.', 'LineWidth', 1);
            title([obj.DelayProfile ' - ' num2str(obj.NumReceiveAntennas) ' Rx ant - ' ...
                num2str(max(obj.Occasions)) ' PRACH occasions - Fmt ' obj.Format] );
            xlabel('SNR (dB)'); ylabel(figName); grid on
        end % of function plot(obj)

    end % methods public
end % of classdef PRACHPERF < matlab.System

% %% Local Functions
function mixedArray = joinArrays(arrayA, arrayB, removeFromA, outputOrder)
    arrayA(removeFromA) = [];
    mixedArray = [arrayA; arrayB];
    mixedArray = mixedArray(outputOrder);
end
