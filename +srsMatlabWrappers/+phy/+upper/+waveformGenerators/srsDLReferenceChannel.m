%SRSDLREFERENCECHANNEL Generates Downlink Reference channels.
%
%    [DESCRIPTION, CFGDL, INFO] = srsDLReferenceChannel(REFERENCECHANNEL) 
%       Generates a downlink regference signal where the parameter 
%       REFERENCECHANNEL is a string that identifies one of the following 
%       test reference channels:
%        R.PDSCH.1-1.1: Reference channel described in TS38.101-4 Table
%            5.2.3.1.1-3 test 1-1 for testing FDD PDSCH QPSK modulation with
%            target rate of 0.3, mapping Type A and allocated in the full
%            band.
%        R.PDSCH.1-1.2: Reference channel described in TS38.101-4 Table
%            5.2.3.1.1-3 test 1-2 for testing FDD PDSCH QPSK modulation with 
%            target rate of 0.3, mapping Type A and allocated in the center 6
%            RB.
%        R.PDSCH.1-4.1: Reference channel described in TS38.101-4 Table
%            5.2.3.1.1-3 test 1-3 for testing FDD PDSCH 256QAM modulation with
%            target rate of 0.82, mapping Type A and allocated in the full
%            band.
%        R.PDSCH.1-2.1: Reference channel described in TS38.101-4 Table
%            5.2.3.1.1-3 test 1-4 for testing FDD PDSCH 16QAM modulation with
%            target rate of 0.48, mapping Type A and allocated in the full
%            band.
%        R.PDSCH.1-8.1: Reference channel described in TS38.101-4 Table
%            5.2.3.1.1-3 test 1-5 for testing FDD PDSCH 16QAM modulation with
%            target rate of 0.48, mapping Type A and allocated in the full
%            band. Optimized for HST scenario.
%   
%   The function returns:
%       DESCRIPTION - structure that provides details of the reference channel
%       CFGDL       - object of type <a href="matlab: help('nrDLCarrierConfig')">nrDLCarrierConfig</a>
%       INFO        - structure with the generated waveform information

function [description, cfgDL, info] = srsDLReferenceChannel(referenceChannel)
description = struct();
switch referenceChannel
    case 'R.PDSCH.1-1.1'
        description.bandwidth = 10;
        description.subcarrierSpacing = 15;
        description.modulation = 'QPSK';
        description.targetCodeRate = 0.3;
        description.summary = ['Reference channel described in ' ...
            'TS38.101-4 Table 5.2.3.1.1-3 test 1-1 for testing FDD '...
            'PDSCH QPSK modulation with target rate of 0.3, mapping '...
            'Type A and allocated in the full band.'];
        description.duplexMode = 'FDD';
    case 'R.PDSCH.1-1.2'
        description.bandwidth = 10;
        description.subcarrierSpacing = 15;
        description.modulation = 'QPSK';
        description.targetCodeRate = 0.3;
        description.summary = ['Reference channel described in ' ...
            'TS38.101-4 Table 5.2.3.1.1-3 test 1-2 for testing PDSCH ' ...
            'QPSK modulation with target rate of 0.3, mapping Type A ' ...
            'and allocated in the center 6 RB.'];
        description.duplexMode = 'FDD';
    case 'R.PDSCH.1-4.1'
        description.bandwidth = 10;
        description.subcarrierSpacing = 15;
        description.modulation = '256QAM';
        description.targetCodeRate = 0.82;
        description.summary = ['Reference channel described in ' ...
            'TS38.101-4 Table 5.2.3.1.1-3 test 1-3 for testing PDSCH ' ...
            '256QAM modulation with target rate of 0.82, mapping Type A ' ...
            'and allocated in the full band.'];
        description.duplexMode = 'FDD';
    case 'R.PDSCH.1-2.1'
        description.bandwidth = 10;
        description.subcarrierSpacing = 15;
        description.modulation = '16QAM';
        description.targetCodeRate = 0.48;
        description.summary = ['Reference channel described in ' ...
            'TS38.101-4 Table 5.2.3.1.1-3 test 1-4 for testing PDSCH ' ...
            '16QAM modulation with target rate of 0.48, mapping Type A ' ...
            'and allocated in the full band.'];
        description.duplexMode = 'FDD';
    case 'R.PDSCH.1-8.1'
        description.bandwidth = 10;
        description.subcarrierSpacing = 15;
        description.modulation = '16QAM';
        description.targetCodeRate = 0.48;
        description.summary = ['Reference channel described in ' ...
            'TS38.101-4 Table 5.2.3.1.1-3 test 1-5 for testing PDSCH ' ...
            '16QAM modulation with target rate of 0.48, mapping Type A ' ...
            'and allocated in the full band. Optimized for HST scenario.'];
        description.duplexMode = 'FDD';
    otherwise
        error(['Reference channel ' referenceChannel ' is not valid.']);
