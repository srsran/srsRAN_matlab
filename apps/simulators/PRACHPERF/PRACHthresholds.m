%PRACHthresholds Search PRACH detector thresholds.
%   PRACHthresholds(FILENAME) searches the values of the PRACH detection
%   threshold that achieve a probability of false alarm of 0.1% in an AWGN
%   channel. For all configurations, once the threshold is found, the function
%   also estimates the detection probability in AWGN, and both the false-alarm
%   and detection probabilities in under the TDLC300 channel. The results are
%   saved in table form in the FILENAME file. If, when the funcion is called,
%   FILENAME already contains a table of results, the simulation will not rerun
%   the configurations in the table.
%
%   PRACHthresholds(FILENAME, FORMAT) only runs the simulations for the given
%   PRACH format.
%
%   PRACHthresholds(FILENAME, FORMAT, SCS) only runs the simulations for the given
%   PRACH format and subcarrier spacing.

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

function PRACHthresholds(filename, format, scs)

    confs = loadconfs();
    lastConf = length(confs);

    % Prepare table to store results.
    varNames = ["Conf. #", "Format", "# Ant.", "SCS", "NCS", "Threshold", "PFA AWGN", "PD AWGN", "PFA TDL", "PD TDL"];
    varTypes = ["double", "string", "double", "double", "double", "double", "double", "double", "double", "double"];
    nResColumns = length(varTypes);
    sz = [lastConf * 16, nResColumns];

    w2e = warning('error', 'MATLAB:load:variableNotFound');
    try
        % Try to read the file and check if the content is compatible with the table.
        load(filename, 'results');
        assert(all(results.Properties.VariableNames == varNames), 'The table variable names are incorrect.');
        r1 = results(1, vartype('double'));
        assert(all(r1.Properties.VariableNames == varNames(varTypes == "double")), 'The table variable types are incorrect.');
        r2 = results(1, vartype("string"));
        assert(all(r2.Properties.VariableNames == varNames(varTypes == "string")), 'The table variable types are incorrect.');

        % Find the last non-zero entry of the first column.
        c1 = results.("Conf. #");
        [iRow, ~, startConf] = find(c1, 1, 'last');

        % Read the last NCS already written in the table.
        NCSused = results{iRow, "NCS"};

        % The following row will be good for writing new data.
        iRow = iRow + 1;
    catch ME
        % If the file doesn't exist...
        if strcmp(ME.identifier, 'MATLAB:load:couldNotReadFile')
            % Create a new table and start from the first row and first configuration.
            results = table('Size', sz, 'VariableTypes', varTypes, 'VariableNames', varNames);
            iRow = 1;
            startConf = 1;
            NCSused = -1;
        else
            % For all other errors, just rethrow them and stop.
            rethrow(ME);
        end
    end
    warning(w2e);

    % If a specific format is requested, skip all other configurations.
    if ((nargin >= 2) && ~strcmp(format, 'all'))
        mask = strcmp({confs.Format}, format);

        % If a specific subcarrier spacing is requested, skip all other configurations.
        if (nargin == 3)
            mask = mask & ([confs.PUSCHSubcarrierSpacing] == scs);
        end
        allIndices = 1:length(confs);
        confIndices = allIndices(mask);
        if isempty(confIndices)
            error('srsran_matlab:PRACHthresholds', ...
                'The requested format %s and subcarrier spacing of %d kHz do not match any valid configuration.', ...
                format, scs);
        end
        lastConf = confIndices(end);

        % If the result table is new (i.e., NCSused == -1) or if startConf (the last
        % configuration in the table) is not in the range, then set startConf
        % to the first configuration in the range.
        % Otherwise (the table is old and startConf is part of the range), nothing
        % to change.
        if ((NCSused == -1) || ~ismember(startConf, confIndices))
            startConf = confIndices(1);
            NCSused = -1;
        end
    end

    % Target false-alarm probability and number of runs needed to estimate it properly.
    targetPFA = 0.001;
    runsFA = ceil(100 / targetPFA); % 1e5

    % Number of runs for estimating the detection probability.
    runsDet = 10000;

    prachWarn = warning('query', 'srsran_matlab:srsPRACHdetector');
    warning('off', 'srsran_matlab:srsPRACHdetector');

    for iConf = startConf:lastConf
        % Load the configuration and set up the PRACHPERF simulator.
        thisConf = confs(iConf);

        prachperf = PRACHPERF;
        prachperf.Format = thisConf.Format;
        prachperf.NumReceiveAntennas = thisConf.NumReceiveAntennas;
        prachperf.PUSCHSubcarrierSpacing = thisConf.PUSCHSubcarrierSpacing;
        [seqIndex, prIndex] = getPreamble(thisConf.Format);
        prachperf.SequenceIndex = seqIndex;
        prachperf.PreambleIndex = prIndex;

        prachperf.IgnoreCFO = true;
        prachperf.QuickSimulation = true;

        % Get the list of valid NCS.
        NCSlist = getNCS(prachperf.Format);

        % Skip the ones already available in the file.
        if (NCSused > -1)
            NCSlist = NCSlist(NCSlist > NCSused);
            NCSused = -1;
        end

        for NCS = NCSlist
            % Change the NCS.
            prachperf.release();
            prachperf.NCS = NCS;

            %%%% Find the threshold for the AWGN channel.
            prachperf.DelayProfile = 'AWGN';
            prachperf.FrequencyOffset = 0;
            prachperf.TimeErrorTolerance = getTimeErrorTolerance(prachperf.Format, ...
                'AWGN', prachperf.PUSCHSubcarrierSpacing);
            prachperf.TestType = 'False Alarm';

            snr = thisConf.SNRawgn;

            % Rough search for the threshold: use a smaller number of runs to get
            % to a PFA in the interval (0.25, 10) relative to the target value.
            % Warning: statistically, it may happen that the true threshold falls
            % outside "fineBounds", but the probability should be negligible.
            maxPFA = min(targetPFA * 10, 1);
            minPFA = targetPFA / 4;
            [~, ~, fineBounds, fineValues] = estimateThreshold([0, 1], targetPFA * [10, -1], ...
                [minPFA, maxPFA], snr, ceil(runsFA/10), true);

            % Fine search for the threshold: the resulting PFA should fall in the
            % interval (0.9, 1) relative to the target value.
            [th, pfa] = estimateThreshold(fineBounds, fineValues, targetPFA * [0.9 1], snr, runsFA, false);

            %%%% Try the detection probability.
            prachperf.release();
            prachperf.TestType = 'Detection';
            prachperf.DetectionThreshold = th;
            prachperf(snr, runsDet);
            pdet = prachperf.ProbabilityDetectionPerfect;

            %%%% Try the TDL channel.
            snr = thisConf.SNRtdl;
            prachperf.release();
            prachperf.DelayProfile = 'TDLC300';
            prachperf.FrequencyOffset = 400;
            prachperf.TimeErrorTolerance = getTimeErrorTolerance(prachperf.Format, ...
                'TDLC300', prachperf.PUSCHSubcarrierSpacing);
            prachperf.TestType = 'False Alarm';
            prachperf.DetectionThreshold = th;
            prachperf(snr, runsFA);
            pfaTDL = prachperf.ProbabilityFalseAlarm;

            prachperf.release();
            prachperf.TestType = 'Detection';
            prachperf.DetectionThreshold = th;
            prachperf(snr, runsDet);
            pdetTDL = prachperf.ProbabilityDetectionPerfect;

            % Store the results in the table.
            results(iRow, :) = {iConf, thisConf.Format, thisConf.NumReceiveAntennas, ...
                thisConf.PUSCHSubcarrierSpacing, NCS, th, pfa, pdet, pfaTDL, pdetTDL};
            iRow = iRow + 1;
            save(filename, 'results');
        end % of for NCS = NCSlist

    end % of for iConf = startConf:lastConf

    warning(prachWarn.state, 'srsran_matlab:srsPRACHdetector');

    %%%% Nested functions %%%%

    %Runs the PFA simulation with different thresholds until the estimated PFA value
    %   falls within the desired interval.
    function [th_, pfa_, newTHbounds_, newFvalues_] = estimateThreshold(startTHs_, Fvalues_, bounds_, snr_, nRuns_, bootstrap)
        lowerTH_ = startTHs_(1);
        upperTH_ = startTHs_(2);
        FlowerTH_ = Fvalues_(1);
        FupperTH_ = Fvalues_(2);
        oldF_ = -1; % Any negative value will do.
        lowerBound_ = bounds_(1);
        upperBound_ = bounds_(2);

        th_ = upperTH_;
        pfa_ = 0;

        oldth_ = th_ + 1;
        while ((oldth_ ~= th_) && ((pfa_ > upperBound_) || (pfa_ < lowerBound_) || (pfa_ == 0)))
            newF_ = pfa_ - targetPFA;
            oldth_ = th_;
            if (bootstrap && (newF_ < 0))
                % While in the bootstrap phase, use the trivial bisection method.
                % Note that we leave bootstrap as soon as we get a PFA value larger
                % than the target value.
                upperTH_ = th_;
                th_ = round((lowerTH_ + upperTH_) / 2, 3);
            else
                bootstrap = false;
                % When not in bootstrap anymore, use the Anderson-Bjorck version of
                % the false position method.
                if (newF_ > 0)
                    lowerTH_ = th_;
                    FlowerTH_ = newF_;
                    if (oldF_ > 0)
                        m = 0.5;
                        mprime = 1 - newF_ / FlowerTH_;
                        if (mprime > 0)
                            m = mprime;
                        end
                        FupperTH_ = m * FupperTH_;
                    end
                else
                    upperTH_ = th_;
                    FupperTH_ = newF_;
                    if (oldF_ < 0)
                        m = 0.5;
                        mprime = 1 - newF_ / FupperTH_;
                        if (mprime > 0)
                            m = mprime;
                        end
                        FlowerTH_ = m * FlowerTH_;
                    end
                end

                th_ = round((lowerTH_ * FupperTH_ - upperTH_ * FlowerTH_) / (FupperTH_ - FlowerTH_), 3);
            end

            if (th_ == oldth_)
                % If we have space, move towards the center of the interval.
                mTH_ = upperTH_ + lowerTH_ - 2 * th_;
                if (abs(mTH_)  >= 0.004)
                    th_ = round(th_ + mTH_ / 4, 3);
                else
                    % Otherwise we are done.
                    break;
                end
            end
            oldF_ = newF_;

            fprintf('     %d: %.3f - %.3f - %.3f\n', nRuns_, lowerTH_, th_, upperTH_);

            prachperf.release();
            prachperf.DetectionThreshold = th_;
            prachperf(snr_, nRuns_); %#ok<NOEFF>
            pfa_ = prachperf.ProbabilityFalseAlarm;
        end

        newTHbounds_ = [lowerTH_ upperTH_];
        newFvalues_ = [FlowerTH_ FupperTH_];
    end % of function [th_, pfa_, newTHbounds_, newFvalues_] = estimateThreshold(startTHs_, Fvalues_, ...

end % of function searchthresholds(filename)

% Get the allowed time-error tolerance for format, delay profile and SCS.
function err = getTimeErrorTolerance(format, delayProfile, scs)
    if ismember(format, {'0', '1', '2'})
        % TS38.104 Section 8.4 only provides values for Format 0 - we set all
        % other long formats with SCS = 1.25 kHz the same.
        if strcmp(delayProfile, 'AWGN')
            err = 1.04;
        else
            err = 2.55;
        end
    elseif strcmp(format, '3')
        % TS38.104 Section 8.4 doesn't provide these values - we extrapolate
        % them comparing tolerance and SCS of the other formats.
        if strcmp(delayProfile, 'AWGN')
            err = 0.26;
        else
            err = 1.77;
        end
    else
        % For all short formats, although TS38.104 Section 8.4 only considers
        % Formats A1, A2, A3, B4, C0 and C2.
        if strcmp(delayProfile, 'AWGN')
            if scs == 15
                err = 0.52;
            elseif scs == 30
                err = 0.26;
            else
                err = 0.07;
            end
        else
            if scs == 15
                err = 2.03;
            elseif scs == 30
                err = 1.77;
            else
                err = 1.58;
            end
        end
    end
end % of function err = getTimeErrorTolerance(format, delayProfile, scs)

%Get the list of NCSs for the given format.
function ncslist = getNCS(format)
    if ismember(format, {'0', '1', '2'})
        ncslist = [0, 13, 15, 18, 22, 26, 32, 38, 46, 59, 76, 93, 119, 167, 279, 419];
    elseif strcmp(format, '3')
        ncslist = [0, 13, 26, 33, 38, 41, 49, 55, 64, 76, 93, 119, 139, 209, 279, 419];
    else
        ncslist = [0:2:12 13:2:19 23 27 34 46 69];
    end
end

%Get the sequence and preamble indices for the given format: different setups for
%   long and short formats according to TS38.141 Section 8.4.
function [seqIndex, prIndex] = getPreamble(format)
    if ismember(format, {'0', '1', '2', '3'})
        seqIndex = 22;
        prIndex = 32;
    else
        seqIndex = 0;
        prIndex = 0;
    end
end

%PRACH configurations: for each format and number of antennas (and SCS, for short
%   formats) we have different target SNRs for AWGN and TDL channels. Configurations
%   labeled "TS38.141" are specified in the standard, those labeled "custom"
%   are extrapolated from the ones in the standard according to the number of
%   antennas and preamble replicas.
function confs = loadconfs()
    confs = [ ...

        % custom
        struct(...
        'Format', '0', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -12, ...
        'SNRtdl', 0); ...

        % TS38.141
        struct(...
        'Format', '0', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -14.2, ...
        'SNRtdl', -6.0); ...

        % TS38.141
        struct(...
        'Format', '0', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -16.4, ...
        'SNRtdl', -11.3); ...

        % custom
        struct(...
        'Format', '1', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -15, ...
        'SNRtdl', -3); ...

        % custom
        struct(...
        'Format', '1', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -17.2, ...
        'SNRtdl', -9.0); ...

        % custom
        struct(...
        'Format', '1', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -19.4, ...
        'SNRtdl', -14.3); ...

        % custom
        struct(...
        'Format', '2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -18, ...
        'SNRtdl', -6); ...

        % custom
        struct(...
        'Format', '2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -20.2, ...
        'SNRtdl', -12.0); ...

        % custom
        struct(...
        'Format', '2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -22.4, ...
        'SNRtdl', -17.3); ...

        % custom
        struct(...
        'Format', '3', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -18, ...
        'SNRtdl', -6); ...

        % custom
        struct(...
        'Format', '3', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -20.2, ...
        'SNRtdl', -12.0); ...

        % custom
        struct(...
        'Format', '3', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -22.4, ...
        'SNRtdl', -17.3); ...

        % custom
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -6.8, ...
        'SNRtdl', 4.1); ...

        % TS38.141
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -9, ...
        'SNRtdl', -1.5); ...

        % TS38.141
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -11.3, ...
        'SNRtdl', -6.7); ...

        % custom
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -6.5, ...
        'SNRtdl', 2.8); ...

        % TS38.141
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -8.8, ...
        'SNRtdl', -2.2); ...

        % TS38.141
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.1, ...
        'SNRtdl', -6.6); ...

        % custom
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 120, ...
        'SNRawgn', -6.5, ...
        'SNRtdl', 2.8); ...

        % custom
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 120, ...
        'SNRawgn', -8.8, ...
        'SNRtdl', -2.2); ...

        % custom
        struct(...
        'Format', 'A1', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 120, ...
        'SNRawgn', -11.1, ...
        'SNRtdl', -6.6); ...

        % custom
        struct(...
        'Format', 'A2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -10.8, ...
        'SNRtdl', 1); ...

        % TS38.141
        struct(...
        'Format', 'A2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -12.3, ...
        'SNRtdl', -4.2); ...

        % TS38.141
        struct(...
        'Format', 'A2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -14.0, ...
        'SNRtdl', -9.7); ...

        % custom
        struct(...
        'Format', 'A2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -9.7, ...
        'SNRtdl', 0.9); ...

        % TS38.141
        struct(...
        'Format', 'A2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.7, ...
        'SNRtdl', -5.1); ...

        % TS38.141
        struct(...
        'Format', 'A2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -13.9, ...
        'SNRtdl', -9.8); ...

        % custom
        struct(...
        'Format', 'A3', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -12.5, ...
        'SNRtdl', 0.5); ...

        % TS38.141
        struct(...
        'Format', 'A3', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -13.9, ...
        'SNRtdl', -6); ...

        % TS38.141
        struct(...
        'Format', 'A3', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -15.7, ...
        'SNRtdl', -11.1); ...

        % custom
        struct(...
        'Format', 'A3', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.5, ...
        'SNRtdl', -0.5); ...

        % TS38.141
        struct(...
        'Format', 'A3', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -13.5, ...
        'SNRtdl', -6.8); ...

        % TS38.141
        struct(...
        'Format', 'A3', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -15.6, ...
        'SNRtdl', -11.4); ...

        % custom
        struct(...
        'Format', 'B1', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -6.8, ...
        'SNRtdl', 4.1); ...

        % custom
        struct(...
        'Format', 'B1', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -9, ...
        'SNRtdl', -1.5); ...

        % custom
        struct(...
        'Format', 'B1', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -11.3, ...
        'SNRtdl', -6.7); ...

        % custom
        struct(...
        'Format', 'B1', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -6.5, ...
        'SNRtdl', 2.8); ...

        % custom
        struct(...
        'Format', 'B1', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -8.8, ...
        'SNRtdl', -2.2); ...

        % custom
        struct(...
        'Format', 'B1', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.1, ...
        'SNRtdl', -6.6); ...

        % custom
        struct(...
        'Format', 'B2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -10.8, ...
        'SNRtdl', 1); ...

        % custom
        struct(...
        'Format', 'B2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -12.3, ...
        'SNRtdl', -4.2); ...

        % custom
        struct(...
        'Format', 'B2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -14.0, ...
        'SNRtdl', -9.7); ...

        % custom
        struct(...
        'Format', 'B2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -9.7, ...
        'SNRtdl', 0.9); ...

        % custom
        struct(...
        'Format', 'B2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.7, ...
        'SNRtdl', -5.1); ...

        % custom
        struct(...
        'Format', 'B2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -13.9, ...
        'SNRtdl', -9.8); ...

        % custom
        struct(...
        'Format', 'B3', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -12.5, ...
        'SNRtdl', 0.5); ...

        % custom
        struct(...
        'Format', 'B3', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -13.9, ...
        'SNRtdl', -6); ...

        % custom
        struct(...
        'Format', 'B3', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -15.7, ...
        'SNRtdl', -11.1); ...

        % custom
        struct(...
        'Format', 'B3', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.5, ...
        'SNRtdl', -0.5); ...

        % custom
        struct(...
        'Format', 'B3', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -13.5, ...
        'SNRtdl', -6.8); ...

        % custom
        struct(...
        'Format', 'B3', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -15.6, ...
        'SNRtdl', -11.4); ...

        % custom
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -14.3, ...
        'SNRtdl', -2); ...

        % TS38.141
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -16.5, ...
        'SNRtdl', -8.2); ...

        % TS38.141
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -18.7, ...
        'SNRtdl', -13.2); ...

        % custom
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -13.2, ...
        'SNRtdl', -3); ...

        % TS38.141
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -16.2, ...
        'SNRtdl', -9.3); ...

        % TS38.141
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -18.7, ...
        'SNRtdl', -13.9); ...

        % custom
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 120, ...
        'SNRawgn', -13.2, ...
        'SNRtdl', -3); ...

        % custom
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 120, ...
        'SNRawgn', -16.2, ...
        'SNRtdl', -9.3); ...

        % custom
        struct(...
        'Format', 'B4', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 120, ...
        'SNRawgn', -18.7, ...
        'SNRtdl', -13.9); ...

        % custom
        struct(...
        'Format', 'C0', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -3.6, ...
        'SNRtdl', 7); ...

        % TS38.141
        struct(...
        'Format', 'C0', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -6.0, ...
        'SNRtdl', 1.4); ...

        % TS38.141
        struct(...
        'Format', 'C0', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -8.4, ...
        'SNRtdl', -3.7); ...

        % custom
        struct(...
        'Format', 'C0', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -3.2, ...
        'SNRtdl', 6.5); ...

        % TS38.141
        struct(...
        'Format', 'C0', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -5.8, ...
        'SNRtdl', 0.7); ...

        % TS38.141
        struct(...
        'Format', 'C0', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -8.3, ...
        'SNRtdl', -3.9); ...

        % custom
        struct(...
        'Format', 'C2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -11, ...
        'SNRtdl', 2.1); ...

        % TS38.141
        struct(...
        'Format', 'C2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -12.2, ...
        'SNRtdl', -4.3); ...

        % TS38.141
        struct(...
        'Format', 'C2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 15, ...
        'SNRawgn', -13.8, ...
        'SNRtdl', -9.6); ...

        % custom
        struct(...
        'Format', 'C2', ...
        'NumReceiveAntennas', 1, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -9.6, ...
        'SNRtdl', 1); ...

        % TS38.141
        struct(...
        'Format', 'C2', ...
        'NumReceiveAntennas', 2, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -11.6, ...
        'SNRtdl', -5); ...

        % TS38.141
        struct(...
        'Format', 'C2', ...
        'NumReceiveAntennas', 4, ...
        'PUSCHSubcarrierSpacing', 30, ...
        'SNRawgn', -13.8, ...
        'SNRtdl', -9.8); ...

        ];
end
