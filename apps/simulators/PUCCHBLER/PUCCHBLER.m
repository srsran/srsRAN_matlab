%PUCCHBLER PUCCH block error rate simulator.
%   PUCCHSIM = PUCCHBLER creates a PUCCH simulator object, PUCCHSIM. This object
%   simulates a PUCCH transmission according to the specified setup (see list of
%   PUCCHBLER properties below) and measures the detection probability or the
%   block error rate depending on the PUCCH format and/or the number of UCI bits.
%
%   Step method syntax
%
%   step(PUCCHSIM, SNRIN) runs a PUCCH simulation corresponding to ten 10-ms
%   frames for each one of the SNR values (dB) specified in SNRIN (a real-valued
%   array). When the simulation is over, the results will be available as properties
%   of the PUCCHSIM object (see below).
%
%   step(PUCCHSIM, SNRIN, NFRAMES) runs simulations corresponding to NFRAMES 10-ms
%   frames. Setting parameter QuickSimulation to true, each simulated point is
%   stopped earlier when reaching 100 failed block transmissions.
%
%   Being a MATLAB system object, the PUCCHSIM object may be called directly as
%   a function instead of using the step method. For example, step(PUCCHSIM, SNRIN)
%   is equivalent to PUCCHSIM(SNRIN).
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
%   a PUCCHBLER object implies resetting the simulation results.
%
%   Note: PUCCHBLER objects can be saved and loaded normally as all MATLAB objects.
%   Saving an unlocked object only stores the simulation configuration. Saving
%   a locked object also stores all simulation results so that the simulation
%   can be resumed after loading the object.
%
%   PUCCHBLER methods:
%
%   step        - Runs a PUCCH simulation (see above).
%   release     - Allows property value changes (implies reset).
%   clone       - Creates PUCCHBLER object with same property values.
%   isLocked    - Locked status (logical).
%   reset       - Resets simulated data.
%   plot        - Plots detection/BLER curves (if simulated data are present).
%
%   PUCCHBLER properties (all nontunable, unless otherwise specified):
%
%   NTxAnts                      - Number of transmit antennas.
%   NRxAnts                      - Number of receive antennas.
%   PerfectChannelEstimator      - Perfect channel estimation flag.
%   DisplaySimulationInformation - Flag for displaying simulation information.
%   NSizeGrid                    - Bandwidth as a number of resource blocks.
%   SubcarrierSpacing            - Subcarrier spacing in kHz.
%   NCellID                      - Cell identity.
%   PRBSet                       - PUCCH allocated PRBs (specify as an array, e.g. 0:51).
%   SymbolAllocation             - PUCCH OFDM symbol allocation.
%   RNTI                         - Radio network temporary identifier (0...65535).
%   PUCCHFormat                  - PUCCH format (2, 3).
%   Modulation                   - Modulation scheme (inactive if "PUCCHFormat == 2").
%   NumUCIBits                   - Number of UCI information bits.
%   DelayProfile                 - Channel delay profile ('AWGN'(no delay, no Doppler),
%                                  'TDL-C'(rural scenario), 'TDLC300' (simplified rural scenario)).
%   DelaySpread                  - Delay spread in seconds (TDL-C delay profile only).
%   MaximumDopplerShift          - Maximum Doppler shift in hertz (TDL-C and TDLC300 delay profile only)
%   ImplementationType           - PUCCH implementation type ('matlab' only).
%   QuickSimulation              - Quick-simulation flag: set to true to stop
%                                  each point after 100 failed transport blocks (tunable).
%
%   When the simulation is over, the object allows access to the following
%   results properties.
%
%   SNRrange              - Simulated SNR range in dB.
%   TotalBlocksCtr        - Counter of newly transmitted transport blocks (ignoring repetitions).
%   MissedBlocksMATLABCtr - Counter of missed transport blocks, after all
%                           allowed retransmissions (MATLAB case).
%   BlockErrorRateMATLAB  - Transport block error (or missed detection) rate (MATLAB case).
%
%   Remark: The simulation loop is heavily based on the <a href="https://www.mathworks.com/help/5g/ug/nr-pucch-block-error-rate.html">NR PUCCH Block Error Rate</a> MATLAB example by MathWorks.

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