end

NStartGrid = 0;
switch description.bandwidth
    case 10
        NSizeGrid = 52;
end

% Downlink configuration
cfgDL = nrDLCarrierConfig;
cfgDL.Label = 'Carrier1';
cfgDL.FrequencyRange = 'FR1';
cfgDL.ChannelBandwidth = description.bandwidth;
cfgDL.NCellID = 0;
cfgDL.NumSubframes = 20;
cfgDL.WindowingPercent = 0;
cfgDL.SampleRate = [];
cfgDL.CarrierFrequency = 3500000000;

%% SCS specific carriers
scscarrier = nrSCSCarrierConfig;
scscarrier.SubcarrierSpacing = description.subcarrierSpacing;
scscarrier.NSizeGrid = NSizeGrid;
scscarrier.NStartGrid = NStartGrid;

cfgDL.SCSCarriers = {scscarrier};

%% Bandwidth Parts
bwp = nrWavegenBWPConfig;
bwp.BandwidthPartID = 1;
bwp.Label = 'BWP1';
bwp.SubcarrierSpacing = description.subcarrierSpacing;
bwp.CyclicPrefix = 'normal';
bwp.NSizeBWP = NSizeGrid;
bwp.NStartBWP = NStartGrid;

cfgDL.BandwidthParts = {bwp};

%% Synchronization Signals Burst
ssburst = nrWavegenSSBurstConfig;
ssburst.BlockPattern = 'Case A';
ssburst.TransmittedBlocks = [1 0 0 0];
ssburst.Period = 20;
ssburst.NCRBSSB = [];
ssburst.KSSB = 0;
ssburst.DataSource = 'MIB';
ssburst.DMRSTypeAPosition = 2;
ssburst.CellBarred = false;
ssburst.IntraFreqReselection = false;
ssburst.PDCCHConfigSIB1 = 0;
ssburst.SubcarrierSpacingCommon = 15;
ssburst.Enable = true;
ssburst.Power = 0;

cfgDL.SSBurst = ssburst;

%% CORESET and Search Space Configuration
coreset = nrCORESETConfig;
coreset.CORESETID = 1;
coreset.Label = 'CORESET1';
coreset.FrequencyResources = ones([1 floor(NSizeGrid / 6)]);
coreset.Duration = 2;
coreset.CCEREGMapping = 'noninterleaved';
coreset.REGBundleSize = 6;
coreset.InterleaverSize = 2;
coreset.ShiftIndex = 0;

cfgDL.CORESET = {coreset};

% Search Spaces
searchspace = nrSearchSpaceConfig;
searchspace.SearchSpaceID = 1;
searchspace.Label = 'SearchSpace1';
searchspace.CORESETID = 1;
searchspace.SearchSpaceType = 'ue';
searchspace.StartSymbolWithinSlot = 0;
searchspace.SlotPeriodAndOffset = [1 0];
searchspace.Duration = 1;
searchspace.NumCandidates = [1 1 1 1 1];

cfgDL.SearchSpaces = {searchspace};

%% PDCCH Instances Configuration
pdcch = nrWavegenPDCCHConfig;
pdcch.Enable = true;
pdcch.Label = 'PDCCH1';
pdcch.Power = 0;
pdcch.BandwidthPartID = 1;
pdcch.SearchSpaceID = 1;
pdcch.AggregationLevel = 8;
pdcch.AllocatedCandidate = 1;
pdcch.CCEOffset = [];
pdcch.SlotAllocation = 0;
pdcch.Period = 1;
pdcch.Coding = true;
pdcch.DataBlockSize = 20;
pdcch.DataSource = 'PN9-ITU';
pdcch.RNTI = 1;
pdcch.DMRSScramblingID = 2;
pdcch.DMRSPower = 0;

