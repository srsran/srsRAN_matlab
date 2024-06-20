%PUSCHBLER PUSCH block error rate and throughput simulator.
%   PUSCHSIM = PUSCHBLER creates a PUSCH simulator object, PUSCHSIM. This object
%   simulates a PUSCH transmission according to the specified setup (see list of
%   PUSCHBLER properties below).
%
%   Step method syntax
%
%   step(PUSCHSIM, SNRIN) runs a PUSCH simulation corresponding to ten 10-ms
%   frames for each one of the SNR values (dB) specified in SNRIN (a real-valued array).
%   When the simulation is over, the results will be available as properties of
%   the PUSCHSIM object (see below).
%
%   step(PUSCHSIM, SNRIN, NFRAMES) runs simulations corresponding to NFRAMES 10-ms
%   frames. Setting parameter QuickSimulation to true, each simulated point is
%   stopped earlier when reaching 100 failed transport block transmissions.
%
%   Being a MATLAB system object, the PUSCHSIM object may be called directly as
%   a function instead of using the step method. For example, step(PUSCHSIM, SNRIN)
%   is equivalent to PUSCHSIM(SNRIN).
%
%   Note: Successive calls of the step method will result in a combined set
%   of simulation results spanning all the provided SNR values (common SNR values
%   will be overwritten by the last call of the step method). Call the reset
%   method to start a new simulation from scratch without changing the parameters.
%
%   Note: Calling the step method locks the object (the locked status can be
%   verified with the logical method isLocked). Once the object is locked,
%   simulation parameters cannot be changed (unless they are marked as tunable)
%   until the release method is called. It is worth mentioning that releasing
%   a PUSCHBLER object implies resetting the simulation results.
%
%   Note: PUSCHBLER objects can be saved and loaded normally as all MATLAB objects.
%   Saving an unlocked object only stores the simulation configuration. Saving
%   a locked object also stores all simulation results so that the simulation
%   can be resumed after loading the object.
%
%   PUSCHBLER methods:
%
%   step        - Runs a PUSCH simulation (see above).
%   release     - Allows property value changes (implies reset).
%   clone       - Creates PUSCHBLER object with same property values.
%   isLocked    - Locked status (logical).
%   reset       - Resets simulated data.
%   plot        - Plots throughput and BLER curves (if simulated data are present).
%
%   PUSCHBLER properties (all nontunable, unless otherwise specified):
%
%   NTxAnts                      - Number of transmit antennas (temporarily
%                                  constant and fixed to 1).
%   NRxAnts                      - Number of receive antennas.
%   PerfectChannelEstimator      - Perfect channel estimation flag.
%   DisplaySimulationInformation - Flag for displaying simulation information.
%   DisplayDiagnostics           - Flag for displaying simulation diagnostics.
%   NSizeGrid                    - Bandwidth as a number of resource blocks.
%   SubcarrierSpacing            - Subcarrier spacing in kHz.
%   CyclicPrefix                 - Cyclic prefix: 'Normal' or 'Extended'
%                                  (Extended CP is relevant for 60 kHz SCS only).
%   NCellID                      - Cell identity.
%   PRBSet                       - PUSCH allocated PRBs (specify as an array, e.g. 0:51).
%   SymbolAllocation             - PUSCH OFDM symbol allocation.
%   MappingType                  - PUSCH mapping type ('A'(slot-wise), 'B'(non slot-wise)).
%   RNTI                         - Radio network temporary identifier (0...65535).
%   NumLayers                    - Number of PUSCH transmission layers (1...4).
%   MCSTable                     - Modulation Coding Scheme table.
%   MCSIndex                     - Modulation Coding Scheme index
%                                  (inactive if "MCSTable == 'custom'").
%   Modulation                   - Modulation scheme (inactive if "MCSTable == 'custom'").
%   TargetCodeRate               - Target code rate (inactive if "MCSTable == 'custom'").
%   DMRSTypeAPosition            - First DM-RS symbol position (2, 3)
%                                  (relevant only for mapping type A).
%   DMRSLength                   - Number of front-loaded DM-RS symbols
%                                  (1(single symbol), 2(double symbol)).
%   DMRSAdditionalPosition       - Additional DM-RS symbol positions (0...3).
%   DMRSConfigurationType        - DM-RS configuration type (1, 2).
%   DelayProfile                 - Channel delay profile ('AWGN'(no delay, no Doppler), 'single-tap'
%                                  (only one tap, no Doppler), 'TDL-A', 'TDLA30', 'TDL-B', 'TDLB100',
%                                  'TDL-C', 'TDLC300').
%   DelaySpread                  - Delay spread in seconds (single-tap and TDL-{A,B,C} delay profiles only).
%   MaximumDopplerShift          - Maximum Doppler shift in hertz (TDL delay profiles only).
%   EnableHARQ                   - HARQ flag: true for enabling retransmission with
%                                  RV sequence [0, 2, 3, 1], false for no retransmissions.
%   ImplementationType           - PUSCH implementation type ('matlab', 'srs' (requires mex), 'both')
%   SRSEstimatorType             - Implementation of the SRS channel estimator ('MEX', 'noMEX')
%   QuickSimulation              - Quick-simulation flag: set to true to stop
%                                  each point after 100 failed transport blocks (tunable).
%   ApplyOFHCompression          - Emulate the effect of O-FH compression on the received grid: set to true 
%                                  to enable (tunable).
%   CompIQwidth                  - Bit-width of the compressed IQ samples (1...16). Used only if 
%                                  'ApplyOFHCOmpression' is set to true.
%
%   When the simulation is over, the object allows access to the following
%   results properties.
%
%   SNRrange              - Simulated SNR range in dB.
%   MaxThroughputCtr      - Counter of transmitted transport blocks.
%   ThroughputMATLABCtr   - Counter of correctly received transport blocks (MATLAB case).
%   ThroughputSRSCtr      - Counter of correctly received transport blocks (SRS case).
%   TotalBlocksCtr        - Counter of newly transmitted transport blocks (ignoring repetitions).
%   MissedBlocksMATLABCtr - Counter of missed transport blocks, after all
%                           allowed retransmissions (MATLAB case).
%   MissedBlocksSRSCtr    - Counter of missed transport blocks, after all
%                           allowed retransmissions (SRS case).
%   TBS                   - Transport block size in bits.
%   MaxThroughput         - Maximum achievable throughput in Mbps.
%   ThroughputMATLAB      - Throughput in Mbps (MATLAB case).
%   ThroughputSRS         - Throughput in Mbps (SRS case).
%   BlockErrorRateMATLAB  - Transport block error rate (MATLAB case).
%   BlockErrorRateSRS     - Transport block error rate (SRS case).
%
%   Remark: The simulation loop is heavily based on the <a href="https://www.mathworks.com/help/5g/ug/nr-pusch-throughput.html">NR PUSCH Throughput</a> MATLAB example by MathWorks.

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

