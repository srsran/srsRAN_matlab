%setupImpl System object setup method implementation.

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

function setupImpl(obj)
    % Set carrier resource grid properties.
    obj.Carrier = nrCarrierConfig;
    obj.Carrier.NCellID = obj.NCellID;
    obj.Carrier.SubcarrierSpacing = obj.SubcarrierSpacing;
    obj.Carrier.CyclicPrefix = "normal";

    obj.Carrier.NSizeGrid = obj.NSizeGrid;
    obj.Carrier.NStartGrid = 0;

    % Set PUCCH properties.
    if (obj.PUCCHFormat == 0)
        obj.PUCCH = nrPUCCH0Config;
        obj.PUCCH.GroupHopping = "neither";
        obj.PUCCH.HoppingID = 0;
        obj.PUCCH.InitialCyclicShift = 0;
    elseif (obj.PUCCHFormat == 1)
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
    if (obj.PUCCHFormat == 0)
        obj.updateStats = @updateStatsF0;
        obj.updateStatsSRS = @updateStatsSRSF0;
        obj.printMessages = @printMessagesF0;
        obj.printMessagesSRS = @printMessagesSRSF0;
    elseif (obj.PUCCHFormat == 1)
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
function stats = updateStatsF0(stats, uci, uciRx, ouci, isDetectTest, snrIdx)
    if isDetectTest
        % If MATLAB's PUCCH decoder was able to detect a PUCCH and
        % uciRx contains the resulting bits.
        if ~isempty(uciRx{1})
            % Erroneous ACK.
            stats.errorACK(snrIdx) = stats.errorACK(snrIdx) + sum(uci{1} ~= uciRx{1});
        else
            stats.errorACK(snrIdx) = stats.errorACK(snrIdx) + ouci(1);
        end
        if ~isempty(uciRx{2})
            % Erroneous SR.
            stats.errorSR(snrIdx) = stats.errorSR(snrIdx) + (uci{2} ~= uciRx{2});
        else
            stats.errorSR(snrIdx) = stats.errorSR(snrIdx) + ouci(2);
        end
    else % false alarm test
        % False ACK.
        if (ouci(1) > 0)
            stats.falseACK(snrIdx) = stats.falseACK(snrIdx) + numel(uciRx{1});
        end
        if (ouci(2) > 0)
            stats.falseSR(snrIdx) = stats.falseSR(snrIdx) + numel(uciRx{2});
        end
    end % if isDetectTest
end

function stats = updateStatsF1(stats, uci, uciRx, ~, isDetectTest, snrIdx)
    if isDetectTest
        % If MATLAB's PUCCH decoder was able to detect a PUCCH and
        % uciRx contains the resulting bits.
        if ~isempty(uciRx{1})
            % NACK to ACK.
            stats.falseACK(snrIdx) = stats.falseACK(snrIdx) + sum(~uci & uciRx{1});
            % Missed ACK.
            stats.missedACK(snrIdx) = stats.missedACK(snrIdx) + sum(uci & ~uciRx{1});
        else
            % Missed ACK. Here, uciRx is empty (MATLAB's PUCCH decoder failed
            % to detect) and all ACKs are lost.
            stats.missedACK(snrIdx) = stats.missedACK(snrIdx) + sum(uci);
        end
    else % false alarm test
        % False ACK.
        stats.falseACK(snrIdx) = stats.falseACK(snrIdx) + sum(uciRx{1});
    end % if isDetectTest
end

function stats = updateStatsF2(stats, uci, uciRx, ouci, isDetectTest, snrIdx)
    if isDetectTest
        % Decode UCI.
        decucibits = nrUCIDecode(uciRx{1}, ouci);

        % Store values to calculate BLER.
        stats.blerUCI(snrIdx) = stats.blerUCI(snrIdx) + (~isequal(decucibits, uci));
    else % false alarm test
        stats.blerUCI(snrIdx) = stats.blerUCI(snrIdx) + (~isempty(uciRx{1}));
    end % if isDetectTest
end