cfgDL.PDCCH = {pdcch};

%% PDSCH Instances Configuration
pdsch = nrWavegenPDSCHConfig;
pdsch.Enable = true;
pdsch.Label = 'PDSCH1';
pdsch.Power = 0;
pdsch.BandwidthPartID = 1;
pdsch.Modulation = 'QPSK';
pdsch.NumLayers = 1;
pdsch.MappingType = 'A';
pdsch.ReservedCORESET = [];
pdsch.SymbolAllocation = [2 12];
pdsch.SlotAllocation = 0:9;
pdsch.Period = 10;
switch referenceChannel
    case 'R.PDSCH.1-1.2'
        pdsch.PRBSet = 23 + (0:5);
    otherwise
        pdsch.PRBSet = 0:(NSizeGrid-1);
end
pdsch.VRBToPRBInterleaving = false;
pdsch.VRBBundleSize = 2;
pdsch.NID = 1;
pdsch.RNTI = 1;
pdsch.Coding = true;
pdsch.TargetCodeRate = 0.3;
pdsch.TBScaling = 1;
pdsch.XOverhead = 0;
pdsch.RVSequence = 0;
pdsch.DataSource = 'PN9-ITU';
pdsch.DMRSPower = 0;
pdsch.EnablePTRS = false;
pdsch.PTRSPower = 0;

% PDSCH Reserved PRB
pdschReservedPRB = nrPDSCHReservedConfig;
pdschReservedPRB.PRBSet = [];
pdschReservedPRB.SymbolSet = [];
pdschReservedPRB.Period = [];

pdsch.ReservedPRB = {pdschReservedPRB};

% PDSCH DM-RS
pdschDMRS = nrPDSCHDMRSConfig;
pdschDMRS.DMRSConfigurationType = 1;
pdschDMRS.DMRSReferencePoint = 'CRB0';
pdschDMRS.DMRSTypeAPosition = 2;
switch referenceChannel
    case 'R.PDSCH.1-1.1'
        pdschDMRS.DMRSAdditionalPosition = 2;
    case 'R.PDSCH.1-8.1'
        pdschDMRS.DMRSAdditionalPosition = 2;
    otherwise
        pdschDMRS.DMRSAdditionalPosition = 1;
end
pdschDMRS.DMRSLength = 1;
pdschDMRS.CustomSymbolSet = [];
pdschDMRS.DMRSPortSet = [];
pdschDMRS.NIDNSCID = [];
pdschDMRS.NSCID = 0;
pdschDMRS.NumCDMGroupsWithoutData = 1;
pdschDMRS.DMRSDownlinkR16 = 0;

pdsch.DMRS = pdschDMRS;

% PDSCH PT-RS
pdschPTRS = nrPDSCHPTRSConfig;
pdschPTRS.TimeDensity = 1;
pdschPTRS.FrequencyDensity = 2;
pdschPTRS.REOffset = '00';
pdschPTRS.PTRSPortSet = [];

pdsch.PTRS = pdschPTRS;

cfgDL.PDSCH = {pdsch};

%% CSI-RS Instances Configuration
% CSI-RS 1
csirs1 = nrWavegenCSIRSConfig;
csirs1.Enable = true;
csirs1.Label = 'CSIRSTRS1';
csirs1.Power = 0;
csirs1.BandwidthPartID = 1;
csirs1.CSIRSType = 'nzp';
switch referenceChannel
    case 'R.PDSCH.1-8.1'
        csirs1.CSIRSPeriod = [10 1];
    otherwise
        csirs1.CSIRSPeriod = [20 10];
end
csirs1.RowNumber = 1;
csirs1.Density = 'three';
csirs1.SymbolLocations = 6;
csirs1.SubcarrierLocations = 0;
csirs1.NumRB = NSizeGrid;
csirs1.RBOffset = 0;
csirs1.NID = 0;

