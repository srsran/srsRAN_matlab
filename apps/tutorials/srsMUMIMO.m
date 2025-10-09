%% Multi-user MIMO
% This script is a first approach towards the implementation of Multi-User
% Multiple-Input Multiple-Output (MU-MIMO) in srsRAN. Specifically, the following
% PUSCH-based toy example shows that MU-MIMO is, under most aspects, equivalent
% to a multi-layered transmission. Similar conclusions can be drawn for the
% PDSCH case.
%
% *Warning:* The real challenge in MU-MIMO is the procedure that allows grouping
% together UEs to be allocated on the same resources. This decision is probably
% a responsibility of the MAC with the support of metrics collected by the PHY,
% most likely to be based on Sounding Reference Signal (SRS) measurements. It
% is not included in this preliminary analysis.

%% MU-MIMO in the PUSCH
% A simple example of MU-MIMO PUSCH transmission can be constructed as follows.
% Let us assume that the gNB intends to serve two UEs on the same time-frequency
% resources. Note that complete overlap of the grants, as well as identical DM-RS
% configurations (but for the DM-RS ports), are necessary to guarantee that
% the DM-RSs of the two UEs do not interfere with one another nor with the other
% UE's data signal.

% First, we need to configure the carrier - we pick a 10-MHz bandwidth with
% 30-kHz subcarrier spacing.
carrier = nrCarrierConfig;
carrier.SubcarrierSpacing = 30;
carrier.NSizeGrid = 25;

% Configure PUSCH of UE1.
pusch1 = nrPUSCHConfig;
pusch1.PRBSet = 0:(carrier.NSizeGrid - 1);
pusch1.TransmissionScheme = 'Codebook';
pusch1.NumAntennaPorts = 2;
pusch1.NumLayers = 2;
pusch1.Modulation = '16QAM';
% Configure the DM-RS: Configuration Type 1, single symbol.
pusch1.DMRS.DMRSConfigurationType = 1;
pusch1.DMRS.DMRSLength = 1;
% Same PUSCH configuration for UE2.
pusch2 = pusch1;

%%
% For the gNB to be able to separate the two transmissions, it is
% important that the Transmitted Precoding Matrix Indicator (TPMI) and the DM-RS
% antenna ports of the two transmissions are set so that they do no not interfere
% with one another or, at least, so that the interference is minimized.
pusch1.TPMI = 0;
pusch1.DMRS.DMRSPortSet = [0, 1];

pusch2.TPMI = 1;
pusch2.DMRS.DMRSPortSet = [2, 3];

%%
% Now generate the PUSCH transmissions for the two UEs.

% Fix the target code rate. For simplicity, we use the same MCS for both UEs.
targetCodeRate = 616 / 1024; % With 16QAM, corresponds to MCS 20 in table qam64LowSE.

% Number of antenna ports at the gNB. For simplicity, at least equal to the
% total number of antenna ports across all UEs.
numRxPorts = 4;

% Finally, simulate the transmission and get the received resource grid.
%
%   grid                - the received resource grid;
%   infoData.Indices    - indices of REs carrying data for both UEs;
%   infoData.NREPerPRB  - number of REs carrying data for each PRB (across OFDM
%                         symbols and layers);
%   infoData.UE1        - transmitted bits for UE1;
%   infoData.UE2        - transmitted bits for UE2;
%   infoDMRS.Indices1   - DM-RS symbols for UE1;
%   infoDMRS.Symbols1   - indices of REs carrying DM-RS for UE1;
%   infoDMRS.Indices2   - DM-RS symbols for UE2;
%   infoDMRS.Symbols2   - indices of REs carrying DM-RS for UE2;
%   Hcoef               - Channel coefficients between Tx antenna ports (columns) and
%                         Rx antenna ports (rows). The channels are considered
%                         frequency flat.
[grid, infoData, infoDMRS, Hcoef] = generateRG(carrier, pusch1, pusch2, targetCodeRate, numRxPorts);

