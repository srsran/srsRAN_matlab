classdef PUSCHBLER < handle
    properties
        %Perfect channel estimation flag.
        PerfectChannelEstimator (1, 1) logical = true
        %Flag for displaying simulation information.
        DisplaySimulationInformation (1, 1) logical = false
        %Flag for displaying simulation diagnostics.
        DisplayDiagnostics (1, 1) logical = false
        %Bandwidth in number of resource blocks.
        NSizeGrid = 52
        %Subcarrier spacing in kHz.
        SubcarrierSpacing = 15
        %Cyclic prefix: 'Normal' or 'Extended' (Extended CP is relevant for 60 kHz SCS only)
        CyclicPrefix = 'Normal'
        %Cell identity.
        NCellID (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1
        %PUSCH allocated PRBs.
        PRBSet = 0:51
        %PUSCH OFDM symbol allocation in each slot.
        SymbolAllocation = [0, 13]
        %PUSCH mapping type ('A'(slot-wise), (1)B'(non slot-wise)).
        MappingType (1, 1) char {mustBeMember(MappingType, ['A', 'B'])} = 'A'
        %Radio network temporary identifier (0,...,65535),
        RNTI (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(RNTI, 0, 65535)} = 1
        %Number of PUSCH transmission layers.
        NumLayers (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(NumLayers, 1, 4)} = 1
        %Modulation scheme.
        Modulation (1, :) char {mustBeMember(Modulation, {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'})} = 'QPSK'
        %Target code rate.
        TargetCodeRate (1, 1) double {mustBeReal, mustBeInRange(TargetCodeRate, 0, 1, 'exclusive')} = 193 / 1024
        %Mapping type A only: First DM-RS symbol position (2, 3).
        DMRSTypeAPosition (1, 1) double {mustBeReal, mustBeMember(DMRSTypeAPosition, [2, 3])} = 2
        %Number of front-loaded DM-RS symbols (1(single symbol), 2(double symbol)).
        DMRSLength (1, 1) double {mustBeReal, mustBeMember(DMRSLength, [1, 2])} = 1
        %Additional DM-RS symbol positions (max range 0...3).
        DMRSAdditionalPosition (1, 1) double {mustBeReal, mustBeMember(DMRSAdditionalPosition, [0, 1, 2, 3])} = 1
        %DM-RS configuration type (1, 2).
        DMRSConfigurationType (1, 1) double {mustBeReal, mustBeMember(DMRSConfigurationType, [1, 2])} = 1
        %Channel delay profile ('AWGN'(no delay), 'TDL-A'(Indoor hotspot model)).
        DelayProfile (1, :) char {mustBeMember(DelayProfile, {'AWGN', 'TDL-A'})} = 'TDL-A'
        %TDL-A delay profile only: Delay spread in seconds.
        DelaySpread (1, 1) double {mustBeReal, mustBeNonnegative} = 30e-9
        %TDL-A delay profile only: Maximum Doppler shift in hertz.
        MaximumDopplerShift (1, 1) double {mustBeReal, mustBeNonnegative} = 5
        %HARQ flag: true for enabling retransmission with RV sequence [0, 2, 3, 1], false for no retransmissions.
        EnableHARQ (1, 1) logical = false
        %PUSCH decoder type ('matlab', 'srs' (requires mex), 'both')
        DecoderType (1, :) char {mustBeMember(DecoderType, {'matlab', 'srs', 'both'})} = 'matlab'
    end % of properties

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
        %Counter of missed trasport blocks, after all allowed retransmissions (MATLAB case).
        MissedBlocksMATLABCtr = []
        %Counter of missed trasport blocks, after all allowed retransmissions (SRS case).
        MissedBlocksSRSCtr = []
        %Transport block size in bits.
        TBS = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %Throughput in Mbps (MATLAB case).
        ThroughputMATLAB
        %Throughput in Mbps (SRS case).
        ThroughputSRS
        %Block error rate (MATLAB case).
        BlockErrorRateMATLAB
        %Block error rate (SRS case).
        BlockErrorRateSRS
    end % of properties (Dependable)

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
    end % of methods (Access = private)

    methods
        function set.NSizeGrid(obj, value)
            validateattributes(value, 'numeric', {'real', 'scalar', '>', 0});
            obj.NSizeGrid = value;
            obj.checkPRBSetandGrid();
        end

        function set.SubcarrierSpacing(obj, value)
            validateattributes(value, 'numeric', {'real', 'scalar'});
            mustBeMember(value, [15, 30, 60, 120])

            obj.SubcarrierSpacing = value;
            obj.checkSCSandCP();
        end

        function set.CyclicPrefix(obj, value)
            validateattributes(value, 'char', {});
            mustBeMember(value, {'Normal', 'Extended'})

            obj.CyclicPrefix = value;
            obj.checkSCSandCP();
        end

        function set.PRBSet(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'vector', 'nonempty', ...
                '>=', 0, '<=', 274});
            obj.PRBSet = value;
            obj.checkPRBSetandGrid();
        end

        function set.SymbolAllocation(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'size', [1, 2], '>=', 0, '<=', 14});
            if (value(1) + value(2) > 14)
                error('Cannot allocate %d OFDM symbols starting from OFDM symbol %d.', value(2), value(1));
            end
            obj.SymbolAllocation = value;
        end

        function tp = get.ThroughputMATLAB(obj)
            tp = 1e-6 * obj.ThroughputMATLABCtr ./ (obj.MaxThroughputCtr / obj.TBS * 1e-3);
        end

        function tp = get.ThroughputSRS(obj)
            tp = 1e-6 * obj.ThroughputSRSCtr ./ (obj.MaxThroughputCtr / obj.TBS * 1e-3);
        end

        function bler = get.BlockErrorRateMATLAB(obj)
            bler = obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function bler = get.BlockErrorRateSRS(obj)
            bler = obj.MissedBlocksSRSCtr ./ obj.TotalBlocksCtr;
        end

        function run(obj, SNRIn, nFrames)
            arguments
                obj (1, 1) PUSCHBLER
                %SNR range in dB.
                SNRIn double {mustBeReal, mustBeFinite, mustBeVector}
                %Number of 10 ms frames.
                nFrames (1, 1) double {mustBeInteger, mustBePositive} = 10
            end

            % Ensure SNRIn has no repetitions and is a row vector.
            SNRIn = unique(SNRIn);
            SNRIn = SNRIn(:).';

            % Simulation Length and SNR Points.
            simParameters = struct();             % Clean simParameters structure to contain all key simulation parameters.
            simParameters.NFrames = nFrames;
            simParameters.SNRIn = SNRIn;

            % Channel Estimator Configuration.
            simParameters.PerfectChannelEstimator = obj.PerfectChannelEstimator;

            % Simulation Diagnostics.
            simParameters.DisplaySimulationInformation = obj.DisplaySimulationInformation;
            simParameters.DisplayDiagnostics = obj.DisplayDiagnostics;

            % Carrier and PUSCH Configuration.
            %
            % Set waveform type and PUSCH numerology (SCS and CP type).
            simParameters.Carrier = nrCarrierConfig;         % Clean carrier resource grid configuration.
            simParameters.Carrier.NSizeGrid = obj.NSizeGrid;
            simParameters.Carrier.SubcarrierSpacing = obj.SubcarrierSpacing;
            simParameters.Carrier.CyclicPrefix = obj.CyclicPrefix;
            simParameters.Carrier.NCellID = obj.NCellID;

            % PUSCH/UL-SCH parameters.
            simParameters.PUSCH = nrPUSCHConfig;      % This PUSCH definition is the basis for all PUSCH transmissions in the BLER simulation.
            simParameters.PUSCHExtension = struct();  % This structure is to hold additional simulation parameters for the UL-SCH and PUSCH.

            % Define PUSCH time-frequency resource allocation per slot.
            simParameters.PUSCH.PRBSet =  obj.PRBSet;
            simParameters.PUSCH.SymbolAllocation = obj.SymbolAllocation;
            simParameters.PUSCH.MappingType = obj.MappingType;

            % Scrambling identifiers.
            simParameters.PUSCH.NID = simParameters.Carrier.NCellID;
            simParameters.PUSCH.RNTI = obj.RNTI;

            % Define the transform precoding enabling, layering and transmission scheme.
            simParameters.PUSCH.TransformPrecoding = false;         % Enable/disable transform precoding.
            simParameters.PUSCH.NumLayers = obj.NumLayers;
            simParameters.PUSCH.TransmissionScheme = 'nonCodebook'; % Transmission scheme ('nonCodebook', 'codebook').
            simParameters.PUSCH.NumAntennaPorts = 1;                % Number of antenna ports for codebook based precoding.
            simParameters.PUSCH.TPMI = 0;                           % Precoding matrix indicator for codebook based precoding.

            % Define codeword modulation.
            simParameters.PUSCH.Modulation = obj.Modulation;

            % PUSCH DM-RS configuration.
            simParameters.PUSCH.DMRS.DMRSTypeAPosition = obj.DMRSTypeAPosition;
            simParameters.PUSCH.DMRS.DMRSLength = obj.DMRSLength;
            simParameters.PUSCH.DMRS.DMRSAdditionalPosition = obj.DMRSAdditionalPosition;
            simParameters.PUSCH.DMRS.DMRSConfigurationType = obj.DMRSConfigurationType;
            simParameters.PUSCH.DMRS.NumCDMGroupsWithoutData = 2; % Number of CDM groups without data.
            simParameters.PUSCH.DMRS.NIDNSCID = 0;                % Scrambling identity (0...65535).
            simParameters.PUSCH.DMRS.NSCID = 0;                   % Scrambling initialization (0, 1).
            simParameters.PUSCH.DMRS.NRSID = 0;                   % Scrambling ID for low-PAPR sequences (0...1007).
            simParameters.PUSCH.DMRS.GroupHopping = 0;            % Group hopping (0, 1).
            simParameters.PUSCH.DMRS.SequenceHopping = 0;         % Sequence hopping (0, 1).

            % Additional simulation and UL-SCH related parameters.
            %
            % Target code rate
            simParameters.PUSCHExtension.TargetCodeRate = obj.TargetCodeRate;
            %
            % HARQ process and rate matching/TBS parameters
            simParameters.PUSCHExtension.XOverhead = 0;       % Set PUSCH rate matching overhead for TBS (Xoh).
            simParameters.PUSCHExtension.NHARQProcesses = 16; % Number of parallel HARQ processes to use.
            simParameters.PUSCHExtension.EnableHARQ = obj.EnableHARQ;

            % LDPC decoder parameters.
            % Available algorithms: 'Belief propagation', 'Layered belief propagation', 'Normalized min-sum', 'Offset min-sum'.
            simParameters.PUSCHExtension.LDPCDecodingAlgorithm = 'Normalized min-sum';
            simParameters.PUSCHExtension.MaximumLDPCIterationCount = 6;

            % Define the overall transmission antenna geometry at end-points.
            % If using a CDL propagation channel then the integer number of antenna elements is
            % turned into an antenna panel configured when the channel model object is created.
            simParameters.NTxAnts = 1; % Number of transmit antennas.
            simParameters.NRxAnts = 1; % Number of receive antennas.

            % Define the general CDL/TDL propagation channel parameters
            simParameters.DelayProfile = obj.DelayProfile;
            simParameters.DelaySpread = obj.DelaySpread;
            simParameters.MaximumDopplerShift = obj.MaximumDopplerShift;

            % Cross-check the PUSCH layering against the channel geometry
            validateNumLayers(simParameters);

            % The simulation relies on various pieces of information about the baseband
            % waveform, such as sample rate.
            waveformInfo = nrOFDMInfo(simParameters.Carrier); % Get information about the baseband waveform after OFDM modulation step

            % Constructed the CDL or TDL channel model object
            if contains(simParameters.DelayProfile, 'CDL', 'IgnoreCase', true)

                channel = nrCDLChannel; % CDL channel object

                % Turn the overall number of antennas into a specific antenna panel
                % array geometry. The number of antennas configured is updated when
                % nTxAnts is not one of (1,2,4,8,16,32,64,128,256,512,1024) or nRxAnts
                % is not 1 or even.
                [channel.TransmitAntennaArray.Size, channel.ReceiveAntennaArray.Size] = ...
                    hArrayGeometry(simParameters.NTxAnts, simParameters.NRxAnts, 'uplink');
                nTxAnts = prod(channel.TransmitAntennaArray.Size);
                nRxAnts = prod(channel.ReceiveAntennaArray.Size);
                simParameters.NTxAnts = nTxAnts;
                simParameters.NRxAnts = nRxAnts;
                % Configure antenna elements
                channel.TransmitAntennaArray.Element = 'isotropic';
                channel.ReceiveAntennaArray.Element = '38.901';
                channel.DelaySpread = simParameters.DelaySpread;
            else
                channel = nrTDLChannel; % TDL channel object

                % Set the channel geometry
                channel.NumTransmitAntennas = simParameters.NTxAnts;
                channel.NumReceiveAntennas = simParameters.NRxAnts;
                channel.DelaySpread = simParameters.DelaySpread;

                if strcmp(simParameters.DelayProfile, 'AWGN')
                    simParameters.DelayProfile = 'custom';
                    channel.DelayProfile = 'custom';
                    channel.PathDelays = 0;
                    channel.AveragePathGains = 0;
                end
            end

            % Assign simulation channel parameters and waveform sample rate to the object
            channel.DelayProfile = simParameters.DelayProfile;
            channel.MaximumDopplerShift = simParameters.MaximumDopplerShift;
            channel.SampleRate = waveformInfo.SampleRate;

            % Get the maximum number of delayed samples by a channel multipath
            % component. This is calculated from the channel path with the largest
            % delay and the implementation delay of the channel filter. This is
            % required later to flush the channel filter to obtain the received signal.
            chInfo = info(channel);
            maxChDelay = ceil(max(chInfo.PathDelays*channel.SampleRate)) + chInfo.ChannelFilterDelay;

            % Array to store the maximum throughput and the number of transmitted transport blocks for all SNR points.
            maxThroughput = zeros(length(simParameters.SNRIn), 1);
            totalBlocks = zeros(length(simParameters.SNRIn), 1);

            % Set up redundancy version (RV) sequence for all HARQ processes.
            if simParameters.PUSCHExtension.EnableHARQ
                % From PUSCH demodulation requirements in RAN WG4 meeting #88bis (R4-1814062).
                rvSeq = [0 2 3 1];
            else
                % HARQ disabled - single transmission with RV=0, no retransmissions.
                rvSeq = 0;
            end

            % Create UL-SCH encoder System object to perform transport channel encoding.
            encodeULSCH = nrULSCH;
            encodeULSCH.MultipleHARQProcesses = true;
            encodeULSCH.TargetCodeRate = simParameters.PUSCHExtension.TargetCodeRate;

            useMATLABDecoder = (strcmp(obj.DecoderType, 'matlab') || strcmp(obj.DecoderType, 'both'));
            useSRSDecoder = (strcmp(obj.DecoderType, 'srs') || strcmp(obj.DecoderType, 'both'));

            % Create UL-SCH decoder System object to perform transport channel decoding
            % Use layered belief propagation for LDPC decoding, with half the number of
            % iterations as compared to the default for belief propagation decoding.
            decodeULSCH = nrULSCHDecoder;
            decodeULSCH.MultipleHARQProcesses = true;
            decodeULSCH.TargetCodeRate = simParameters.PUSCHExtension.TargetCodeRate;
            decodeULSCH.LDPCDecodingAlgorithm = simParameters.PUSCHExtension.LDPCDecodingAlgorithm;
            decodeULSCH.MaximumLDPCIterationCount = simParameters.PUSCHExtension.MaximumLDPCIterationCount;

            % Calculate the transport block size for the transmission in the slot.
            [puschIndices, puschIndicesInfo] = nrPUSCHIndices(simParameters.Carrier, simParameters.PUSCH);
            MRB = numel(simParameters.PUSCH.PRBSet);
            trBlkSize = nrTBS(simParameters.PUSCH.Modulation, simParameters.PUSCH.NumLayers, ...
                MRB, puschIndicesInfo.NREPerPRB, simParameters.PUSCHExtension.TargetCodeRate, simParameters.PUSCHExtension.XOverhead);
            obj.TBS = trBlkSize;

            % Array to store the simulation throughput and BLER for all SNR points.
            simThroughput = zeros(length(simParameters.SNRIn), 1);
            simBLER = zeros(length(simParameters.SNRIn), 1);

            [configSRS, segmentCfg] = srsPUSCHDecConfig(simParameters);
            decodeULSCHsrs = srsTest.phy.srsPUSCHDecoder('maxCodeblockSize', configSRS.max_codeblock_size, ...
                'maxSoftbuffers', configSRS.max_softbuffers, 'maxCodeblocks', configSRS.max_nof_codeblocks);

            % Array to store the simulation throughput and BLER for all SNR points.
            simThroughputSRS = zeros(length(simParameters.SNRIn), 1);
            simBLERSRS = zeros(length(simParameters.SNRIn), 1);

            % %%% Simulation loop.

            for snrIdx = 1:numel(simParameters.SNRIn)    % comment out for parallel computing

                % Reset the random number generator so that each SNR point will
                % experience the same noise realization.
                rng('default');

                % Take copies of channel-level parameters to simplify subsequent parameter referencing.
                carrier = simParameters.Carrier;
                pusch = simParameters.PUSCH;
                puschextra = simParameters.PUSCHExtension;
                decodeULSCH.reset();        % Reset decoder at the start of each SNR point
                pathFilters = [];

                % Create PUSCH object configured for the non-codebook transmission
                % scheme, used for receiver operations that are performed with respect
                % to the PUSCH layers.
                puschNonCodebook = pusch;
                puschNonCodebook.TransmissionScheme = 'nonCodebook';

                % Prepare simulation for new SNR point.
                SNRdB = simParameters.SNRIn(snrIdx);
                fprintf('\nSimulating transmission scheme 1 (%dx%d) and SCS=%dkHz with %s channel at %gdB SNR for %d 10ms frame(s)\n', ...
                    simParameters.NTxAnts, simParameters.NRxAnts, carrier.SubcarrierSpacing, ...
                    simParameters.DelayProfile, SNRdB, simParameters.NFrames);

                % Specify the fixed order in which we cycle through the HARQ process IDs.
                harqSequence = 0:puschextra.NHARQProcesses-1;

                % Initialize the state of all HARQ processes.
                harqEntity = HARQEntity(harqSequence, rvSeq);

                % Reset the channel so that each SNR point will experience the same
                % channel realization.
                reset(channel);

                % Total number of slots in the simulation period.
                NSlots = simParameters.NFrames * carrier.SlotsPerFrame;

                % Timing offset, updated in every slot for perfect synchronization and
                % when the correlation is strong for practical synchronization.
                offset = 0;

                % Loop over the entire waveform length
                for nslot = 0:NSlots-1

                    % Update the carrier slot numbers for new slot.
                    carrier.NSlot = nslot;

                    % HARQ processing
                    %
                    % Create HARQ ID for the SRS decoder.
                    % Set the HARQ ID.
                    harqBufID.rnti = pusch.RNTI;
                    harqBufID.harq_ack_id = harqEntity.HARQProcessID;
                    harqBufID.nof_codeblocks = segmentCfg.nof_codeblocks;

                    % If new data for current process then create a new UL-SCH transport block.
                    if harqEntity.NewData
                        trBlk = randi([0 1], trBlkSize, 1);
                        setTransportBlock(encodeULSCH, trBlk, harqEntity.HARQProcessID);
                        % If new data because of previous RV sequence time out then flush decoder soft buffer explicitly.
                        if harqEntity.SequenceTimeout
                            resetSoftBuffer(decodeULSCH, harqEntity.HARQProcessID);
                        end
                        % The SRS decoder must be reset explicitely in any case.
                        decodeULSCHsrs.resetCRCS(harqBufID);

                        % Increment counter of transmitted transport blocks.
                        totalBlocks(snrIdx) = totalBlocks(snrIdx) + 1;
                    end

                    % Encode the UL-SCH transport block.
                    codedTrBlock = encodeULSCH(pusch.Modulation, pusch.NumLayers, ...
                        puschIndicesInfo.G, harqEntity.RedundancyVersion, harqEntity.HARQProcessID);

                    % Create resource grid for a slot.
                    puschGrid = nrResourceGrid(carrier, simParameters.NTxAnts);

                    % PUSCH modulation, including codebook based MIMO precoding if TxScheme = 'codebook'.
                    puschSymbols = nrPUSCH(carrier, pusch, codedTrBlock);

                    % Implementation-specific PUSCH MIMO precoding and mapping. This
                    % MIMO precoding step is in addition to any codebook based
                    % MIMO precoding done during PUSCH modulation above.
                    if (strcmpi(pusch.TransmissionScheme, 'codebook'))
                        % Codebook based MIMO precoding, F precodes between PUSCH
                        % transmit antenna ports and transmit antennas.
                        F = eye(pusch.NumAntennaPorts, simParameters.NTxAnts);
                    else
                        % Non-codebook based MIMO precoding, F precodes between PUSCH
                        % layers and transmit antennas.
                        F = eye(pusch.NumLayers, simParameters.NTxAnts);
                    end
                    [~, puschAntIndices] = nrExtractResources(puschIndices, puschGrid);
                    puschGrid(puschAntIndices) = puschSymbols * F;

                    % Implementation-specific PUSCH DM-RS MIMO precoding and mapping.
                    % The first DM-RS creation includes codebook based MIMO precoding if applicable.
                    dmrsSymbols = nrPUSCHDMRS(carrier, pusch);
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
                    [rxWaveform, pathGains, sampleTimes] = channel(txWaveform);

                    % Add AWGN to the received time domain waveform
                    % Normalize noise power by the IFFT size used in OFDM modulation,
                    % as the OFDM modulator applies this normalization to the
                    % transmitted waveform. Also normalize by the number of receive
                    % antennas, as the channel model applies this normalization to the
                    % received waveform, by default.
                    SNR = 10^(SNRdB/10);
                    N0 = 1/sqrt(2.0*simParameters.NRxAnts*double(waveformInfo.Nfft)*SNR);
                    noise = N0*complex(randn(size(rxWaveform)), randn(size(rxWaveform)));
                    rxWaveform = rxWaveform + noise;

                    if (simParameters.PerfectChannelEstimator)
                        % Perfect synchronization. Use information provided by the
                        % channel to find the strongest multipath component.
                        pathFilters = getPathFilters(channel);
                        [offset, ~] = nrPerfectTimingEstimate(pathGains, pathFilters);
                    else
                        % Practical synchronization. Correlate the received waveform
                        % with the PUSCH DM-RS to give timing offset estimate 't' and
                        % correlation magnitude 'mag'. The function
                        % hSkipWeakTimingOffset is used to update the receiver timing
                        % offset. If the correlation peak in 'mag' is weak, the current
                        % timing estimate 't' is ignored and the previous estimate
                        % 'offset' is used.
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
                    rxWaveform = rxWaveform(1+offset:end, :);

                    % Perform OFDM demodulation on the received data to recreate the
                    % resource grid, including padding in the event that practical
                    % synchronization results in an incomplete slot being demodulated.
                    rxGrid = nrOFDMDemodulate(carrier, rxWaveform);
                    [K, L, R] = size(rxGrid);
                    if (L < carrier.SymbolsPerSlot)
                        rxGrid = cat(2, rxGrid, zeros(K, carrier.SymbolsPerSlot - L, R));
                    end

                    if (simParameters.PerfectChannelEstimator)
                        % Perfect channel estimation, use the value of the path gains
                        % provided by the channel.
                        estChannelGrid = nrPerfectChannelEstimate(carrier, pathGains, pathFilters, offset, sampleTimes);

                        % Get perfect noise estimate (from the noise realization).
                        noiseGrid = nrOFDMDemodulate(carrier, noise(1+offset:end, :));
                        noiseEst = var(noiseGrid(:));

                        % Apply MIMO deprecoding to estChannelGrid to give an estimate
                        % per transmission layer.
                        K = size(estChannelGrid, 1);
                        estChannelGrid = reshape(estChannelGrid, K*carrier.SymbolsPerSlot*simParameters.NRxAnts, simParameters.NTxAnts);
                        estChannelGrid = estChannelGrid * F.';
                        if (strcmpi(pusch.TransmissionScheme, 'codebook'))
                            W = nrPUSCHCodebook(pusch.NumLayers, pusch.NumAntennaPorts, pusch.TPMI, pusch.TransformPrecoding);
                            estChannelGrid = estChannelGrid * W.';
                        end
                        estChannelGrid = reshape(estChannelGrid, K, carrier.SymbolsPerSlot, simParameters.NRxAnts, []);
                    else
                        % Practical channel estimation between the received grid and
                        % each transmission layer, using the PUSCH DM-RS for each layer
                        % which are created by specifying the non-codebook transmission
                        % scheme.
                        dmrsLayerSymbols = nrPUSCHDMRS(carrier, puschNonCodebook);
                        dmrsLayerIndices = nrPUSCHDMRSIndices(carrier, puschNonCodebook);
                        [estChannelGrid, noiseEst] = nrChannelEstimate(carrier, rxGrid, dmrsLayerIndices, dmrsLayerSymbols, 'CDMLengths', pusch.DMRS.CDMLengths);
                    end

                    % Get PUSCH resource elements from the received grid.
                    [puschRx, puschHest] = nrExtractResources(puschIndices, rxGrid, estChannelGrid);

                    % Equalization.
                    [puschEq, csi] = nrEqualizeMMSE(puschRx, puschHest, noiseEst);

                    % Decode PUSCH physical channel.
                    [ulschLLRs, rxSymbols] = nrPUSCHDecode(carrier, puschNonCodebook, puschEq, noiseEst);

                    % Display EVM per layer, per slot and per RB. Reference symbols for
                    % each layer are created by specifying the non-codebook
                    % transmission scheme.
                    if (simParameters.DisplayDiagnostics)
                        refSymbols = nrPUSCH(carrier, puschNonCodebook, codedTrBlock);
                        plotLayerEVM(NSlots, nslot, puschNonCodebook, size(puschGrid), puschIndices, refSymbols, puschEq);
                    end

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

                    % Store values to calculate BLER.
                    isLastRetransmission = (harqEntity.RedundancyVersion == rvSeq(end));

                    blkerrBoth = false;

                    if useMATLABDecoder
                        % Decode the UL-SCH transport channel.
                        decodeULSCH.TransportBlockLength = trBlkSize;
                        [decbits, blkerr] = decodeULSCH(ulschLLRs, pusch.Modulation, pusch.NumLayers, harqEntity.RedundancyVersion, harqEntity.HARQProcessID);

                        % Store values to calculate throughput and BLER.
                        simThroughput(snrIdx) = simThroughput(snrIdx) + (~blkerr * trBlkSize);
                        simBLER(snrIdx) = simBLER(snrIdx) + (isLastRetransmission && any(decbits ~= trBlk));

                        blkerrBoth = blkerr;
                    end

                    if useSRSDecoder
                        % Decode the UL-SCH transport channel with the SRS decoder.
                        %
                        % First, quantize the LLRs.
                        llrsTmp = ulschLLRs;
                        llrsTmp(llrsTmp > 20) = 20;
                        llrsTmp(llrsTmp < -20) = -20;
                        ulschLLRsInt8 = int8(llrsTmp * 6);

                        % Set the RV.
                        segmentCfg.rv = harqEntity.RedundancyVersion;

                        [decbitsSRS, statsSRS] = decodeULSCHsrs(ulschLLRsInt8, harqEntity.NewData, segmentCfg, harqBufID);

                        % Store values to calculate throughput and BLER.
                        simThroughputSRS(snrIdx) = simThroughputSRS(snrIdx) + (statsSRS.crc_ok * trBlkSize);
                        simBLERSRS(snrIdx) = simBLERSRS(snrIdx) + (isLastRetransmission && any(decbitsSRS ~= srsTest.helpers.bitPack(trBlk)));

                        blkerrBoth = blkerrBoth || (~statsSRS.crc_ok);
                    end

                    % Increase total number of transmitted information bits.
                    maxThroughput(snrIdx) = maxThroughput(snrIdx) + trBlkSize;

                    % Update current process with CRC error and advance to next process
                    procstatus = updateAndAdvance(harqEntity, blkerrBoth, trBlkSize, puschIndicesInfo.G);
                    if (simParameters.DisplaySimulationInformation)
                        fprintf('\n(%3.2f%%) NSlot=%d, %s', 100*(nslot+1)/NSlots, nslot, procstatus);
                    end

                    % To speed the simulation up, we stop after 100 missed transport blocks.
                    if (~useMATLABDecoder || (simBLER(snrIdx) >= 100)) && (~useSRSDecoder || (simBLERSRS(snrIdx) >= 100))
                        break;
                    end
                end

                % Display the results dynamically in the command window.
                if (simParameters.DisplaySimulationInformation)
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

        end % of function run()

        function plot(obj)
            % Display the measured throughput and BLER.

            plotMATLABDecoder = (strcmp(obj.DecoderType, 'matlab') || strcmp(obj.DecoderType, 'both'));
            plotSRSDecoder = (strcmp(obj.DecoderType, 'srs') || strcmp(obj.DecoderType, 'both'));

            titleString = sprintf('NRB=%d / SCS=%dkHz / %s %d/1024', ...
                obj.NSizeGrid, obj.SubcarrierSpacing, obj.Modulation, ...
                round(obj.TargetCodeRate*1024));
            figure;
            legendstrings = {};

            if plotMATLABDecoder
                plot(obj.SNRrange, obj.ThroughputMATLABCtr * 100 ./ obj.MaxThroughputCtr, 'o-.')
                legendstrings{end + 1} = 'MATLAB';
            end
            if plotSRSDecoder
                hold on;
                plot(obj.SNRrange, obj.ThroughputSRSCtr * 100 ./ obj.MaxThroughputCtr, '^-.')
                legendstrings{end + 1} = 'SRS';
                hold off;
            end
            xlabel('SNR (dB)'); ylabel('Throughput (%)'); grid on; legend(legendstrings);
            title(titleString);

            figure;
            set(gca, "YScale", "log")
            if plotMATLABDecoder
                semilogy(obj.SNRrange, obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr, 'o-.')
            end
            if plotSRSDecoder
                hold on;
                semilogy(obj.SNRrange, obj.MissedBlocksSRSCtr ./ obj.TotalBlocksCtr, '^-.')
                hold off;
            end
            xlabel('SNR (dB)'); ylabel('BLER'); grid on; legend(legendstrings);
            title(titleString);
        end % of function plot()
    end % of methods
end % of classdef PUSCHBLER


% %% Local Functions
function mixedArray = joinArrays(arrayA, arrayB, removeFromA, outputOrder)
    arrayA(removeFromA) = [];
    mixedArray = [arrayA; arrayB];
    mixedArray = mixedArray(outputOrder);
end

function [cfg, segCfg] = srsPUSCHDecConfig(simParameters)
% Creates the configuration structure for the srsPUSCHDecoder.
    pusch = simParameters.PUSCH;
    carrier = simParameters.Carrier;
    puschextra = simParameters.PUSCHExtension;
    [~, puschIndicesInfo] = nrPUSCHIndices(carrier, pusch);
    MRB = numel(pusch.PRBSet);
    trBlkSize = nrTBS(pusch.Modulation, pusch.NumLayers, MRB, puschIndicesInfo.NREPerPRB, puschextra.TargetCodeRate, puschextra.XOverhead);

    segmentInfo = nrULSCHInfo(trBlkSize, puschextra.TargetCodeRate);

    cfg.max_nof_codeblocks = segmentInfo.C * puschextra.NHARQProcesses;
    cfg.max_codeblock_size = segmentInfo.N;
    cfg.max_softbuffers = puschextra.NHARQProcesses;
    cfg.expire_timeout_slots = 10;

    segCfg.nof_layers = pusch.NumLayers;
    segCfg.rv = 0;
    segCfg.Nref = 0;
    segCfg.nof_ch_symbols = puschIndicesInfo.Gd;
    segCfg.modulation = pusch.Modulation;
    segCfg.base_graph = segmentInfo.BGN;
    segCfg.tbs = trBlkSize;
    segCfg.nof_codeblocks = segmentInfo.C;
end

function validateNumLayers(simParameters)
% Validate the number of layers, relative to the antenna geometry

    numlayers = simParameters.PUSCH.NumLayers;
    ntxants = simParameters.NTxAnts;
    nrxants = simParameters.NRxAnts;
    antennaDescription = sprintf('min(NTxAnts, NRxAnts) = min(%d, %d) = %d', ntxants, nrxants, min(ntxants, nrxants));
    if numlayers > min(ntxants, nrxants)
        error('The number of layers (%d) must satisfy NumLayers <= %s', ...
            numlayers, antennaDescription);
    end

    % Display a warning if the maximum possible rank of the channel equals
    % the number of layers
    if (numlayers > 2) && (numlayers == min(ntxants, nrxants))
        warning(['The maximum possible rank of the channel, given by %s, is equal to NumLayers (%d).' ...
            ' This may result in a decoding failure under some channel conditions.' ...
            ' Try decreasing the number of layers or increasing the channel rank' ...
            ' (use more transmit or receive antennas).'], antennaDescription, numlayers); %#ok<SPWRN>
    end

end

function plotLayerEVM(NSlots, nslot, pusch, siz, puschIndices, puschSymbols, puschEq)
% Plot EVM information

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