% CSI-RS 2
csirs2 = nrWavegenCSIRSConfig;
csirs2.Enable = true;
csirs2.Label = 'CSIRSTRS2';
csirs2.Power = 0;
csirs2.BandwidthPartID = 1;
csirs2.CSIRSType = 'nzp';
csirs2.CSIRSPeriod = csirs1.CSIRSPeriod;
csirs2.RowNumber = 1;
csirs2.Density = 'three';
csirs2.SymbolLocations = 10;
csirs2.SubcarrierLocations = 0;
csirs2.NumRB = NSizeGrid;
csirs2.RBOffset = 0;
csirs2.NID = 0;

% CSI-RS 3
csirs3 = nrWavegenCSIRSConfig;
csirs3.Enable = true;
csirs3.Label = 'CSIRSTRS3';
csirs3.Power = 0;
csirs3.BandwidthPartID = 1;
csirs3.CSIRSType = 'nzp';
switch referenceChannel
    case 'R.PDSCH.1-8.1'
        csirs3.CSIRSPeriod = [10 2];
    otherwise
        csirs3.CSIRSPeriod = [20 11];
end
csirs3.RowNumber = 1;
csirs3.Density = 'three';
csirs3.SymbolLocations = 6;
csirs3.SubcarrierLocations = 0;
csirs3.NumRB = NSizeGrid;
csirs3.RBOffset = 0;
csirs3.NID = 0;

% CSI-RS 4
csirs4 = nrWavegenCSIRSConfig;
csirs4.Enable = true;
csirs4.Label = 'CSIRSTRS4';
csirs4.Power = 0;
csirs4.BandwidthPartID = 1;
csirs4.CSIRSType = 'nzp';
csirs4.CSIRSPeriod = csirs3.CSIRSPeriod;
csirs4.RowNumber = 1;
csirs4.Density = 'three';
csirs4.SymbolLocations = 10;
csirs4.SubcarrierLocations = 0;
csirs4.NumRB = NSizeGrid;
csirs4.RBOffset = 0;
csirs4.NID = 0;

% CSI-RS 5
csirs5 = nrWavegenCSIRSConfig;
csirs5.Enable = true;
csirs5.Label = 'NZPCSIRS';
csirs5.Power = 0;
csirs5.BandwidthPartID = 1;
csirs5.CSIRSType = 'nzp';
csirs5.CSIRSPeriod = [20 0];
csirs5.RowNumber = 2;
csirs5.Density = 'one';
csirs5.SymbolLocations = 12;
csirs5.SubcarrierLocations = 0;
csirs5.NumRB = NSizeGrid;
csirs5.RBOffset = 0;
csirs5.NID = 0;

% CSI-RS 6
csirs6 = nrWavegenCSIRSConfig;
csirs6.Enable = true;
csirs6.Label = 'ZPCSIRS';
csirs6.Power = 0;
csirs6.BandwidthPartID = 1;
csirs6.CSIRSType = 'zp';
csirs6.CSIRSPeriod = [20 0];
csirs6.RowNumber = 4;
csirs6.Density = 'one';
csirs6.SymbolLocations = 12;
csirs6.SubcarrierLocations = 4;
csirs6.NumRB = NSizeGrid;
csirs6.RBOffset = 0;
csirs6.NID = 0;

cfgDL.CSIRS = {csirs1,csirs2,csirs3,csirs4,csirs5,csirs6};

% Generation
[~, info] = nrWaveformGenerator(cfgDL);

for pdschIndex = 1:length(info.WaveformResources.PDSCH.Resources)
    slotIndex = info.WaveformResources.PDSCH.Resources(pdschIndex).NSlot;
    csiResources = [];
    csiConfigurations = cfgDL.CSIRS;
    for csiConfigurationIndex=1:length(csiConfigurations)
        csiSlotPeriod = csiConfigurations{csiConfigurationIndex}.CSIRSPeriod(1);
        csiSlotOffset = csiConfigurations{csiConfigurationIndex}.CSIRSPeriod(2);
        if rem(slotIndex, csiSlotPeriod) == csiSlotOffset
            csiResources = [csiResources, csiConfigurationIndex]; %#ok<AGROW>
        end
    end
    info.WaveformResources.PDSCH.Resources(pdschIndex).CSIRSResources = csiResources;
end

