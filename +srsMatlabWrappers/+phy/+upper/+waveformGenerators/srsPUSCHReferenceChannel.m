%srsPUSCHReferenceChannel Generates Physical uplink shared reference channels.
%   [DESCRIPTION, CFGULFRC, INFO] = srsPUSCHReferenceChannel(FIXEDREFERENCECHANNEL, CHANNELBANDWIDTH) 
%   Generates an uplink reference signal where the parameter
%   FIXEDREFERENCECHANNEL is a string that identifies fixed reference
%   channels described in TS38.104 Annex A, and CHANNELBANDWIDTH is the
%   total channel bandwidth in MHz.
%   
%   The function returns:
%       DESCRIPTION - structure that provides details of the reference channel
%       CFGULFRC    - object of type <a href="matlab: help('nrULCarrierConfig')">nrULCarrierConfig</a>
%       INFO        - structure with the generated waveform information
function [description, cfgULFRC, info] = srsPUSCHReferenceChannel(fixedReferenceChannel, channelBandwidth)

description = struct();
description.bandWidthMHz = channelBandwidth;
switch fixedReferenceChannel
    case 'G-FR1-A3-8'
        description.subcarrierSpacing = 15;
        description.modulation = 'QPSK';
        description.targetCodeRate = 0.1884765625;
        description.frequencyRange = 'FR1';
    otherwise
        error(['Reference channel ' fixedReferenceChannel ' is not valid.']);
end

NStartGrid = 0;
switch description.bandWidthMHz
    case 5
        NSizeGrid = 25;
    case 10
        NSizeGrid = 52;
end

%% Generating Uplink FRC waveform
% Uplink FRC configuration
cfgULFRC = nrULCarrierConfig;
cfgULFRC.Label = fixedReferenceChannel;
cfgULFRC.FrequencyRange = description.frequencyRange;
cfgULFRC.ChannelBandwidth = channelBandwidth;
cfgULFRC.NCellID = 1;
cfgULFRC.NumSubframes = 10;
cfgULFRC.WindowingPercent = 0;
cfgULFRC.SampleRate = [];
cfgULFRC.CarrierFrequency = 0;

%% SCS specific carriers
scscarrier = nrSCSCarrierConfig;
scscarrier.SubcarrierSpacing = description.subcarrierSpacing;
scscarrier.NSizeGrid = NSizeGrid;
scscarrier.NStartGrid = NStartGrid;

cfgULFRC.SCSCarriers = {scscarrier};

%% Bandwidth Parts
bwp = nrWavegenBWPConfig;
bwp.BandwidthPartID = 1;
bwp.Label = 'BWP1';
bwp.SubcarrierSpacing = 15;
bwp.CyclicPrefix = 'normal';
bwp.NSizeBWP = NSizeGrid;
bwp.NStartBWP = 0;

cfgULFRC.BandwidthParts = {bwp};

%% PUSCH Instances Configuration
pusch = nrWavegenPUSCHConfig;
pusch.Enable = true;
pusch.Label = ['PUSCH sequence for ', fixedReferenceChannel];
pusch.Power = 0;
pusch.BandwidthPartID = 1;
pusch.Modulation = description.modulation;
pusch.NumLayers = 1;
pusch.MappingType = 'A';
pusch.SymbolAllocation = [0 14];
pusch.SlotAllocation = 0:9;
pusch.Period = 10;
pusch.PRBSet = 0:24;
pusch.TransformPrecoding = false;
pusch.TransmissionScheme = 'codebook';
pusch.NumAntennaPorts = 1;
pusch.TPMI = 0;
pusch.FrequencyHopping = 'neither';
pusch.SecondHopStartPRB = 0;
pusch.NID = 0;
pusch.RNTI = 1;
pusch.NRAPID = [];
pusch.Coding = true;
pusch.TargetCodeRate = description.targetCodeRate;
pusch.XOverhead = 0;
pusch.RVSequence = 0;
pusch.DataSource = 'PN9';
pusch.EnableACK = false;
pusch.NumACKBits = 10;
pusch.BetaOffsetACK = 20;
pusch.DataSourceACK = 'PN9-ITU';
pusch.EnableCSI1 = false;
pusch.NumCSI1Bits = 10;
pusch.BetaOffsetCSI1 = 6.25;
pusch.DataSourceCSI1 = 'PN9-ITU';
pusch.EnableCSI2 = false;
pusch.NumCSI2Bits = 10;
pusch.BetaOffsetCSI2 = 6.25;
pusch.DataSourceCSI2 = 'PN9-ITU';
pusch.EnableCGUCI = false;
pusch.NumCGUCIBits = 7;
pusch.BetaOffsetCGUCI = 20;
pusch.DataSourceCGUCI = 'PN9-ITU';
pusch.EnableULSCH = true;
pusch.UCIScaling = 1;
pusch.DMRSPower = 3;
pusch.EnablePTRS = false;
pusch.PTRSPower = 0;