%% Channel estimation
% With the provided configuration, it is possible to estimate the channel of both UEs.
%
% In order to use MATLAB's channel estimation function, we need to trick it into
% thinking that we have a single UE transmitting all the layers.
%
% *Remark:* Regarding channel estimation, MATLAB's behavior differs from srsRAN
% Project since MATLAB estimates the channel between antenna ports at the Tx and
% Rx sides, while srsRAN estimates the per-layer equivalent channels to the Rx
% side, that is the product of the channel times the transmit precoding matrix.

% Silence excessively verbose warnings.
oldWarn = warning('query', 'nr5g:nrChannelEstimate:ZeroValuedSym');
warning('off', 'nr5g:nrChannelEstimate:ZeroValuedSym');

% Use the DM-RS to estimate the channels. DM-RS indices and symbols of the two UEs
% are combined together.
dmrsIndices1 = infoDMRS.Indices1;
dmrs1 = infoDMRS.Symbols1;
dmrsIndices2shifted = infoDMRS.Indices2 + pusch1.NumAntennaPorts * numel(grid(:, :, 1));
dmrs2 = infoDMRS.Symbols2;
estChannel = nrChannelEstimate(carrier, grid, [dmrsIndices1, dmrsIndices2shifted], [dmrs1, dmrs2]);

% Restore warnings.
warning(oldWarn.state, 'nr5g:nrChannelEstimate:ZeroValuedSym');

%%
% We can now compare the estimated channels (solid lines) with the actual coefficients
% (dotted lines). In this toy example, the channel is assumed frequency-flat.
plotChannels(estChannel, Hcoef, pusch1, pusch2);

%% PUSCH reception
% The PUSCH transmissions from the two UEs can now be decoded. In this simple
% example, since the UEs have the same configuration, one could decode both
% transmissions at the same time as if coming from a single UE with the total
% number of layers. However, in general, UEs may use different MCSs and, for that
% reason, we decode each PUSCH transmission separately.

% Configure an SCH decoder: since we picked the same MCS and number of layers,
% this is common for both UEs.
decUL = nrULSCHDecoder;
decUL.TargetCodeRate = targetCodeRate;
tbs1 = nrTBS(pusch1.Modulation, pusch1.NumLayers, numel(pusch1.PRBSet), infoData.NREPerPRB, targetCodeRate);
decUL.TransportBlockLength = tbs1;

% Set a nominal estimated noise variance. Under the controlled environment of
% the test, this works better than taking an estimated value.
estNoise = 0.001;

% Now decode UE1.
dataIndices = infoData.Indices;
[rx1, estCh1] = nrExtractResources(dataIndices, grid, estChannel(:, :, :, 1:pusch1.NumAntennaPorts));
rxSym1 = nrEqualizeMMSE(rx1, estCh1, estNoise);
llrs1 = nrPUSCHDecode(carrier, pusch1, rxSym1, estNoise);
rv = 0;
bits1 = decUL(llrs1, pusch1.Modulation, pusch1.NumLayers, rv);
assert(all(bits1 == infoData.UE1), 'The received bits for UE1 are incorrect.');

% Finally, decode UE2.
[rx2, estCh2] = nrExtractResources(dataIndices, grid, ...
        estChannel(:, :, :, pusch1.NumAntennaPorts + (1:pusch2.NumAntennaPorts)));
rxSym2 = nrEqualizeMMSE(rx2, estCh2, estNoise);
llrs2 = nrPUSCHDecode(carrier, pusch2, rxSym2, estNoise);
bits2 = decUL(llrs2, pusch2.Modulation, pusch2.NumLayers, rv);
assert(all(bits2 == infoData.UE2), 'The received bits for UE2 are incorrect.');



%% Helper functions.

