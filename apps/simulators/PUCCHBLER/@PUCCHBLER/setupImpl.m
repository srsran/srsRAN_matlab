%setupImpl System object setup method implementation.

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

function setupImpl(obj)
    % Set carrier resource grid properties.
    obj.Carrier = nrCarrierConfig;
    obj.Carrier.NCellID = obj.NCellID;
    obj.Carrier.SubcarrierSpacing = obj.SubcarrierSpacing;
    obj.Carrier.CyclicPrefix = "normal";

    obj.Carrier.NSizeGrid = obj.NSizeGrid;
    obj.Carrier.NStartGrid = 0;

    % Set PUCCH properties.
    if (obj.PUCCHFormat == 1)
        obj.PUCCH = nrPUCCH1Config;
        obj.PUCCH.GroupHopping = "neither";
        obj.PUCCH.HoppingID = 0;
        obj.PUCCH.InitialCyclicShift = 0;
        obj.PUCCH.OCCI = 0;
    elseif (obj.PUCCHFormat == 2)
        obj.PUCCH = nrPUCCH2Config;
        obj.PUCCH.NID0 = 0;
        obj.PUCCH.NID = [];
        obj.PUCCH.RNTI = obj.RNTI;
    else % if PUCCH Format3
        obj.PUCCH = nrPUCCH3Config;
        obj.PUCCH.Modulation = obj.Modulation;
        obj.PUCCH.GroupHopping = "neither";
        obj.PUCCH.HoppingID = 0;
        obj.PUCCH.AdditionalDMRS = 0;
        obj.PUCCH.NID = [];
        obj.PUCCH.RNTI = obj.RNTI;
    end
    obj.PUCCH.PRBSet = obj.PRBSet;
    obj.PUCCH.SymbolAllocation = obj.SymbolAllocation;
    obj.PUCCH.FrequencyHopping = obj.FrequencyHopping;
    if ~strcmp(obj.FrequencyHopping, 'neither')
        obj.PUCCH.SecondHopStartPRB = (obj.NSizeGrid-1) - (numel(obj.PRBSet)-1);
    end

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

    % Set helper function handles.
    if (obj.PUCCHFormat == 1)
        obj.updateStats = @updateStatsF1;
        obj.updateStatsSRS = @updateStatsSRSF1;
        obj.printMessages = @printMessagesF1;
        obj.printMessagesSRS = @printMessagesSRSF1;
    else
        obj.updateStats = @updateStatsF2;
        obj.updateStatsSRS = @updateStatsSRSF2;
        obj.printMessages = @printMessagesF2;
        obj.printMessagesSRS = @printMessagesSRSF2;
    end

end % function setupImpl(obj)

% %% Local Functions
function stats = updateStatsF1(stats, uci, uciRx, ~, NumACKBits, isDetectTest, snrIdx)
    if isDetectTest
        % If MATLAB's PUCCH decoder was able to detect a PUCCH and
        % uciRx contains the resulting bits.
        if ~isempty(uciRx{1})
            % NACK to ACK.
            stats.falseACK(snrIdx) = stats.falseACK(snrIdx) + sum(~uci & uciRx{1});
            stats.nNACKs(snrIdx) = stats.nNACKs(snrIdx) + sum(~uci);
            % Missed ACK.
            stats.missedACK(snrIdx) = stats.missedACK(snrIdx) + sum(uci & ~uciRx{1});
            stats.nACKs(snrIdx) = stats.nACKs(snrIdx) + sum(uci);
        else
            % Missed ACK. Here, uciRx is empty (MATLAB's PUCCH decoder failed
            % to detect) and all ACKs are lost.
            stats.missedACK(snrIdx) = stats.missedACK(snrIdx) + sum(uci);
            stats.nACKs(snrIdx) = stats.nACKs(snrIdx) + sum(uci);
        end
    else % false alarm test
        % False ACK.
        stats.falseACK(snrIdx) = stats.falseACK(snrIdx) + sum(uciRx{1});
        stats.nNACKs(snrIdx) = stats.nNACKs(snrIdx) + NumACKBits;
    end % if isDetectTest
end

function stats = updateStatsF2(stats, uci, uciRx, ouci, ~, isDetectTest, snrIdx)
    if isDetectTest
        % Decode UCI.
        decucibits = nrUCIDecode(uciRx{1}, ouci);

        % Store values to calculate BLER.
        stats.blerUCI(snrIdx) = stats.blerUCI(snrIdx) + (~isequal(decucibits, uci));
    else % false alarm test
        stats.blerUCI(snrIdx) = stats.blerUCI(snrIdx) + (~isempty(uciRx{1}));
    end % if isDetectTest
