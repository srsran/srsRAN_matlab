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
        obj.FormatDetails = FormatDetailsF0(obj.NumACKBits, obj.NumSRBits, obj.isDetectionTest());
    elseif (obj.PUCCHFormat == 1)
        obj.PUCCH = nrPUCCH1Config;
        obj.PUCCH.GroupHopping = "neither";
        obj.PUCCH.HoppingID = 0;
        obj.PUCCH.InitialCyclicShift = 0;
        obj.PUCCH.OCCI = 0;
        obj.FormatDetails = FormatDetailsF1(obj.NumACKBits, obj.NumSRBits, obj.isDetectionTest());
    elseif (obj.PUCCHFormat == 2)
        obj.PUCCH = nrPUCCH2Config;
        obj.PUCCH.NID0 = 0;
        obj.PUCCH.NID = [];
        obj.PUCCH.RNTI = obj.RNTI;
        obj.FormatDetails = FormatDetailsF2(obj.NumACKBits, obj.NumSRBits, obj.NumCSI1Bits, obj.NumCSI2Bits, obj.isDetectionTest());
    else % if PUCCH Format3
        obj.PUCCH = nrPUCCH3Config;
        obj.PUCCH.Modulation = obj.Modulation;
        obj.PUCCH.GroupHopping = "neither";
        obj.PUCCH.HoppingID = 0;
        obj.PUCCH.AdditionalDMRS = 0;
        obj.PUCCH.NID = [];
        obj.PUCCH.RNTI = obj.RNTI;
        % BLER tests work the same as detection tests.
        obj.TestType = 'Detection';
        obj.FormatDetails = FormatDetailsF3(obj.NumACKBits, obj.NumSRBits, obj.NumCSI1Bits, obj.NumCSI2Bits);
    end
    obj.PUCCH.PRBSet = obj.PRBSet;
    obj.PUCCH.SymbolAllocation = obj.SymbolAllocation;
    obj.PUCCH.FrequencyHopping = obj.FrequencyHopping;
    if ~strcmp(obj.FrequencyHopping, 'neither')
        obj.PUCCH.SecondHopStartPRB = (obj.NSizeGrid-1) - (numel(obj.PRBSet)-1);
    end

    obj.checkPUCCHandSymbolAllocation();
    obj.checkPUCCHandPRBs();
    obj.checkUCIBits();

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