% Simulates a PUSCH transmission with two superimposed UEs.
% Inputs:
%    carrier            - carrier configuration;
%    pusch1             - PUSCH configuration for UE1;
%    pusch2             - PUSCH configuration for UE2;
%    targetCodeRate     - target code rate, assumed common for both UEs;
%    numRxPorts         - number of antenna ports at the receive (i.e., gNB) side.
%
% Outputs:
%   grid                - the received resource grid;
%   infoData.Indices    - indices of REs carrying data for both UEs;
%   infoData.NREPerPRB  - number of REs carrying data for each PRB (across OFDM
%                         symbols and layers);
%   infoData.UE1        - transmitted bits for UE1;
%   infoData.UE2        - transmitted bits for UE2;
%   infoDMRS.Indices1   - DM-RS symbols for UE1;
%   infoDMRS.Symbols1   - indices of REs carrying DM-RS for UE1;
%   infoDMRS.Indices2   - DM-RS symbols for UE2;
%   infoDMRS.Symbols2   - indices of REs carrying DM-RS for UE2;
%   Hcoef               - Channel coefficients between Tx antenna ports (columns) and
%                         Rx antenna ports (rows). The channels are considered
%                         frequency flat.
function [grid, infoData, infoDMRS, Hcoef] = generateRG(carrier, pusch1, pusch2, targetCodeRate, numRxPorts)
    % Get indices for data and DM-RS.
    [dataIndices, indicesInfo] = nrPUSCHIndices(carrier, pusch1);
    dmrsIndices1 = nrPUSCHDMRSIndices(carrier, pusch1);
    dmrsIndices2 = nrPUSCHDMRSIndices(carrier, pusch2);

    numRBs = numel(pusch1.PRBSet);
    % Compute the transport block size.
    tbs1 = nrTBS(pusch1.Modulation, pusch1.NumLayers, numRBs, indicesInfo.NREPerPRB, targetCodeRate);
    % Configure a UL SCH encoder: since we picked the same MCS and number of layers,
    % this is common for both UEs.
    encUL = nrULSCH(TargetCodeRate=targetCodeRate);

    % Create the transmitted symbols for the first UE.
    bits1 = randi([0, 1], tbs1, 1, 'int8');
    encUL.setTransportBlock(bits1);
    bps1 = srsLib.phy.helpers.srsGetBitsSymbol(pusch1.Modulation);
    rv = 0;
    cw1 = encUL(pusch1.Modulation, pusch1.NumLayers, length(dataIndices) * bps1 * pusch1.NumLayers, rv);
    sym1 = nrPUSCH(carrier, pusch1, cw1);

    % Create the transmitted symbols for the second UE.
    tbs2 = nrTBS(pusch2.Modulation, pusch2.NumLayers, numRBs, indicesInfo.NREPerPRB, targetCodeRate);
    bits2 = randi([0, 1], tbs2, 1, 'int8');
    encUL.setTransportBlock(bits2);
    bps2 = srsLib.phy.helpers.srsGetBitsSymbol(pusch2.Modulation);
    cw2 = encUL(pusch2.Modulation, pusch2.NumLayers, length(dataIndices) * bps2 * pusch2.NumLayers, rv);
    sym2 = nrPUSCH(carrier, pusch2, cw2);

    % Create the DM-RS for the two UEs.
    dmrs1 = nrPUSCHDMRS(carrier, pusch1);
    dmrs2 = nrPUSCHDMRS(carrier, pusch2);

    % Generate a channel. For simplicity, let it be frequency flat and such that all
    % paths are orthogonal. In other words, we only need a coefficient for each path
    % and there will be no cross-path interference.
    [Hcoef, ~] = svd(randn(numRxPorts) + 1j * randn(numRxPorts));
    Hcoef = Hcoef(:, 1:(pusch1.NumAntennaPorts + pusch2.NumAntennaPorts));

    % Create the received resource grid.
    grid = nrResourceGrid(carrier, numRxPorts);

    nres = numel(grid(:, :, 1));
    for iRxPort = 1:numRxPorts
        for iTxPort = 1:pusch1.NumAntennaPorts
            grid(dataIndices(:, 1) + (iRxPort - 1) * nres) = grid(dataIndices(:, 1) + (iRxPort - 1) * nres) ...
                    + Hcoef(iRxPort, iTxPort) * sym1(:, iTxPort);
            grid(dmrsIndices1(:, 1) + (iRxPort - 1) * nres) = grid(dmrsIndices1(:, 1) + (iRxPort - 1) * nres) ...
                    + Hcoef(iRxPort, iTxPort) * dmrs1(:, iTxPort);
        end
        for iTxPort = 1:pusch2.NumAntennaPorts
            iChCoef = iTxPort + pusch1.NumAntennaPorts;
            grid(dataIndices(:, 1) + (iRxPort - 1) * nres) = grid(dataIndices(:, 1) + (iRxPort - 1) * nres) ...
                    + Hcoef(iRxPort, iChCoef) * sym2(:, iTxPort);
            grid(dmrsIndices2(:, 1) + (iRxPort - 1) * nres) = grid(dmrsIndices2(:, 1) + (iRxPort - 1) * nres) ...
                    + Hcoef(iRxPort, iChCoef) * dmrs2(:, iTxPort);
        end
    end

    % Add some noise.
    noiseVar = 0.0005;
    grid = grid + (randn(size(grid)) + 1j * randn(size(grid))) * sqrt(noiseVar / 2);

    infoData.Indices = dataIndices;
    infoData.NREPerPRB = indicesInfo.NREPerPRB;
    infoData.UE1 = bits1;
    infoData.UE2 = bits2;
    infoDMRS.Indices1 = dmrsIndices1;
    infoDMRS.Symbols1 = dmrs1;
    infoDMRS.Indices2 = dmrsIndices2;
    infoDMRS.Symbols2 = dmrs2;