function stats = updateStatsSRSF0(stats, uci, msg, isDetectTest, snrIdx)
    ackRxSRS = msg.HARQAckPayload;
    srRxSRS = msg.SRPayload;
    if isDetectTest
        % If SRS's PUCCH decoder was able to detect a PUCCH.
        if msg.isValid
            % ACK errors.
            stats.errorACKSRS(snrIdx) = stats.errorACKSRS(snrIdx) + sum(uci{1} ~= ackRxSRS);
            stats.errorSRSRS(snrIdx) = stats.errorSRSRS(snrIdx) + sum(uci{2} ~= srRxSRS);
        else
            % No ACK or SR bit has been recovered.
            stats.errorACKSRS(snrIdx) = stats.errorACKSRS(snrIdx) + numel(uci{1});
            stats.errorSRSRS(snrIdx) = stats.errorSRSRS(snrIdx) + numel(uci{2});
        end
    else % false alarm test
        % False ACK.
        if msg.isValid
            if ~isempty(uci{1})
                stats.falseACKSRS(snrIdx) = stats.falseACKSRS(snrIdx) + numel(uci{1});
            end
            if ~isempty(uci{2})
                stats.falseSRSRS(snrIdx) = stats.falseSRSRS(snrIdx) + numel(uci{2});
            end
        end
    end
end

function stats = updateStatsSRSF1(stats, uci, msg, isDetectTest, snrIdx)
    uciRxSRS = msg.HARQAckPayload;
    if isDetectTest
        % If SRS's PUCCH decoder was able to detect a PUCCH.
        if msg.isValid
            % NACK to ACK.
            stats.falseACKSRS(snrIdx) = stats.falseACKSRS(snrIdx) + sum(~uci & uciRxSRS);
            % Missed ACK.
            stats.missedACKSRS(snrIdx) = stats.missedACKSRS(snrIdx) + sum(uci & ~uciRxSRS);
        else
            % Missed ACK. Here, SRS's PUCCH decoder failed
            % to detect and all ACKs are lost.
            stats.missedACKSRS(snrIdx) = stats.missedACKSRS(snrIdx) + sum(uci);
        end
    else % false alarm test
        % False ACK.
        if msg.isValid
            stats.falseACKSRS(snrIdx) = stats.falseACKSRS(snrIdx) + sum(uciRxSRS);
        end
    end
end

function stats = updateStatsSRSF2(stats, uci, msg, isDetectTest, snrIdx)
    if isDetectTest
        decucibitssrs = [msg.HARQAckPayload; msg.SRPayload; msg.CSI1Payload; msg.CSI2Payload];
        stats.blerUCISRS(snrIdx) = stats.blerUCISRS(snrIdx) + (~(isequal(decucibitssrs, uci)));
    else % false alarm test
        stats.blerUCISRS(snrIdx) = stats.blerUCISRS(snrIdx) + msg.isValid;
    end
end

function printMessagesF0(stats, usedFrames, nSRs, SNRIn, isDetectTest, snrIdx)
    if isDetectTest
        fprintf(['PUCCH Format 0 - ACK error rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.errorACK(snrIdx)/stats.nACKs(snrIdx));
        fprintf(['PUCCH Format 0 - SR error rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.errorSR(snrIdx)/nSRs(snrIdx));
    else
        fprintf(['PUCCH Format 0 - false ACK detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACK(snrIdx)/stats.nACKs(snrIdx));
        fprintf(['PUCCH Format 0 - false SR detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseSR(snrIdx)/stats.nSRs(snrIdx));
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

function printMessagesSRSF0(stats, usedFrames, nSRs, SNRIn, isDetectTest, snrIdx)
    if isDetectTest
        fprintf(['SRS - PUCCH Format 0 - ACK error rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.errorACKSRS(snrIdx)/stats.nACKs(snrIdx));
        fprintf(['SRS - PUCCH Format 0 - SR error rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.errorSRSRS(snrIdx)/nSRs(snrIdx));
    else
        fprintf(['SRS - PUCCH Format 0 - false ACK detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACKSRS(snrIdx)/stats.nACKs(snrIdx));
        fprintf(['SRS - PUCCH Format 0 - false SR detection rate for %d frame(s) at ', ...
            'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseSRSRS(snrIdx)/stats.nSRs(snrIdx));
    end
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
        ' frame(s) at SNR ' num2str(SNRIn(snrIdx)) ' dB: ' num2str(stats.blerUCISRS(snrIdx)/totalBlocks(snrIdx)) '\n'])
end