classdef PUSCHBLER < matlab.System
    properties (Constant)
        %Number of transmit antennas.
        NTxAnts = 1
    end % of constant properties

    properties (Nontunable)
        %Perfect channel estimation flag.
        PerfectChannelEstimator (1, 1) logical = true
        %Number of receive antennas.
        NRxAnts = 1
        %Bandwidth in number of resource blocks.
        NSizeGrid = 52
        %Subcarrier spacing in kHz (15, 30, 60, 120).
        SubcarrierSpacing = 15
        %Cyclic prefix: 'Normal' or 'Extended' (Extended CP is relevant for 60 kHz SCS only).
        CyclicPrefix = 'Normal'
        %Cell identity.
        NCellID (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1
        %PUSCH allocated PRBs.
        PRBSet = 0:51
        %PUSCH OFDM symbol allocation in each slot.
        %   Specify as a two-element array, where the first element represents the
        %   start of symbol allocation (0-based) and the second element represents
        %   the number of allocated OFDM symbols (e.g., [0 14]).
        SymbolAllocation = [0, 14]
        %PUSCH mapping type ('A'(slot-wise), 'B'(non slot-wise)).
        MappingType (1, 1) char {mustBeMember(MappingType, ['A', 'B'])} = 'A'
        %Radio network temporary identifier (0...65535).
        RNTI (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(RNTI, 0, 65535)} = 1
        %Number of PUSCH transmission layers.
        NumLayers (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(NumLayers, 1, 4)} = 1
        %Modulation Coding Scheme table.
        %   Choose between 'qam64', 'qam256', 'qam64LowSE' and 'custom'.
        MCSTable (1, :) char {mustBeMember(MCSTable, {'qam64', 'qam256', 'qam64LowSE', 'custom'})} = 'qam64'
        %Modulation Coding Scheme index (inactive if "MCSTable == 'custom'").
        MCSIndex (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(MCSIndex, 0, 28)} = 0
        %Modulation scheme (only when "MCSTable == 'custom'").
        %   Choose between 'pi/2-BPSK', 'QPSK', '16QAM', '64QAM' and '256QAM'.
        Modulation (1, :) char {mustBeMember(Modulation, {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'})} = 'QPSK'
        %Target code rate (only when "MCSTable == 'custom'").
        %   A real number between 0 and 1, excluded.
        TargetCodeRate (1, 1) double {mustBeReal, mustBeInRange(TargetCodeRate, 0, 1, 'exclusive')} = 193 / 1024
        %Mapping type A only: First DM-RS symbol position (2, 3).
        DMRSTypeAPosition (1, 1) double {mustBeReal, mustBeMember(DMRSTypeAPosition, [2, 3])} = 2
        %Number of front-loaded DM-RS symbols (1(single symbol), 2(double symbol)).
        DMRSLength (1, 1) double {mustBeReal, mustBeMember(DMRSLength, [1, 2])} = 1
        %Additional DM-RS symbol positions (max range 0...3).
        DMRSAdditionalPosition (1, 1) double {mustBeReal, mustBeMember(DMRSAdditionalPosition, [0, 1, 2, 3])} = 1
        %DM-RS configuration type (1, 2).
        DMRSConfigurationType (1, 1) double {mustBeReal, mustBeMember(DMRSConfigurationType, [1, 2])} = 1
        %Channel delay profile ('AWGN'(no delay), 'TDL-A', 'TDLA30' 'TDL-B', 'TDLB100',
        %   'TDL-C', 'TDLC300').
        DelayProfile (1, :) char {mustBeMember(DelayProfile, {'AWGN', 'single-tap', 'TDL-A', 'TDLA30', ...
            'TDL-B', 'TDLB100', 'TDL-C', 'TDLC300'})} = 'AWGN'
        %Delay spread in seconds.
        %   Tap delay for 'single-tap' profile.
        %   Delay spread for 'TDL-A', 'TDL-B' and 'TDL-C', as defined by the 3GPP model.
        %   Does not apply for the simplified models 'TDLA30', 'TDLB100' and 'TDLC300'.
        DelaySpread (1, 1) double {mustBeReal, mustBeNonnegative} = 30e-9
        %TDL delay profiles only: Maximum Doppler shift in hertz.
        MaximumDopplerShift (1, 1) double {mustBeReal, mustBeNonnegative} = 0
        %Carrier frequency offset in hertz (requires PerfectChannelEstimator set to false).
        CarrierFrequencyOffset (1, 1) double {mustBeReal} = 0
        %HARQ flag: true for enabling retransmission with RV sequence [0, 2, 3, 1], false for no retransmissions.
        EnableHARQ (1, 1) logical = false
        %PUSCH implementation type ('matlab', 'srs' (requires mex), 'both').
        ImplementationType (1, :) char {mustBeMember(ImplementationType, {'matlab', 'srs', 'both'})} = 'matlab'
        %Implementation of the SRS channel estimator ('MEX', 'noMEX').
        %   Only applies if ImplementationType is set to 'srs' or 'both' and PerfectChannelEstimator
        %   is set to false.
        SRSEstimatorType (1, :) char {mustBeMember(SRSEstimatorType, {'MEX', 'noMEX'})} = 'MEX'
        %Flag for emulating O-FH compression.
        ApplyOFHCompression (1, 1) logical = false
        %Bit-width of the compressed IQ samples.
        %   Only applies if ApplyOFHCompression is set to true.
        CompIQwidth (1, 1) double {mustBeInteger, mustBeInRange(CompIQwidth, 1, 16)} = 9
    end % of properties (Nontunable)

    properties % Tunable
        %Flag for displaying simulation information.
        DisplaySimulationInformation (1, 1) logical = false
        %Flag for displaying simulation diagnostics.
        DisplayDiagnostics (1, 1) logical = false
        %Quick-simulation flag: set to true to stop each point after 100 failed transport blocks.
        QuickSimulation (1, 1) logical = true
    end % of properties Tunable

    properties (SetAccess = private)
        %SNR range in dB.
        SNRrange = []
        %Counter of all transmitted transport blocks.
        MaxThroughputCtr = []
        %Counter of correctly received transport blocks (MATLAB case).
        ThroughputMATLABCtr = []
        %Counter of correctly received transport blocks (SRS case).
        ThroughputSRSCtr = []
        %Counter of newly transmitted transport blocks (ignoring repetitions).
        TotalBlocksCtr = []
        %Counter of missed transport blocks, after all allowed retransmissions (MATLAB case).
        MissedBlocksMATLABCtr = []
        %Counter of missed transport blocks, after all allowed retransmissions (SRS case).
        MissedBlocksSRSCtr = []
        %Transport block size in bits.
        TBS = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %Maximum achievable throughput (in Mbps).
        MaxThroughput
        %Throughput in Mbps (MATLAB case).
        ThroughputMATLAB
        %Throughput in Mbps (SRS case).
        ThroughputSRS
        %Block error rate (MATLAB case).
        BlockErrorRateMATLAB
        %Block error rate (SRS case).
        BlockErrorRateSRS
    end % of properties (Dependable)

    properties (Access = private, Hidden)
        %Carrier configuration.
        Carrier
        %FFT size.
        Nfft
        %PUSCH configuration.
        PUSCH
        %Extra PUSCH parameters.
        PUSCHExtension
        %Channel system object.
        Channel
        %ULSCH encoder (MATLAB).
        EncodeULSCH
        %ULSCH decoder (MATLAB).
        DecodeULSCH
        %ULSCH decoder (SRS).
        DecodeULSCHsrs
        %PUSCH resource element indices.
        PUSCHIndices
        %PUSCH resource information.
        PUSCHIndicesInfo
        %Transport block segmentation configuration.
        SegmentCfg
    end % of properties (Access = private, Hidden)

    methods (Access = private)
        function checkSCSandCP(obj)
            if (strcmp(obj.CyclicPrefix, 'Extended') && (obj.SubcarrierSpacing ~= 60))
                error('CyclicPrefix ''Extended'' and SubcarrierSpacing %d kHz are incompatible.', obj.SubcarrierSpacing);
            end
        end

        function checkPRBSetandGrid(obj)
            if (max(obj.PRBSet) > obj.NSizeGrid - 1)
                error('PRB allocation and resource grid are incompatible.');
            end
        end

        function checkHARQandDecType(obj)
            if (obj.EnableHARQ && strcmp(obj.ImplementationType, 'both'))
                error('Cannot run both decoders when HARQ is enabled.');
            end
        end

        function checkCFOandEstimator(obj)
            if (obj.PerfectChannelEstimator && (obj.CarrierFrequencyOffset ~= 0))
                error('Cannot set a non-null carrier frequency offset with perfect channel estimation.');
            end
        end
    end % of methods (Access = private)

    methods % public
        function set.NSizeGrid(obj, value)
            validateattributes(value, 'numeric', {'real', 'scalar', '>', 0});
            obj.NSizeGrid = value;
        end

        function set.SubcarrierSpacing(obj, value)
            validateattributes(value, 'numeric', {'real', 'scalar'});
            mustBeMember(value, [15, 30, 60, 120])

            obj.SubcarrierSpacing = value;
        end

        function set.CyclicPrefix(obj, value)
            validateattributes(value, 'char', {});
            mustBeMember(value, {'Normal', 'Extended'})

            obj.CyclicPrefix = value;
        end

        function set.PRBSet(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'vector', 'nonempty', ...
                '>=', 0, '<=', 274});
            obj.PRBSet = value;
        end

        function set.SymbolAllocation(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'size', [1, 2], '>=', 0, '<=', 14});
            if (value(1) + value(2) > 14)
                error('Cannot allocate %d OFDM symbols starting from OFDM symbol %d.', value(2), value(1));
            end
            obj.SymbolAllocation = value;
        end

        function tp = get.ThroughputMATLAB(obj)
            tp = 1e-6 * obj.ThroughputMATLABCtr ./ (obj.MaxThroughputCtr / obj.TBS * 1e-3) ...
                * obj.SubcarrierSpacing / 15;
        end

        function tp = get.ThroughputSRS(obj)
            tp = 1e-6 * obj.ThroughputSRSCtr ./ (obj.MaxThroughputCtr / obj.TBS * 1e-3) ...
                * obj.SubcarrierSpacing / 15;
        end

        function bler = get.BlockErrorRateMATLAB(obj)
            bler = obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function bler = get.BlockErrorRateSRS(obj)
            bler = obj.MissedBlocksSRSCtr ./ obj.TotalBlocksCtr;
        end

        function maxTP = get.MaxThroughput(obj)
            maxTP = obj.TBS * 1e-3 * obj.SubcarrierSpacing / 15;
        end

        function plot(obj)
        %Display the measured throughput and BLER.

            if (isempty(obj.SNRrange))
                warning('Empty simulation data.');
                return;
            end

            implementationType = obj.ImplementationType;

            plotMATLABDecoder = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
            plotSRSDecoder = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

            titleString = sprintf('NRB=%d / SCS=%dkHz / %s %d/1024', ...
                obj.NSizeGrid, obj.SubcarrierSpacing, obj.Modulation, ...
                round(obj.TargetCodeRate*1024));
            figure;
            legendstrings = {};

            if plotMATLABDecoder
                plot(obj.SNRrange, obj.ThroughputMATLABCtr * 100 ./ obj.MaxThroughputCtr, 'o-.', ...
                    'LineWidth', 1)
                legendstrings{end + 1} = 'MATLAB';
            end
            if plotSRSDecoder
                hold on;
                plot(obj.SNRrange, obj.ThroughputSRSCtr * 100 ./ obj.MaxThroughputCtr, '^-.', ...
                    'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980])
                legendstrings{end + 1} = 'SRS';
                hold off;
            end
            xlabel('SNR (dB)'); ylabel('Throughput (%)'); grid on; legend(legendstrings, 'Location', 'northwest');
            title(titleString);

            figure;
            set(gca, "YScale", "log")
            if plotMATLABDecoder
                semilogy(obj.SNRrange, obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr, 'o-.', ...
                    'LineWidth', 1)
            end
            if plotSRSDecoder
                hold on;
                semilogy(obj.SNRrange, obj.MissedBlocksSRSCtr ./ obj.TotalBlocksCtr, '^-.', ...
                    'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980])
                hold off;
            end
            xlabel('SNR (dB)'); ylabel('BLER'); grid on; legend(legendstrings);
            title(titleString);
        end % of function plot()
    end % of public methods

    methods (Access = protected)
        function setupImpl(obj)

            % Expand modulation and coding scheme.
            if ~strcmp(obj.MCSTable, 'custom')
                [cc, mm] = srsLib.phy.helpers.srsExpandMCS(obj.MCSIndex, obj.MCSTable);
                obj.TargetCodeRate = cc / 1024;
                mString = srsLib.phy.helpers.srsGetModulation(mm);
                obj.Modulation = mString;
            end

            % Carrier and PUSCH Configuration.
            %
            % Set waveform type and PUSCH numerology (SCS and CP type).
            obj.Carrier = nrCarrierConfig;         % Clean carrier resource grid configuration.
            obj.Carrier.NSizeGrid = obj.NSizeGrid;
            obj.Carrier.SubcarrierSpacing = obj.SubcarrierSpacing;
            obj.Carrier.CyclicPrefix = obj.CyclicPrefix;
            obj.Carrier.NCellID = obj.NCellID;

            % PUSCH/UL-SCH parameters.
            obj.PUSCH = nrPUSCHConfig;      % This PUSCH definition is the basis for all PUSCH transmissions in the BLER simulation.
            obj.PUSCHExtension = struct();  % This structure is to hold additional simulation parameters for the UL-SCH and PUSCH.

            % Define PUSCH time-frequency resource allocation per slot.
            obj.PUSCH.PRBSet =  obj.PRBSet;
            obj.PUSCH.SymbolAllocation = obj.SymbolAllocation;
            obj.PUSCH.MappingType = obj.MappingType;

            % Scrambling identifiers.
            obj.PUSCH.NID = obj.NCellID;
            obj.PUSCH.RNTI = obj.RNTI;

            % Define the transform precoding enabling, layering and transmission scheme.
            obj.PUSCH.TransformPrecoding = false;         % Enable/disable transform precoding.
            obj.PUSCH.NumLayers = obj.NumLayers;
            obj.PUSCH.TransmissionScheme = 'nonCodebook'; % Transmission scheme ('nonCodebook', 'codebook').
            obj.PUSCH.NumAntennaPorts = 1;                % Number of antenna ports for codebook based precoding.
            obj.PUSCH.TPMI = 0;                           % Precoding matrix indicator for codebook based precoding.

            % Define codeword modulation.
            obj.PUSCH.Modulation = obj.Modulation;

            % PUSCH DM-RS configuration.
            obj.PUSCH.DMRS.DMRSTypeAPosition = obj.DMRSTypeAPosition;
            obj.PUSCH.DMRS.DMRSLength = obj.DMRSLength;
            obj.PUSCH.DMRS.DMRSAdditionalPosition = obj.DMRSAdditionalPosition;
            obj.PUSCH.DMRS.DMRSConfigurationType = obj.DMRSConfigurationType;
            obj.PUSCH.DMRS.NumCDMGroupsWithoutData = 2; % Number of CDM groups without data.
            obj.PUSCH.DMRS.NIDNSCID = 0;                % Scrambling identity (0...65535).
            obj.PUSCH.DMRS.NSCID = 0;                   % Scrambling initialization (0, 1).
            obj.PUSCH.DMRS.NRSID = 0;                   % Scrambling ID for low-PAPR sequences (0...1007).
            obj.PUSCH.DMRS.GroupHopping = 0;            % Group hopping (0, 1).
            obj.PUSCH.DMRS.SequenceHopping = 0;         % Sequence hopping (0, 1).

            % Additional simulation and UL-SCH related parameters.
            %
            % Target code rate.
            obj.PUSCHExtension.TargetCodeRate = obj.TargetCodeRate;
            %
            % HARQ process and rate matching/TBS parameters.
            obj.PUSCHExtension.XOverhead = 0;       % Set PUSCH rate matching overhead for TBS (Xoh).
            obj.PUSCHExtension.NHARQProcesses = 16; % Number of parallel HARQ processes to use.
            obj.PUSCHExtension.EnableHARQ = obj.EnableHARQ;

            % LDPC decoder parameters.
            % Available algorithms: 'Belief propagation', 'Layered belief propagation', 'Normalized min-sum', 'Offset min-sum'.
            obj.PUSCHExtension.LDPCDecodingAlgorithm = 'Normalized min-sum';
            obj.PUSCHExtension.MaximumLDPCIterationCount = 6;

            % The simulation relies on various pieces of information about the baseband
            % waveform, such as sample rate.
            waveformInfo = nrOFDMInfo(obj.Carrier); % Get information about the baseband waveform after OFDM modulation step.

            % Store the FFT size.
            obj.Nfft = waveformInfo.Nfft;

            % Create a channel system object for the simulations.
            channel = nrTDLChannel; % TDL channel object.

            % Set the channel geometry.
            channel.NumTransmitAntennas = obj.NTxAnts;
            channel.NumReceiveAntennas = obj.NRxAnts;

            % Assign simulation channel parameters and waveform sample rate to the object.
            channel.SampleRate = waveformInfo.SampleRate;
            channel.DelaySpread = obj.DelaySpread;

            if strcmp(obj.DelayProfile, 'AWGN')
                channel.DelayProfile = 'custom';
                channel.MaximumDopplerShift = 0;
                channel.PathDelays = 0;
                channel.AveragePathGains = 0;
            elseif strcmp(obj.DelayProfile, 'single-tap')
                channel.DelayProfile = 'custom';
                channel.MaximumDopplerShift = 0;
                channel.PathDelays = obj.DelaySpread;
                channel.AveragePathGains = 0;
            else
                channel.MaximumDopplerShift = obj.MaximumDopplerShift;
                channel.DelayProfile = obj.DelayProfile;
            end

            obj.Channel = channel;

            % Create UL-SCH encoder System object to perform transport channel encoding.
            obj.EncodeULSCH = nrULSCH;
            obj.EncodeULSCH.MultipleHARQProcesses = true;
            obj.EncodeULSCH.TargetCodeRate = obj.PUSCHExtension.TargetCodeRate;

            % Create UL-SCH decoder System object to perform transport channel decoding
            % Use layered belief propagation for LDPC decoding, with half the number of
            % iterations as compared to the default for belief propagation decoding.
            obj.DecodeULSCH = nrULSCHDecoder;
            obj.DecodeULSCH.MultipleHARQProcesses = true;
            obj.DecodeULSCH.TargetCodeRate = obj.PUSCHExtension.TargetCodeRate;
            obj.DecodeULSCH.LDPCDecodingAlgorithm = obj.PUSCHExtension.LDPCDecodingAlgorithm;
            obj.DecodeULSCH.MaximumLDPCIterationCount = obj.PUSCHExtension.MaximumLDPCIterationCount;

            % Calculate the transport block size for the transmission in the slot.
            [puschIndices, puschIndicesInfo] = nrPUSCHIndices(obj.Carrier, obj.PUSCH);
            MRB = numel(obj.PUSCH.PRBSet);
            trBlkSize = nrTBS(obj.PUSCH.Modulation, obj.PUSCH.NumLayers, ...
                MRB, puschIndicesInfo.NREPerPRB, obj.PUSCHExtension.TargetCodeRate, obj.PUSCHExtension.XOverhead);
            obj.TBS = trBlkSize;
            obj.PUSCHIndices = puschIndices;
            obj.PUSCHIndicesInfo = puschIndicesInfo;

            [obj.SegmentCfg, configSRS] = srsMEX.phy.srsPUSCHDecoder.configureSegment(obj.Carrier, ...
                obj.PUSCH, obj.TargetCodeRate, obj.PUSCHExtension.NHARQProcesses, obj.PUSCHExtension.XOverhead);
            obj.DecodeULSCHsrs = srsMEX.phy.srsPUSCHDecoder('MaxCodeblockSize', configSRS.MaxCodeblockSize, ...
                'MaxSoftbuffers', configSRS.MaxSoftbuffers, 'MaxCodeblocks', configSRS.MaxCodeblocks);

        end % of setupImpl

        function validatePropertiesImpl(obj)
            if (strcmp(obj.MCSTable, 'qam256') && (obj.MCSIndex == 28))
                error('The maximum allowed MCS index for MCS Table ''qam256'' is 27.');
            end
            tmp = struct();
            tmp.PUSCH.NumLayers = obj.NumLayers;
            tmp.NTxAnts = obj.NTxAnts;
            tmp.NRxAnts = obj.NRxAnts;

            % Cross-check the PUSCH layering against the channel geometry.
            validateNumLayers(tmp);

            % Cross-check that grid size and PRB allocation are compatible.
            obj.checkPRBSetandGrid();

            % Cross-check that SCS and CP are compatible.
            obj.checkSCSandCP();

            % Cross-check that we are not testing both decoders when HARQ is enabled.
            obj.checkHARQandDecType();

            % Cross-check that we are not using perfect channel estimation with CFO.
            obj.checkCFOandEstimator();
        end

        function stepImpl(obj, SNRIn, nFrames)
            arguments
                obj (1, 1) PUSCHBLER
                %SNR range in dB.
                SNRIn double {mustBeReal, mustBeFinite, mustBeVector}
                %Number of 10-ms frames.
                nFrames (1, 1) double {mustBeInteger, mustBePositive} = 10
            end

            % Ensure SNRIn has no repetitions and is a row vector.
            SNRIn = unique(SNRIn);
            SNRIn = SNRIn(:).';

            % Get the maximum number of delayed samples by a channel multipath
            % component. This is calculated from the channel path with the largest
            % delay and the implementation delay of the channel filter. This is
            % required later to flush the channel filter to obtain the received signal.
            chInfo = info(obj.Channel);
            maxChDelay = ceil(max(chInfo.PathDelays*obj.Channel.SampleRate)) + chInfo.ChannelFilterDelay;

            % Array to store the maximum throughput and the number of transmitted transport blocks for all SNR points.
            maxThroughput = zeros(length(SNRIn), 1);
            totalBlocks = zeros(length(SNRIn), 1);

            % Set up redundancy version (RV) sequence for all HARQ processes.
            if obj.PUSCHExtension.EnableHARQ
                % From PUSCH demodulation requirements in RAN WG4 meeting #88bis (R4-1814062).
                rvSeq = [0 2 3 1];
            else
                % HARQ disabled - single transmission with RV=0, no retransmissions.
                rvSeq = 0;
            end

            % Take copies of channel-level parameters to simplify subsequent parameter referencing.
            carrier = obj.Carrier;
            pusch = obj.PUSCH;
            puschextra = obj.PUSCHExtension;
            implementationType = obj.ImplementationType;
            nRxAnts = obj.NRxAnts;
            nTxAnts = obj.NTxAnts;
            trBlkSize = obj.TBS;
            segmentCfg = obj.SegmentCfg;
            puschBitCapacity = obj.PUSCHIndicesInfo.G;
            puschIndices = obj.PUSCHIndices;
            perfectChannelEstimator = obj.PerfectChannelEstimator;
            delayProfile = obj.DelayProfile;
            nFFT = obj.Nfft;
            displayDiagnostics = obj.DisplayDiagnostics;
            displaySimulationInformation = obj.DisplaySimulationInformation;

            useMATLABDecoder = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
            useSRSDecoder = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

            % Array to store the simulation throughput and BLER for all SNR points.
            simThroughput = zeros(length(SNRIn), 1);
            simBLER = zeros(length(SNRIn), 1);

            % Array to store the simulation throughput and BLER for all SNR points.
            simThroughputSRS = zeros(length(SNRIn), 1);
            simBLERSRS = zeros(length(SNRIn), 1);

            quickSim = obj.QuickSimulation;

            compGrid = obj.ApplyOFHCompression;
            compWidth = obj.CompIQwidth;
            optCompStr = '';
            if compGrid
                optCompStr = sprintf(', with O-FH compression enabled (%d-bit BFP)', compWidth);
            end

            % DM-RS over data amplitude gain.
            betaDMRS = sqrt(2);

            if useSRSDecoder
                srsDemodulatePUSCH = srsMEX.phy.srsPUSCHDemodulator;
                srsChannelEstimate = srsMEX.phy.srsMultiPortChannelEstimator(ImplementationType = obj.SRSEstimatorType, ...
                    Smoothing = 'filter', CompensateCFO = true);
            end

            % %%% Simulation loop.

            for snrIdx = 1:numel(SNRIn)

                % Reset the random number generator so that each SNR point will
                % experience the same noise realization.
                rng('default');

                obj.DecodeULSCH.reset();        % Reset decoder at the start of each SNR point.
                pathFilters = [];

                % Create PUSCH object configured for the non-codebook transmission
                % scheme, used for receiver operations that are performed with respect
                % to the PUSCH layers.
                puschNonCodebook = pusch;
                puschNonCodebook.TransmissionScheme = 'nonCodebook';

                % Prepare simulation for new SNR point.
                SNRdB = SNRIn(snrIdx);
                fprintf('\nSimulating transmission scheme 1 (%dx%d) and SCS=%dkHz with %s channel at %gdB SNR for %d 10ms frame(s)%s\n', ...
                    nTxAnts, nRxAnts, carrier.SubcarrierSpacing, ...
                    delayProfile, SNRdB, nFrames, optCompStr);

                % Specify the fixed order in which we cycle through the HARQ process IDs.
                harqSequence = 0:puschextra.NHARQProcesses-1;

                % Initialize the state of all HARQ processes.
                harqEntity = HARQEntity(harqSequence, rvSeq);

                % Reset the channel so that each SNR point will experience the same
                % channel realization.
                reset(obj.Channel);

                % Total number of slots in the simulation period.
                NSlots = nFrames * carrier.SlotsPerFrame;

                % Timing offset, updated in every slot for perfect synchronization and
                % when the correlation is strong for practical synchronization.
                offset = 0;

                % Loop over the entire waveform length.
                for nslot = 0:NSlots-1

                    % Update the carrier slot numbers for new slot.
                    carrier.NSlot = nslot;

                    % HARQ processing.
                    %
                    % Create HARQ ID for the SRS decoder.
                    % Set the HARQ ID.
                    harqBufID.RNTI = pusch.RNTI;
                    harqBufID.HARQProcessID = harqEntity.HARQProcessID;
                    harqBufID.NumCodeblocks = segmentCfg.NumCodeblocks;

                    % If new data for current process then create a new UL-SCH transport block.
                    if harqEntity.NewData
                        trBlk = randi([0 1], trBlkSize, 1);
                        setTransportBlock(obj.EncodeULSCH, trBlk, harqEntity.HARQProcessID);
                        % If new data because of previous RV sequence time out then flush decoder soft buffer explicitly.
                        if harqEntity.SequenceTimeout
                            resetSoftBuffer(obj.DecodeULSCH, harqEntity.HARQProcessID);
                        end
                        % The SRS decoder must be reset explicitely in any case.
                        obj.DecodeULSCHsrs.resetCRCS(harqBufID);
                    end

                    % Encode the UL-SCH transport block.
                    codedTrBlock = obj.EncodeULSCH(pusch.Modulation, pusch.NumLayers, ...
                        puschBitCapacity, harqEntity.RedundancyVersion, harqEntity.HARQProcessID);

                    % Create resource grid for a slot.
                    puschGrid = nrResourceGrid(carrier, nTxAnts);

                    % PUSCH modulation, including codebook based MIMO precoding if TxScheme = 'codebook'.
                    puschSymbols = nrPUSCH(carrier, pusch, codedTrBlock);

                    % Implementation-specific PUSCH MIMO precoding and mapping. This
                    % MIMO precoding step is in addition to any codebook based
                    % MIMO precoding done during PUSCH modulation above.
                    if (strcmpi(pusch.TransmissionScheme, 'codebook'))
                        % Codebook based MIMO precoding, F precodes between PUSCH
                        % transmit antenna ports and transmit antennas.
                        F = eye(pusch.NumAntennaPorts, nTxAnts);
                    else
                        % Non-codebook based MIMO precoding, F precodes between PUSCH
                        % layers and transmit antennas.
                        F = eye(pusch.NumLayers, nTxAnts);
                    end
                    [~, puschAntIndices] = nrExtractResources(puschIndices, puschGrid);
                    puschGrid(puschAntIndices) = puschSymbols * F;

                    % Implementation-specific PUSCH DM-RS MIMO precoding and mapping.
                    % The first DM-RS creation includes codebook based MIMO precoding if applicable.
                    dmrsSymbols = nrPUSCHDMRS(carrier, pusch) * betaDMRS;
                    dmrsIndices = nrPUSCHDMRSIndices(carrier, pusch);
                    for p = 1:size(dmrsSymbols, 2)
                        [~, dmrsAntIndices] = nrExtractResources(dmrsIndices(:, p), puschGrid);
                        puschGrid(dmrsAntIndices) = puschGrid(dmrsAntIndices) + dmrsSymbols(:, p) * F(p, :);
                    end

                    % OFDM modulation.
                    txWaveform = nrOFDMModulate(carrier, puschGrid);

                    % Pass data through channel model. Append zeros at the end of the
                    % transmitted waveform to flush channel content. These zeros take
                    % into account any delay introduced in the channel. This is a mix
                    % of multipath delay and implementation delay. This value may
                    % change depending on the sampling rate, delay profile and delay
                    % spread.
                    txWaveform = [txWaveform; zeros(maxChDelay, size(txWaveform, 2))]; %#ok<AGROW>
                    [rxWaveform, pathGains, sampleTimes] = obj.Channel(txWaveform);

                    % Add CFO to the received signal, if configured.
                    if (obj.CarrierFrequencyOffset ~= 0)
                        nSamples = size(rxWaveform, 1);
                        if (~exist('cfoPhase', 'var') || (length(cfoPhase) ~= nSamples))
                            timeIx = (0:nSamples-1).';
                            cfoPhase = exp(2j * pi * timeIx * obj.CarrierFrequencyOffset / obj.Channel.SampleRate);
                        end
                        rxWaveform = rxWaveform .* cfoPhase;
                    end

                    % Add AWGN to the received time domain waveform.
                    % Normalize noise power by the IFFT size used in OFDM modulation,
                    % as the OFDM modulator applies this normalization to the
                    % transmitted waveform. Also normalize by the number of receive
                    % antennas, as the channel model applies this normalization to the
                    % received waveform, by default.
                    SNR = 10^(SNRdB/10);
                    N0 = 1 / sqrt(2.0 * nRxAnts * double(nFFT) * SNR);
                    noise = N0 * complex(randn(size(rxWaveform)), randn(size(rxWaveform)));
                    rxWaveform = rxWaveform + noise;

                    if (perfectChannelEstimator)
                        % Perfect synchronization. Use information provided by the
                        % channel to find the strongest multipath component.
                        pathFilters = getPathFilters(obj.Channel);
                        [offset, ~] = nrPerfectTimingEstimate(pathGains, pathFilters);
                        rxWaveform = rxWaveform(1+offset:end, :);
                    end

                    % Perform OFDM demodulation on the received data to recreate the
                    % resource grid, including padding in the event that practical
                    % synchronization results in an incomplete slot being demodulated.
                    rxGrid = nrOFDMDemodulate(carrier, rxWaveform);
                    [K, L, R] = size(rxGrid);
                    if (L < carrier.SymbolsPerSlot)
                        rxGrid = cat(2, rxGrid, zeros(K, carrier.SymbolsPerSlot - L, R));
                    end

                    % Optionally, compress and decompress the received resource grid 
                    % to emulate the effect that thecompression used in the O-FH has 
                    % on the PUSCH decoding performance.
                    if compGrid
                       [compRXGrid, compParam] = srsLib.ofh.compression.srsCompressor(rxGrid, 'BFP', compWidth);
                       rxGrid = srsLib.ofh.compression.srsDecompressor(compRXGrid, compParam, 'BFP', compWidth);
                    end

                    dmrsLayerIndices = nrPUSCHDMRSIndices(carrier, puschNonCodebook);
                    if (perfectChannelEstimator)
                        % Perfect channel estimation, use the value of the path gains
                        % provided by the channel.
                        estChannelGrid = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);

                        % Get perfect noise estimate (from the noise realization).
                        noiseGrid = nrOFDMDemodulate(carrier, noise(1+offset:end, :));
                        noiseEst = var(noiseGrid(:));

                        % Apply MIMO deprecoding to estChannelGrid to give an estimate
                        % per transmission layer.
                        K = size(estChannelGrid, 1);
                        estChannelGrid = reshape(estChannelGrid, K*carrier.SymbolsPerSlot*nRxAnts, nTxAnts);
                        estChannelGrid = estChannelGrid * F.';
                        if (strcmpi(pusch.TransmissionScheme, 'codebook'))
                            W = nrPUSCHCodebook(pusch.NumLayers, pusch.NumAntennaPorts, pusch.TPMI, pusch.TransformPrecoding);
                            estChannelGrid = estChannelGrid * W.';
                        end
                        estChannelGrid = reshape(estChannelGrid, K, carrier.SymbolsPerSlot, nRxAnts, []);
                    else
                        % Practical channel estimation between the received grid and
                        % each transmission layer, using the PUSCH DM-RS for each layer
                        % which are created by specifying the non-codebook transmission
                        % scheme.
                        dmrsLayerSymbols = nrPUSCHDMRS(carrier, puschNonCodebook);
                    end

                    % Display EVM per layer, per slot and per RB. Reference symbols for
                    % each layer are created by specifying the non-codebook
                    % transmission scheme.
                    if (displayDiagnostics)
                        refSymbols = nrPUSCH(carrier, puschNonCodebook, codedTrBlock);
                        plotLayerEVM(NSlots, nslot, puschNonCodebook, size(puschGrid), puschIndices, refSymbols, puschEq);
                    end

                    % Store values to calculate BLER.
                    isLastRetransmission = (harqEntity.RedundancyVersion == rvSeq(end));

                    blkerrBoth = false;

                    if useMATLABDecoder
                        if (~perfectChannelEstimator)
                            [estChannelGrid, noiseEst] = nrChannelEstimate(carrier, rxGrid, ...
                                dmrsLayerIndices, dmrsLayerSymbols * betaDMRS, 'CDMLengths', pusch.DMRS.CDMLengths);
                        end

                        % Get PUSCH resource elements from the received grid.
                        [puschRx, puschHest] = nrExtractResources(puschIndices, rxGrid, estChannelGrid);

                        % Equalization.
                        [puschEq, csi] = nrEqualizeMMSE(puschRx, puschHest, noiseEst);

                        % Decode PUSCH physical channel.
                        [ulschLLRs, rxSymbols] = nrPUSCHDecode(carrier, puschNonCodebook, puschEq, noiseEst);

                        % Apply channel state information (CSI) produced by the equalizer,
                        % including the effect of transform precoding if enabled.
                        if (pusch.TransformPrecoding)
                            MSC = MRB * 12;
                            csi = nrTransformDeprecode(csi, MRB) / sqrt(MSC);
                            csi = repmat(csi((1:MSC:end).'), 1, MSC).';
                            csi = reshape(csi, size(rxSymbols));
                        end
                        csi = nrLayerDemap(csi);
                        Qm = length(ulschLLRs) / length(rxSymbols);
                        csi = reshape(repmat(csi{1}.', Qm, 1), [], 1);
                        ulschLLRs = ulschLLRs .* csi;

                        % Decode the UL-SCH transport channel.
                        obj.DecodeULSCH.TransportBlockLength = trBlkSize;
                        [decbits, blkerr] = obj.DecodeULSCH(ulschLLRs, pusch.Modulation, ...
                            pusch.NumLayers, harqEntity.RedundancyVersion, harqEntity.HARQProcessID);

                        % Store values to calculate throughput and BLER.
                        simThroughput(snrIdx) = simThroughput(snrIdx) + (~blkerr * trBlkSize);
                        isCountBLER = (isLastRetransmission || ~blkerr);
                        simBLER(snrIdx) = simBLER(snrIdx) + (isCountBLER && any(decbits ~= trBlk));

                        blkerrBoth = blkerr;
                    end

                    if useSRSDecoder
                        if (~perfectChannelEstimator)
                            [estChannelGrid, noiseEst] = srsChannelEstimate(rxGrid, pusch.SymbolAllocation, ...
                                dmrsLayerIndices, dmrsLayerSymbols, ...
                                'CyclicPrefix', carrier.CyclicPrefix, ...
                                'SubcarrierSpacing', carrier.SubcarrierSpacing, ...
                                'PortIndices', (0:nRxAnts-1)', ...
                                'BetaScaling', betaDMRS);
                        end

                        ulschLLRsInt8 = int8(srsDemodulatePUSCH(rxGrid, estChannelGrid, noiseEst, pusch, ...
                            puschIndices, dmrsLayerIndices, 0:nRxAnts-1));

                        % Set the RV.
                        segmentCfg.RV = harqEntity.RedundancyVersion;

                        [decbitsSRS, statsSRS] = obj.DecodeULSCHsrs(ulschLLRsInt8, harqEntity.NewData, segmentCfg, harqBufID);

                        % Store values to calculate throughput and BLER.
                        simThroughputSRS(snrIdx) = simThroughputSRS(snrIdx) + (statsSRS.CRCOK * trBlkSize);
                        isCountBLER = (isLastRetransmission || statsSRS.CRCOK);
                        simBLERSRS(snrIdx) = simBLERSRS(snrIdx) + (isCountBLER && any(decbitsSRS ~= srsTest.helpers.bitPack(trBlk)));

                        blkerrBoth = blkerrBoth || (~statsSRS.CRCOK);
                    end

                    % Increase total number of transmitted information bits.
                    maxThroughput(snrIdx) = maxThroughput(snrIdx) + trBlkSize;

                    % If the block was received correctly or if it's the last
                    % restransmission, increment counter of transmitted transport blocks.
                    if (~blkerrBoth || isLastRetransmission)
                        totalBlocks(snrIdx) = totalBlocks(snrIdx) + 1;
                    end

                    % Update current process with CRC error and advance to
                    % next process.
                    procstatus = updateAndAdvance(harqEntity, blkerrBoth, trBlkSize, puschBitCapacity);
                    if (displaySimulationInformation)
                        fprintf('\n(%3.2f%%) NSlot=%d, %s', 100*(nslot+1)/NSlots, nslot, procstatus);
                    end

                    % To speed the simulation up, we stop after 100 missed transport blocks.
                    if quickSim && (~useMATLABDecoder || (simBLER(snrIdx) >= 100)) && (~useSRSDecoder || (simBLERSRS(snrIdx) >= 100))
                        break;
                    end
                end

                % Display the results dynamically in the command window.
                if (displaySimulationInformation)
                    fprintf('\n');
                end
                usedFrames = (nslot + 1) / carrier.SlotsPerFrame;
                if useMATLABDecoder
                    fprintf('\nThroughput(Mbps) after %.0f frame(s) = %.4f (max %.4f)\n', usedFrames, ...
                        1e-6*[simThroughput(snrIdx) maxThroughput(snrIdx)]/(usedFrames*10e-3));
                    fprintf('Throughput(%%) after %.0f frame(s) = %.4f\n', usedFrames, simThroughput(snrIdx)*100/maxThroughput(snrIdx));
                    fprintf('BLER after %.0f frame(s) = %.4f\n', usedFrames, simBLER(snrIdx)/totalBlocks(snrIdx));
                end
                if useSRSDecoder
                    fprintf('\nSRS');
                    fprintf('\nThroughput(Mbps) after %.0f frame(s) = %.4f (max %.4f)\n', usedFrames, ...
                        1e-6*[simThroughputSRS(snrIdx) maxThroughput(snrIdx)]/(usedFrames*10e-3));
                    fprintf('Throughput(%%) after %.0f frame(s) = %.4f\n', usedFrames, simThroughputSRS(snrIdx)*100/maxThroughput(snrIdx));
                    fprintf('BLER after %.0f frame(s) = %.4f\n', usedFrames, simBLERSRS(snrIdx)/totalBlocks(snrIdx));
                end

            end

            % Export results.
            [~, repeatedIdx] = intersect(obj.SNRrange, SNRIn);
            obj.SNRrange(repeatedIdx) = [];
            [obj.SNRrange, sortedIdx] = sort([obj.SNRrange SNRIn]);

            obj.MaxThroughputCtr = joinArrays(obj.MaxThroughputCtr, maxThroughput, repeatedIdx, sortedIdx);
            obj.ThroughputMATLABCtr = joinArrays(obj.ThroughputMATLABCtr, simThroughput, repeatedIdx, sortedIdx);
            obj.ThroughputSRSCtr = joinArrays(obj.ThroughputSRSCtr, simThroughputSRS, repeatedIdx, sortedIdx);
            obj.TotalBlocksCtr = joinArrays(obj.TotalBlocksCtr, totalBlocks, repeatedIdx, sortedIdx);
            obj.MissedBlocksMATLABCtr = joinArrays(obj.MissedBlocksMATLABCtr, simBLER, repeatedIdx, sortedIdx);
            obj.MissedBlocksSRSCtr = joinArrays(obj.MissedBlocksSRSCtr, simBLERSRS, repeatedIdx, sortedIdx);
        end % of function stepImpl()

        function resetImpl(obj)
            % Reset internal system objects.
            reset(obj.Channel);
            reset(obj.EncodeULSCH);
            reset(obj.DecodeULSCH);
            reset(obj.DecodeULSCHsrs);

            % Reset simulation results.
            obj.SNRrange = [];
            obj.MaxThroughputCtr = [];
            obj.ThroughputMATLABCtr = [];
            obj.ThroughputSRSCtr = [];
            obj.TotalBlocksCtr = [];
            obj.MissedBlocksMATLABCtr = [];
            obj.MissedBlocksSRSCtr = [];
        end

        function releaseImpl(obj)
            % Release internal system objects.
            release(obj.Channel);
            release(obj.EncodeULSCH);
            release(obj.DecodeULSCH);
            release(obj.DecodeULSCHsrs);
        end

        function flag = isInactivePropertyImpl(obj, property)
            switch property
                case 'DMRSTypeAPosition'
                    flag = (obj.MappingType == 'B');
                case 'DelaySpread'
                    flag = strcmp(obj.DelayProfile, 'AWGN') || strcmp(obj.DelayProfile, 'TDLA30') ...
                        || strcmp(obj.DelayProfile, 'TDLB100') || strcmp(obj.DelayProfile, 'TDLC300');
                case 'MaximumDopplerShift'
                    flag = strcmp(obj.DelayProfile, 'AWGN');
                case {'ThroughputMATLABCtr', 'MissedBlocksMATLABCtr'}
                    flag = isempty(obj.SNRrange) || strcmp(obj.ImplementationType, 'srs');
                case {'ThroughputSRSCtr', 'MissedBlocksSRSCtr'}
                    flag = isempty(obj.SNRrange) || strcmp(obj.ImplementationType, 'matlab');
                case {'SNRrange', 'MaxThroughputCtr', 'TotalBlocksCtr'}
                    flag = isempty(obj.SNRrange);
                case {'Modulation', 'TargetCodeRate'}
                    flag = ~strcmp(obj.MCSTable, 'custom') && ~obj.isLocked;
                case 'MCSIndex'
                    flag = strcmp(obj.MCSTable, 'custom');
                case {'TBS', 'MaxThroughput'}
                    flag = isempty(obj.TBS) || ~obj.isLocked;
                case {'ThroughputMATLAB', 'BlockErrorRateMATLAB'}
                    flag = isempty(obj.ThroughputMATLABCtr) || strcmp(obj.ImplementationType, 'srs');
                case {'ThroughputSRS', 'BlockErrorRateSRS'}
                    flag = isempty(obj.ThroughputSRSCtr) || strcmp(obj.ImplementationType, 'matlab');
                case 'SRSEstimatorType'
                    flag = strcmp(obj.ImplementationType, 'matlab') || obj.PerfectChannelEstimator;
                case 'CompIQwidth'
                    flag = ~obj.ApplyOFHCompression;
                otherwise
                    flag = false;
            end
        end

        function groups = getPropertyGroups(obj)

            results = {'SNRrange', 'MaxThroughputCtr', 'ThroughputMATLABCtr', 'ThroughputSRSCtr', ...
                'TotalBlocksCtr', 'MissedBlocksMATLABCtr', 'MissedBlocksSRSCtr', 'TBS', ...
                'MaxThroughput', 'ThroughputMATLAB', 'ThroughputSRS', 'BlockErrorRateMATLAB', ...
                'BlockErrorRateSRS'};

            confProps = {...
                ... Generic.
                'NCellID', 'RNTI', ...
                ... Resource grid.
                'SubcarrierSpacing', 'CyclicPrefix', 'NSizeGrid', ...
                ... Allocation.
                'PRBSet', 'SymbolAllocation', 'MappingType', ...
                ... DM-RS.
                'DMRSConfigurationType', 'DMRSLength', 'DMRSAdditionalPosition', 'DMRSTypeAPosition', ...
                ... Modulation and coding.
                'MCSTable', 'MCSIndex', 'Modulation', 'TargetCodeRate', ...
                ... Antennas and layers.
                'NRxAnts', 'NTxAnts', 'NumLayers', ...
                ... Channel model.
                'DelayProfile', 'DelaySpread', 'MaximumDopplerShift', 'CarrierFrequencyOffset', 'PerfectChannelEstimator', ...
                ... HARQ.
                'EnableHARQ', ...
                ... Compression.
                'ApplyOFHCompression', 'CompIQwidth', ...
                ... Other simulation details.
                'ImplementationType', 'SRSEstimatorType', ...
                'QuickSimulation', 'DisplaySimulationInformation', 'DisplayDiagnostics'};
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

        function s = saveObjectImpl(obj)
            % Save all public properties.
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                % Save child objects.
                s.Carrier = obj.Carrier;
                s.PUSCH = obj.PUSCH;
                s.PUSCHExtension = obj.PUSCHExtension;
                s.PUSCHIndices = obj.PUSCHIndices;
                s.PUSCHIndicesInfo = obj.PUSCHIndicesInfo;
                s.Channel = matlab.System.saveObject(obj.Channel);
                s.EncodeULSCH = matlab.System.saveObject(obj.EncodeULSCH);
                s.DecodeULSCH = matlab.System.saveObject(obj.DecodeULSCH);
                s.DecodeULSCHsrs = matlab.System.saveObject(obj.DecodeULSCHsrs);
                s.SegmentCfg = obj.SegmentCfg;

                % Save FFT size.
                s.Nfft = obj.Nfft;

                % Save counters.
                s.SNRrange = obj.SNRrange;
                s.MaxThroughputCtr = obj.MaxThroughputCtr;
                s.ThroughputMATLABCtr = obj.ThroughputMATLABCtr;
                s.ThroughputSRSCtr = obj.ThroughputSRSCtr;
                s.TotalBlocksCtr = obj.TotalBlocksCtr;
                s.MissedBlocksMATLABCtr = obj.MissedBlocksMATLABCtr;
                s.MissedBlocksSRSCtr = obj.MissedBlocksSRSCtr;
                s.TBS = obj.TBS;
            end
        end % of function s = saveObjectImpl(obj)

        function loadObjectImpl(obj, s, wasInUse)
            if wasInUse
                % Load child objects.
                obj.Carrier = s.Carrier;
                obj.PUSCH = s.PUSCH;
                obj.PUSCHExtension = s.PUSCHExtension;
                obj.PUSCHIndices = s.PUSCHIndices;
                obj.PUSCHIndicesInfo = s.PUSCHIndicesInfo;
                obj.Channel = matlab.System.loadObject(s.Channel);
                obj.EncodeULSCH = matlab.System.loadObject(s.EncodeULSCH);
                obj.DecodeULSCH = matlab.System.loadObject(s.DecodeULSCH);
                obj.DecodeULSCHsrs = matlab.System.loadObject(s.DecodeULSCHsrs);
                obj.SegmentCfg = s.SegmentCfg;

                % Load FFT size.
                obj.Nfft = s.Nfft;

                % Load counters.
                obj.SNRrange = s.SNRrange;
                obj.MaxThroughputCtr = s.MaxThroughputCtr;
                obj.ThroughputMATLABCtr = s.ThroughputMATLABCtr;
                obj.ThroughputSRSCtr = s.ThroughputSRSCtr;
                obj.TotalBlocksCtr = s.TotalBlocksCtr;
                obj.MissedBlocksMATLABCtr = s.MissedBlocksMATLABCtr;
                obj.MissedBlocksSRSCtr = s.MissedBlocksSRSCtr;
                obj.TBS = s.TBS;
            end

            % Load all public properties.
            loadObjectImpl@matlab.System(obj, s, wasInUse);

            % For back-compatibility with previous versions.
            if isfield(s, 'DecoderType')
                obj.ImplementationType = s.DecoderType;
            end
        end % function loadObjectImpl(obj, s, wasInUse)

    end % of methods (Access = protected)
end % of classdef PUSCHBLER


% %% Local Functions
function mixedArray = joinArrays(arrayA, arrayB, removeFromA, outputOrder)
    arrayA(removeFromA) = [];
    mixedArray = [arrayA; arrayB];
    mixedArray = mixedArray(outputOrder);
end

function validateNumLayers(simParameters)
%Validate the number of layers, relative to the antenna geometry.

    numlayers = simParameters.PUSCH.NumLayers;
    ntxants = simParameters.NTxAnts;
    nrxants = simParameters.NRxAnts;
    antennaDescription = sprintf('min(NTxAnts, NRxAnts) = min(%d, %d) = %d', ntxants, nrxants, min(ntxants, nrxants));
    if numlayers > min(ntxants, nrxants)
        error('The number of layers (%d) must satisfy NumLayers <= %s', ...
            numlayers, antennaDescription);
    end

    % Display a warning if the maximum possible rank of the channel equals
    % the number of layers.
    if (numlayers > 2) && (numlayers == min(ntxants, nrxants))
        warning(['The maximum possible rank of the channel, given by %s, is equal to NumLayers (%d).' ...
            ' This may result in a decoding failure under some channel conditions.' ...
            ' Try decreasing the number of layers or increasing the channel rank' ...
            ' (use more transmit or receive antennas).'], antennaDescription, numlayers); %#ok<SPWRN>
    end

end

function plotLayerEVM(NSlots, nslot, pusch, siz, puschIndices, puschSymbols, puschEq)
%Plot EVM information.

    persistent slotEVM;
    persistent rbEVM
    persistent evmPerSlot;

    if (nslot==0)
        slotEVM = comm.EVM;
        rbEVM = comm.EVM;
        evmPerSlot = NaN(NSlots, pusch.NumLayers);
        figure;
    end
    evmPerSlot(nslot+1, :) = slotEVM(puschSymbols, puschEq);
    subplot(2, 1, 1);
    plot(0:(NSlots-1), evmPerSlot, 'o-');
    xlabel('Slot number');
    ylabel('EVM (%)');
    legend("layer " + (1:pusch.NumLayers), 'Location', 'EastOutside');
    title('EVM per layer per slot');

    subplot(2, 1, 2);
    [k, ~, p] = ind2sub(siz, puschIndices);
    rbsubs = floor((k-1) / 12);
    NRB = siz(1) / 12;
    evmPerRB = NaN(NRB, pusch.NumLayers);
    for nu = 1:pusch.NumLayers
        for rb = unique(rbsubs).'
            this = (rbsubs==rb & p==nu);
            evmPerRB(rb+1, nu) = rbEVM(puschSymbols(this), puschEq(this));
        end
    end
    plot(0:(NRB-1), evmPerRB, 'x-');
    xlabel('Resource block');
    ylabel('EVM (%)');
    legend("layer " + (1:pusch.NumLayers), 'Location', 'EastOutside');
    title(['EVM per layer per resource block, slot #' num2str(nslot)]);

    drawnow;

end