end

function stats = updateStatsSRSF1(stats, uci, msg, isDetectTest, snrIdx)
    uciRxSRS = msg.HARQAckPayload;
    if isDetectTest
        % If SRS's PUCCH decoder was able to detect a PUCCH.
        if msg.isValid
            % NACK to ACK.
            stats.falseACKSRS(snrIdx) = stats.falseACKSRS(snrIdx) + sum(~uci & uciRxSRS);
            stats.nNACKsSRS(snrIdx) = stats.nNACKsSRS(snrIdx) + sum(~uci);
            % Missed ACK.
            stats.missedACKSRS(snrIdx) = stats.missedACKSRS(snrIdx) + sum(uci & ~uciRxSRS);
            stats.nACKsSRS(snrIdx) = stats.nACKsSRS(snrIdx) + sum(uci);
        else
            % Missed ACK. Here, SRS's PUCCH decoder failed
            % to detect and all ACKs are lost.
            stats.missedACKSRS(snrIdx) = stats.missedACKSRS(snrIdx) + sum(uci);
            stats.nACKsSRS(snrIdx) = stats.nACKsSRS(snrIdx) + sum(uci);
        end
    else % false alarm test
        % False ACK.
        if msg.isValid
            stats.falseACKSRS(snrIdx) = stats.falseACKSRS(snrIdx) + sum(uciRxSRS);
        end
        stats.nNACKsSRS(snrIdx) = stats.nNACKsSRS(snrIdx) + length(uciRxSRS);
    end
end

function stats = updateStatsSRSF2(stats, uci, msg, isDetectTest, snrIdx)
    if isDetectTest
        decucibitssrs = [msg.HARQAckPayload; msg.SRPayload; msg.CSI1Payload; msg.CSI2Payload];
        stats.blerUCIsrs(snrIdx) = stats.blerUCIsrs(snrIdx) + (~(isequal(decucibitssrs, uci)));
    else % false alarm test
        stats.blerUCIsrs(snrIdx) = stats.blerUCIsrs(snrIdx) + msg.isValid;
    end
end

function printMessagesF1(stats, usedFrames, ~, SNRIn, isDetectTest, snrIdx)
    if isDetectTest
        fprintf(['PUCCH Format 1 - NACK to ACK rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACK(snrIdx)/stats.nNACKs(snrIdx));
        fprintf(['PUCCH Format 1 - ACK missed detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.missedACK(snrIdx)/stats.nACKs(snrIdx));
    else
        fprintf(['PUCCH Format 1 - false ACK detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACK(snrIdx)/stats.nNACKs(snrIdx));
    end
end

function printMessagesF2(stats, usedFrames, totalBlocks, SNRIn, isDetectTest, snrIdx)
    if isDetectTest
        message = 'UCI BLER of PUCCH Format 2';
    else
        message = 'UCI false detection rate of PUCCH Format 2';
    end

    fprintf([message ' for ' num2str(usedFrames) ...
        ' frame(s) at SNR ' num2str(SNRIn(snrIdx)) ' dB: ' num2str(stats.blerUCI(snrIdx)/totalBlocks(snrIdx)) '\n'])
end

function printMessagesSRSF1(stats, usedFrames, ~, SNRIn, isDetectTest, snrIdx)
    if isDetectTest
        fprintf(['SRS - PUCCH Format 1 - NACK to ACK rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACKSRS(snrIdx)/stats.nNACKs(snrIdx));
        fprintf(['SRS - PUCCH Format 1 - ACK missed detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.missedACKSRS(snrIdx)/stats.nACKs(snrIdx));
    else
        fprintf(['SRS - PUCCH Format 1 - false ACK detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACKSRS(snrIdx)/stats.nNACKs(snrIdx));
    end
end

function printMessagesSRSF2(stats, usedFrames, totalBlocks, SNRIn, isDetectTest, snrIdx)
    if isDetectTest
        message = 'UCI BLER of PUCCH Format 2';
    else
        message = 'UCI false detection rate of PUCCH Format 2';
    end

    fprintf('SRS - ');
    fprintf([message ' for ' num2str(usedFrames) ...
        ' frame(s) at SNR ' num2str(SNRIn(snrIdx)) ' dB: ' num2str(stats.blerUCIsrs(snrIdx)/totalBlocks(snrIdx)) '\n'])
end