classdef PUCCHBLER < matlab.System
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
        NSizeGrid (1, 1) double {mustBeInteger, mustBePositive} = 25
        %Subcarrier spacing in kHz (15, 30).
        SubcarrierSpacing (1, 1) double {mustBeMember(SubcarrierSpacing, [15, 30])} = 15
        %Cell identity.
        NCellID (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1
        %PUCCH allocated PRBs.
        PRBSet = 0:3
        %PUCCH OFDM symbol allocation in each slot.
        %   Specify as a two-element array, where the first element represents the
        %   start of symbol allocation (0-based) and the second element represents
        %   the number of allocated OFDM symbols (e.g., [0 14]).
        SymbolAllocation = [13, 1]
        %Radio network temporary identifier (0...65535).
        RNTI (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(RNTI, 0, 65535)} = 1
        %Modulation scheme (only when "PUCCHFormat == 3").
        %   Choose between 'BPSK', 'pi/2-BPSK', 'QPSK'.
        Modulation (1, :) char {mustBeMember(Modulation, {'BPSK', 'pi/2-BPSK', 'QPSK'})} = 'QPSK'
        %PUCCH Format (2, 3).
        PUCCHFormat double {mustBeInteger, mustBeInRange(PUCCHFormat, 2, 3)} = 2
        %Number of UCI information bits.
        NumUCIBits double {mustBeInteger, mustBeGreaterThan(NumUCIBits, 2)} = 4
        %Channel delay profile ('AWGN'(no delay), 'TDL-A'(Indoor hotspot model)).
        DelayProfile (1, :) char {mustBeMember(DelayProfile, {'AWGN', 'TDL-C', 'TDLC300'})} = 'AWGN'
        %TDL-A delay profile only: Delay spread in seconds.
        DelaySpread (1, 1) double {mustBeReal, mustBeNonnegative} = 300e-9
        %TDL-A delay profile only: Maximum Doppler shift in hertz.
        MaximumDopplerShift (1, 1) double {mustBeReal, mustBeNonnegative} = 100
        %PUCCH implementation type ('matlab').
        ImplementationType (1, :) char {mustBeMember(ImplementationType, {'matlab'})} = 'matlab'
    end % of properties (Nontunable)

    properties % Tunable
        %Flag for displaying simulation information.
        DisplaySimulationInformation (1, 1) logical = false
        %Quick-simulation flag: set to true to stop each point after 100 failed transport blocks.
        QuickSimulation (1, 1) logical = true
    end % of properties Tunable

    properties (SetAccess = private)
        %SNR range in dB.
        SNRrange = []
        %Counter of transmitted UCI messages.
        TotalBlocksCtr = []
        %Counter of missed UCI messages.
        MissedBlocksMATLABCtr = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %Block error rate (MATLAB case).
        BlockErrorRateMATLAB
    end % of properties (Dependable)

    properties (Access = private, Hidden)
        %Carrier configuration.
        Carrier
        %FFT size.
        Nfft
        %PUCCH configuration.
        PUCCH
        %Channel system object.
        Channel
    end % of properties (Access = private, Hidden)

    methods (Access = private)

        function checkPUCCHandSymbolAll(obj)
            if ((obj.PUCCHFormat == 2) && (obj.SymbolAllocation(2) > 2))
                error('PUCCH Format2 only allows the allocation of 1 or 2 OFDM symbols - requested %d.', obj.SymbolAllocation(2));
            end
            if ((obj.PUCCHFormat == 3) && (obj.SymbolAllocation(2) < 4))
                error('PUCCH Format3 requires the allocation of at least 4 OFDM symbols - requested %d.', obj.SymbolAllocation(2));
            end
        end % of function checkPUCCHandSymbolAll(obj)

        function checkPRBSetandGrid(obj)
            if (max(obj.PRBSet) > obj.NSizeGrid - 1)
                error('PRB allocation and resource grid are incompatible.');
            end
        end

    end % of methods (Access = private)

    methods % public

        function set.SymbolAllocation(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'size', [1, 2], '>=', 0, '<=', 14});
            if (value(2) == 0)
                error('At least one OFDM should be allocated for PUCCH transmission.');
            end
            if (value(1) + value(2) > 14)
                error('Cannot allocate %d OFDM symbols starting from OFDM symbol %d.', value(2), value(1));
            end
            obj.SymbolAllocation = value;
        end

        function set.PRBSet(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'vector', 'nonempty', ...
                '>=', 0, '<=', 274});
            if any(value(2:end) - value(1:end-1) ~= 1)
                error('The PRB allocation set should be contiguous.');
            end
            obj.PRBSet = value;
        end

        function bler = get.BlockErrorRateMATLAB(obj)
            bler = obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function plot(obj)
        %Display the measured throughput and BLER.

            if (isempty(obj.SNRrange))
                warning('Empty simulation data.');
                return;
            end

            implementationType = obj.ImplementationType;

            plotMATLAB = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
            plotSRS = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

            titleString = sprintf('PUCCH F%d / NRB=%d / SCS=%dkHz', ...
                obj.PUCCHFormat, obj.SymbolAllocation(2), obj.SubcarrierSpacing);
            legendstrings = {};

            figure;
            set(gca, "YScale", "log")
            if plotMATLAB
                semilogy(obj.SNRrange, obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr, 'o-.', ...
                    'LineWidth', 1)
                legendstrings{end + 1} = 'MATLAB';
            end
            if plotSRS
                hold on;
                semilogy(obj.SNRrange, obj.MissedBlocksSRSCtr ./ obj.TotalBlocksCtr, '^-.', ...
                    'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980])
                legendstrings{end + 1} = 'SRS';
                hold off;
            end
            xlabel('SNR (dB)'); ylabel('BLER'); grid on; legend(legendstrings);
            title(titleString);
        end % of function plot()

    end % of methods public

    methods (Access = protected)

        function setupImpl(obj)
            % Set carrier resource grid properties.
            obj.Carrier = nrCarrierConfig;
            obj.Carrier.NCellID = obj.NCellID;
            obj.Carrier.SubcarrierSpacing = obj.SubcarrierSpacing;
            obj.Carrier.CyclicPrefix = "normal";

            obj.Carrier.NSizeGrid = obj.NSizeGrid;
            obj.Carrier.NStartGrid = 0;

            % Set PUCCH properties.
            if (obj.PUCCHFormat == 2)
                obj.PUCCH = nrPUCCH2Config;
                obj.PUCCH.NID0 = 0;
            else % if PUCCH Format 3
                obj.PUCCH = nrPUCCH3Config;
                obj.PUCCH.Modulation = obj.Modulation;
                obj.PUCCH.GroupHopping = "neither";
                obj.PUCCH.HoppingID = 0;
                obj.PUCCH.AdditionalDMRS = 0;
            end
            obj.PUCCH.PRBSet = obj.PRBSet;
            obj.PUCCH.SymbolAllocation = obj.SymbolAllocation;
            obj.PUCCH.FrequencyHopping = "intraSlot";
            obj.PUCCH.SecondHopStartPRB = (obj.NSizeGrid-1) - (numel(obj.PRBSet)-1);
            obj.PUCCH.NID = [];
            obj.PUCCH.RNTI = obj.RNTI;

            % The simulation relies on various pieces of information about the baseband
            % waveform, such as sample rate.
            waveformInfo = nrOFDMInfo(obj.Carrier); % Get information about the baseband waveform after OFDM modulation step.

            % Store the FFT size.
            obj.Nfft = waveformInfo.Nfft;

            % Set up TDL channel.
            channel = nrTDLChannel;

            % Set the channel geometry.
            channel.NumTransmitAntennas = obj.NTxAnts;
            channel.NumReceiveAntennas = obj.NRxAnts;

            % Assign simulation channel parameters and waveform sample rate to the object.
            channel.SampleRate = waveformInfo.SampleRate;
            channel.DelaySpread = obj.DelaySpread;
            channel.TransmissionDirection = 'Uplink';

            if strcmp(obj.DelayProfile, 'AWGN')
                channel.DelayProfile = 'custom';
                channel.MaximumDopplerShift = 0;
                channel.PathDelays = 0;
                channel.AveragePathGains = 0;
            else
                channel.MaximumDopplerShift = obj.MaximumDopplerShift;
                channel.DelayProfile = obj.DelayProfile;
                channel.MIMOCorrelation = 'low';
            end

            obj.Channel = channel;
        end % function setupImpl(obj)

        function validatePropertiesImpl(obj)
            obj.checkPUCCHandSymbolAll();
            obj.checkPRBSetandGrid();
        end % of function validatePropertiesImpl(obj)

        function stepImpl(obj, SNRIn, nFrames)
            arguments
                obj (1, 1) PUCCHBLER
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

            % Take copies of channel-level parameters to simplify subsequent parameter referencing.
            carrier = obj.Carrier;
            pucch = obj.PUCCH;
            nTxAnts = obj.NTxAnts;
            nRxAnts = obj.NRxAnts;
            ouci = obj.NumUCIBits;
            nFFT = obj.Nfft;
            symbolsPerSlot = obj.Carrier.SymbolsPerSlot;
            slotsPerFrame = obj.Carrier.SlotsPerFrame;
            perfectChannelEstimator = obj.PerfectChannelEstimator;
            displaySimulationInformation = obj.DisplaySimulationInformation;

            quickSim = obj.QuickSimulation;

            blerUCI = zeros(numel(SNRIn), 1);
            totalBlocks = zeros(length(SNRIn), 1);

            for snrIdx = 1:numel(SNRIn)

                % Reset the random number generator so that each SNR point will
                % experience the same noise realization.
                rng('default')
                reset(obj.Channel)

                % Initialize variables for this SNR point (required when using
                % Parallel Computing Toolbox).
                pathFilters = [];

                % Get operating SNR value.
                SNRdB = SNRIn(snrIdx);

                % Get total number of slots in the simulation period.
                NSlots = nFrames*slotsPerFrame;

                % Set timing offset, which is updated in every slot for perfect
                % synchronization and when correlation is strong for practical
                % synchronization.
                offset = 0;

                for nslot = 0:NSlots-1

                    % Update carrier slot number to account for new slot transmission.
                    carrier.NSlot = nslot;

                    % Get PUCCH resources.
                    [pucchIndices, pucchIndicesInfo] = nrPUCCHIndices(carrier, pucch);
                    dmrsIndices = nrPUCCHDMRSIndices(carrier, pucch);
                    dmrsSymbols = nrPUCCHDMRS(carrier, pucch);

                    % Create random UCI bits.
                    uci = randi([0 1], ouci, 1);

                    % Perform UCI encoding.
                    codedUCI = nrUCIEncode(uci, pucchIndicesInfo.G);

                    % Perform PUCCH modulation.
                    pucchSymbols = nrPUCCH(carrier, pucch, codedUCI);

                    % Create resource grid associated with PUCCH transmission antennas.
                    pucchGrid = nrResourceGrid(carrier, nTxAnts);

                    % Perform implementation-specific PUCCH MIMO precoding and mapping.
                    F = eye(1, nTxAnts);
                    [~, pucchAntIndices] = nrExtractResources(pucchIndices, pucchGrid);
                    pucchGrid(pucchAntIndices) = pucchSymbols*F;

                    % Perform implementation-specific PUCCH DM-RS MIMO precoding and mapping.
                    [~, dmrsAntIndices] = nrExtractResources(dmrsIndices, pucchGrid);
                    pucchGrid(dmrsAntIndices) = dmrsSymbols*F;

                    % Perform OFDM modulation.
                    txWaveform = nrOFDMModulate(carrier, pucchGrid);

                    % Pass data through the channel model. Append zeros at the end of
                    % the transmitted waveform to flush the channel content. These
                    % zeros take into account any delay introduced in the channel. This
                    % delay is a combination of the multipath delay and implementation
                    % delay. This value can change depending on the sampling rate,
                    % delay profile, and delay spread.
                    txWaveformChDelay = [txWaveform; zeros(maxChDelay, size(txWaveform, 2))];
                    [rxWaveform, pathGains, sampleTimes] = obj.Channel(txWaveformChDelay);

                    % Add AWGN to the received time domain waveform. Normalize the
                    % noise power by the size of the inverse fast Fourier transform
                    % (IFFT) used in OFDM modulation, because the OFDM modulator
                    % applies this normalization to the transmitted waveform. Also,
                    % normalize the noise power by the number of receive antennas,
                    % because the default behavior of the channel model is to apply
                    % this normalization to the received waveform.
                    SNR = 10^(SNRdB/20);
                    N0 = 1/(sqrt(2.0*nRxAnts*nFFT)*SNR);
                    noise = N0*complex(randn(size(rxWaveform)), randn(size(rxWaveform)));
                    rxWaveform = rxWaveform + noise;

                    % Perform synchronization.
                    if perfectChannelEstimator == 1
                        % For perfect synchronization, use the information provided by
                        % the channel to find the strongest multipath component.
                        pathFilters = getPathFilters(obj.Channel);
                        [offset, ~] = nrPerfectTimingEstimate(pathGains, pathFilters);
                    else
                        % For practical synchronization, correlate the received
                        % waveform with the PUCCH DM-RS to give timing offset estimate
                        % t and correlation magnitude mag. The function hSkipWeakTimingOffset
                        % is used to update the receiver timing offset. If the correlation
                        % peak in mag is weak, the current timing estimate t is ignored
                        % and the previous estimate offset is used.
                        [t, mag] = nrTimingEstimate(carrier, rxWaveform, dmrsIndices, dmrsSymbols);
                        offset = hSkipWeakTimingOffset(offset, t, mag);

                        % Display a warning if the estimated timing offset exceeds the
                        % maximum channel delay.
                        if offset > maxChDelay
                            warning(['Estimated timing offset (%d) is greater than the maximum channel delay (%d).' ...
                                ' This will result in a decoding failure. This may be caused by low SNR,' ...
                                ' or not enough DM-RS symbols to synchronize successfully.'], offset, maxChDelay);
                        end
                    end
                    rxWaveform = rxWaveform(1+offset:end,:);

                    % Perform OFDM demodulation on the received data to recreate the
                    % resource grid. Include zero padding in the event that practical
                    % synchronization results in an incomplete slot being demodulated.
                    rxGrid = nrOFDMDemodulate(carrier, rxWaveform);
                    [K, L, R] = size(rxGrid);
                    if (L < symbolsPerSlot)
                        rxGrid = cat(2, rxGrid, zeros(K, symbolsPerSlot-L, R));
                    end

                    % Perform channel estimation.
                    if perfectChannelEstimator == 1
                        % For perfect channel estimation, use the value of the path
                        % gains provided by the channel.
                        estChannelGrid = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);

                        % Get the perfect noise estimate (from the noise realization).
                        noiseGrid = nrOFDMDemodulate(carrier, noise(1+offset:end,:));
                        noiseEst = var(noiseGrid(:));

                        % Apply MIMO deprecoding to estChannelGrid to give an
                        % estimate per transmission layer.
                        K = size(estChannelGrid, 1);
                        estChannelGrid = reshape(estChannelGrid, K*symbolsPerSlot*nRxAnts, nTxAnts);
                        estChannelGrid = estChannelGrid*F.';
                        estChannelGrid = reshape(estChannelGrid, K, symbolsPerSlot, nRxAnts, []);
                    else
                        % For practical channel estimation, use PUCCH DM-RS.
                        [estChannelGrid, noiseEst] = nrChannelEstimate(carrier, rxGrid, dmrsIndices, dmrsSymbols);
                    end

                    % Get PUCCH REs from received grid and estimated channel grid.
                    [pucchRx, pucchHest] = nrExtractResources(pucchIndices, rxGrid, estChannelGrid);

                    % Perform equalization.
                    pucchEq = nrEqualizeMMSE(pucchRx, pucchHest, noiseEst);

                    % Decode PUCCH symbols.
                    uciLLRs = nrPUCCHDecode(carrier, pucch, ouci, pucchEq, noiseEst);

                    % Decode UCI.
                    decucibits = nrUCIDecode(uciLLRs{1}, ouci);

                    % Store values to calculate BLER.
                    blerUCI(snrIdx) = blerUCI(snrIdx) + (~isequal(decucibits, uci));
                    totalBlocks(snrIdx) = totalBlocks(snrIdx) + 1;

                    % To speed the simulation up, we stop after 100 missed transport blocks.
                    if quickSim && (blerUCI(snrIdx) >= 100)
                        break;
                    end
                end

                % Display results dynamically.
                if displaySimulationInformation == 1
                    fprintf(['UCI BLER of PUCCH Format ' num2str(obj.PUCCHFormat) ' for ' num2str(nFrames) ...
                        ' frame(s) at SNR ' num2str(SNRIn(snrIdx)) ' dB: ' num2str(blerUCI(snrIdx)/totalBlocks(snrIdx)) '\n'])
                end
            end % of for snrIdx = 1:numel(snrIn)

            % Export results.
            [~, repeatedIdx] = intersect(obj.SNRrange, SNRIn);
            obj.SNRrange(repeatedIdx) = [];
            [obj.SNRrange, sortedIdx] = sort([obj.SNRrange SNRIn]);

            obj.TotalBlocksCtr = joinArrays(obj.TotalBlocksCtr, totalBlocks, repeatedIdx, sortedIdx);
            obj.MissedBlocksMATLABCtr = joinArrays(obj.MissedBlocksMATLABCtr, blerUCI, repeatedIdx, sortedIdx);

        end % of function stepImpl(obj, SNRIn, nFrames)

        function resetImpl(obj)
            % Reset internal system objects.
            reset(obj.Channel);

            % Reset simulation results.
            obj.SNRrange = [];
            obj.TotalBlocksCtr = [];
            obj.MissedBlocksMATLABCtr = [];
        end % of function resetImpl(obj)

        function releaseImpl(obj)
            % Release internal system objects.
            release(obj.Channel);
        end % of function releaseImpl(obj)

        function flag = isInactivePropertyImpl(obj, property)
            switch property
                case 'DelaySpread'
                    flag = strcmp(obj.DelayProfile, 'AWGN') || strcmp(obj.DelayProfile, 'TDLC300');
                case 'Modulation'
                    flag = (obj.PUCCHFormat == 2);
                case {'SNRrange', 'TotalBlocksCtr', 'MissedBlocksMATLABCtr'}
                    flag = isempty(obj.SNRrange);
                case 'BlockErrorRateMATLAB'
                    flag = isempty(obj.MissedBlocksMATLABCtr);
                otherwise
                    flag = false;
            end
        end % of function flag = isInactivePropertyImpl(obj, property)

        function groups = getPropertyGroups(obj)

            confProps = {...
                ... Generic.
                'NCellID', 'RNTI', ...
                ... Resource grid.
                'SubcarrierSpacing', 'NSizeGrid', ...
                ... PUCCH.
                'PUCCHFormat', 'PRBSet', 'SymbolAllocation', 'Modulation', 'NumUCIBits', ...
                ... Antennas and layers.
                'NRxAnts', 'NTxAnts', ...
                ... Channel model.
                'DelayProfile', 'DelaySpread', 'MaximumDopplerShift', 'PerfectChannelEstimator', ...
                ... Other simulation details.
                'ImplementationType', 'QuickSimulation', 'DisplaySimulationInformation'};
            groups = matlab.mixin.util.PropertyGroup(confProps, 'Configuration');

            results = {'SNRrange', 'TotalBlocksCtr', 'MissedBlocksMATLABCtr', 'BlockErrorRateMATLAB'};
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
        end % of function groups = getPropertyGroups(obj)

        function s = saveObjectImpl(obj)
            % Save all public properties.
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                % Save child objects.
                s.Carrier = obj.Carrier;
                s.PUCCH = obj.PUCCH;
                s.Channel = matlab.System.saveObject(obj.Channel);

                % Save FFT size.
                s.Nfft = obj.Nfft;

                % Save counters.
                s.SNRrange = obj.SNRrange;
                s.TotalBlocksCtr = obj.TotalBlocksCtr;
                s.MissedBlocksMATLABCtr = obj.MissedBlocksMATLABCtr;
            end
        end % of function s = saveObjectImpl(obj)

        function loadObjectImpl(obj, s, wasInUse)
            if wasInUse
                % Load child objects.
                obj.Carrier = s.Carrier;
                obj.PUCCH = s.PUCCH;
                obj.Channel = matlab.System.loadObject(s.Channel);

                % Load FFT size.
                obj.Nfft = s.Nfft;

                % Load counters.
                obj.SNRrange = s.SNRrange;
                obj.TotalBlocksCtr = s.TotalBlocksCtr;
                obj.MissedBlocksMATLABCtr = s.MissedBlocksMATLABCtr;
            end

            % Load all public properties.
            loadObjectImpl@matlab.System(obj, s, wasInUse);
        end % function loadObjectImpl(obj, s, wasInUse)

    end % of methods (Access = protected)
end % of classdef PUCCHBLER < matlab.System

% %% Local Functions
function mixedArray = joinArrays(arrayA, arrayB, removeFromA, outputOrder)
    arrayA(removeFromA) = [];
    mixedArray = [arrayA; arrayB];
    mixedArray = mixedArray(outputOrder);
end