end % of function [grid, infoData, infoDMRS, Hcoef] = generateRG()


% Plots the estimated channels (solid lines) for the first OFDM symbol, all receive
% ports and both UEs. They are compared with the true coefficients in Hcoef (dotted
% lines).
function plotChannels(estChannel, Hcoef, pusch1, pusch2)
    tpm1 = nrPUSCHCodebook(pusch1.NumLayers, pusch1.NumAntennaPorts, pusch1.TPMI);
    tpm2 = nrPUSCHCodebook(pusch2.NumLayers, pusch2.NumAntennaPorts, pusch2.TPMI);
    numSubcarriers = size(estChannel, 1);
    numRxPorts = size(estChannel, 3);
    figure
    tiledlayout(2, 1);
    linenames = {};
    for iRxPort = 1:numRxPorts
        for iTxPort = 1:pusch1.NumAntennaPorts
            if (tpm1(iTxPort) ~= 0)
                nexttile(1)
                ev = plot(0:(numSubcarriers-1), real(estChannel(:, 1, iRxPort, iTxPort)));
                hold on;
                tv = plot(0:(numSubcarriers-1), real(Hcoef(iRxPort, iTxPort)) * ones(numSubcarriers, 1), '.');
                tv.SeriesIndex = ev.SeriesIndex;
                linenames = {linenames{:}, sprintf('UE1-%d - Rx-%d', iTxPort - 1, iRxPort - 1), ''}; %#ok<CCAT>
                nexttile(2)
                ev = plot(0:(numSubcarriers-1), imag(estChannel(:, 1, iRxPort, iTxPort)));
                hold on;
                tv = plot(0:(numSubcarriers-1), imag(Hcoef(iRxPort, iTxPort)) * ones(numSubcarriers, 1), '.');
                tv.SeriesIndex = ev.SeriesIndex;
            end
        end
        for iTxPort = 1:pusch2.NumAntennaPorts
            iChCoef = iTxPort + pusch1.NumAntennaPorts;
            if (tpm2(iTxPort) ~= 0)
                nexttile(1)
                ev = plot(0:(numSubcarriers-1), real(estChannel(:, 1, iRxPort, iChCoef)));
                hold on;
                tv = plot(0:(numSubcarriers-1), real(Hcoef(iRxPort, iChCoef)) * ones(numSubcarriers, 1), '.');
                tv.SeriesIndex = ev.SeriesIndex;
                linenames = {linenames{:}, sprintf('UE2-%d - Rx-%d', iTxPort - 1, iRxPort - 1), ''}; %#ok<CCAT>
                nexttile(2)
                ev = plot(0:(numSubcarriers-1), imag(estChannel(:, 1, iRxPort, iChCoef)));
                hold on;
                tv = plot(0:(numSubcarriers-1), imag(Hcoef(iRxPort, iChCoef)) * ones(numSubcarriers, 1), '.');
                tv.SeriesIndex = ev.SeriesIndex;
            end
        end
    end
    nexttile(1)
    xlabel('Subcarrier index')
    title('Channel real part')
    legend(linenames)
    nexttile(2)
    xlabel('Subcarrier index')
    title('Channel imaginary part')
    legend(linenames)
end