% PUSCH DM-RS
puschDMRS = nrPUSCHDMRSConfig;
puschDMRS.DMRSConfigurationType = 1;
puschDMRS.DMRSTypeAPosition = 2;
puschDMRS.DMRSAdditionalPosition = 1;
puschDMRS.DMRSLength = 1;
puschDMRS.CustomSymbolSet = [];
puschDMRS.DMRSPortSet = 0;
puschDMRS.NIDNSCID = 0;
puschDMRS.NSCID = 0;
puschDMRS.GroupHopping = 0;
puschDMRS.SequenceHopping = 0;
puschDMRS.NRSID = [];
puschDMRS.NumCDMGroupsWithoutData = 2;
puschDMRS.DMRSUplinkR16 = 0;
puschDMRS.DMRSUplinkTransformPrecodingR16 = 0;

pusch.DMRS = puschDMRS;

% PUSCH PT-RS
puschPTRS = nrPUSCHPTRSConfig;
puschPTRS.TimeDensity = 1;
puschPTRS.FrequencyDensity = 2;
puschPTRS.NumPTRSSamples = 2;
puschPTRS.NumPTRSGroups = 2;
puschPTRS.REOffset = '00';
puschPTRS.PTRSPortSet = 0;
puschPTRS.NID = [];

pusch.PTRS = puschPTRS;

cfgULFRC.PUSCH = {pusch};

%% PUCCH Instances Configuration
pucch = nrWavegenPUCCH0Config;
pucch.Enable = false;
pucch.Label = 'PUCCH format 0';
pucch.Power = 0;
pucch.BandwidthPartID = 1;
pucch.SymbolAllocation = [13 1];
pucch.SlotAllocation = 0:9;
pucch.Period = 10;
pucch.PRBSet = 0;
pucch.FrequencyHopping = 'neither';
pucch.SecondHopStartPRB = 1;
pucch.GroupHopping = 'neither';
pucch.HoppingID = [];
pucch.InitialCyclicShift = 0;
pucch.NumUCIBits = 1;
pucch.DataSourceUCI = 'PN9-ITU';
pucch.DataSourceSR = 0;

cfgULFRC.PUCCH = {pucch};

%% SRS Instances Configuration
srs = nrWavegenSRSConfig;
srs.Enable = false;
srs.Label = 'SRS1';
srs.Power = 0;
srs.BandwidthPartID = 1;
srs.NumSRSPorts = 1;
srs.NumSRSSymbols = 1;
srs.SymbolStart = 13;
srs.SlotAllocation = 0:9;
srs.Period = 10;
srs.KTC = 2;
srs.KBarTC = 0;
srs.CyclicShift = 0;
srs.FrequencyStart = 0;
srs.NRRC = 0;
srs.CSRS = 0;
srs.BSRS = 0;
srs.BHop = 0;
srs.Repetition = 1;
srs.GroupSeqHopping = 'neither';
srs.NSRSID = 0;
srs.SRSPositioning = false;

cfgULFRC.SRS = {srs};

% Generation
[waveform,info] = nrWaveformGenerator(cfgULFRC);

end

