%FormatDetailsF1 PUCCH Format 1 detail class for PUCCHPERF.
%
%   Helper class for the PUCCH performance simulator PUCCHPERF. It provides
%   metrics and method implementations specific for PUCCH Format 1. The class
%   is not meant to be used outside PUCCHPERF.
%
%   FormatDetailsF1 properties (read-only):
%
%   SNRrange                      - SNR range in dB.
%   TransmittedACKsCtr            - Counter of tranmsitted ACK bits.
%   TransmittedNACKsCtr           - Counter of transmitted NACKs.
%   ACKOccasionsCtr               - Counter of ACK occasions.
%   MissedACKsMATLABCtr           - Counter of missed ACK bits (MATLAB case).
%   MissedACKsSRSCtr              - Counter of missed ACK bits (SRS case).
%   NACK2ACKsMATLABCtr            - Counter of NACK bits received as ACK bits (MATLAB case).
%   NACK2ACKsSRSCtr               - Counter of NACK bits received as ACK bits (SRS case).
%   FalseACKsMATLABCtr            - Counter of false ACK bits (MATLAB case).
%   FalseACKsSRSCtr               - Counter of false ACK bits (SRS case).
%   FalseACKDetectionRateMATLAB   - False ACK detection rate (MATLAB case).
%   FalseACKDetectionRateSRS      - False ACK detection rate (SRS case).
%   NACK2ACKDetectionRateMATLAB   - NACK-to-ACK detection rate (MATLAB case).
%   NACK2ACKDetectionRateSRS      - NACK-to-ACK detection rate (SRS case).
%   ACKDetectionRateMATLAB        - ACK Detection rate (MATLAB case).
%   ACKDetectionRateSRS           - ACK Detection rate (SRS case).
%
%   See also PUCCHPERF.

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

classdef FormatDetailsF1 < handle
    properties (SetAccess = private)
        %SNR range in dB.
        SNRrange = []
        %Counter of tranmsitted ACK bits.
        TransmittedACKsCtr = []
        %Counter of transmitted NACKs.
        TransmittedNACKsCtr = []
        %Counter of ACK occasions.
        ACKOccasionsCtr = []
        %Counter of missed ACK bits (MATLAB case).
        MissedACKsMATLABCtr = []
        %Counter of missed ACK bits (SRS case).
        MissedACKsSRSCtr = []
        %Counter of NACK bits received as ACK bits (MATLAB case).
        NACK2ACKsMATLABCtr = []
        %Counter of NACK bits received as ACK bits (SRS case).
        NACK2ACKsSRSCtr = []
        %Counter of false ACK bits (MATLAB case).
        FalseACKsMATLABCtr = []
        %Counter of false ACK bits (SRS case).
        FalseACKsSRSCtr = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %False ACK detection rate (MATLAB case).
        %   Probability of detecting an ACK when the input is only noise (or DTX).
        FalseACKDetectionRateMATLAB
        %False ACK detection rate (SRS case).
        %   Probability of detecting an ACK when the input is only noise (or DTX).
        FalseACKDetectionRateSRS
        %NACK-to-ACK detection rate (MATLAB case).
        %   Probability of detecting an ACK when a NACK is transmitted.
        NACK2ACKDetectionRateMATLAB
        %NACK-to-ACK detection rate (SRS case).
        %   Probability of detecting an ACK when a NACK is transmitted.
        NACK2ACKDetectionRateSRS
        %ACK Detection rate (MATLAB case).
        %   Probability of detecting an ACK when the ACK is transmitted.
        ACKDetectionRateMATLAB
        %ACK Detection rate (SRS case).
        %   Probability of detecting an ACK when the ACK is transmitted.
        ACKDetectionRateSRS
    end % of properties (Dependable)

    properties (Hidden)
        %Boolean flag test type: true if strcmp(TestType, 'Detection'), false otherwise.
        isDetectionTest
        %Number of HARQ-ACK bits.
        NumACKBits
        %Number of SR bits.
        NumSRBits
    end % of properties (Hidden)

    % This class is meant to be used only inside a PUCCHPERF simulation - restrict the constructor
    % and the methods that modify the properties.
    methods (Access = ?PUCCHPERF)
        function obj = FormatDetailsF1(nACKBits, nSRBits, isdetection)
            obj.NumACKBits = nACKBits;
            obj.NumSRBits = nSRBits;
            obj.isDetectionTest = isdetection;
        end % of function FormatDetailsF1(nACKBits, nSRBits, isdetection)

        function reset(obj)
            obj.SNRrange = [];
            obj.TransmittedACKsCtr = [];
            obj.TransmittedNACKsCtr = [];
            obj.ACKOccasionsCtr = [];
            obj.MissedACKsMATLABCtr = [];
            obj.MissedACKsSRSCtr = [];
            obj.FalseACKsMATLABCtr = [];
            obj.FalseACKsSRSCtr = [];
        end

        function updateCounters(obj, stats, SNRIn, ~)
            [~, repeatedIdx] = intersect(obj.SNRrange, SNRIn(:));
            obj.SNRrange(repeatedIdx) = [];
            [obj.SNRrange, sortedIdx] = sort([obj.SNRrange; SNRIn(:)]);

            if obj.isDetectionTest
                obj.TransmittedACKsCtr = joinArrays(obj.TransmittedACKsCtr, stats.nACKs, repeatedIdx, sortedIdx);
                obj.TransmittedNACKsCtr = joinArrays(obj.TransmittedNACKsCtr, stats.nNACKs, repeatedIdx, sortedIdx);
                obj.MissedACKsMATLABCtr = joinArrays(obj.MissedACKsMATLABCtr, stats.missedACK, repeatedIdx, sortedIdx);
                obj.MissedACKsSRSCtr = joinArrays(obj.MissedACKsSRSCtr, stats.missedACKSRS, repeatedIdx, sortedIdx);
                obj.NACK2ACKsMATLABCtr = joinArrays(obj.NACK2ACKsMATLABCtr, stats.NACK2ACK, repeatedIdx, sortedIdx);
                obj.NACK2ACKsSRSCtr = joinArrays(obj.NACK2ACKsSRSCtr, stats.NACK2ACKSRS, repeatedIdx, sortedIdx);
            else
                obj.ACKOccasionsCtr = joinArrays(obj.ACKOccasionsCtr, stats.nOccasions, repeatedIdx, sortedIdx);
                obj.FalseACKsMATLABCtr = joinArrays(obj.FalseACKsMATLABCtr, stats.falseACK, repeatedIdx, sortedIdx);
                obj.FalseACKsSRSCtr = joinArrays(obj.FalseACKsSRSCtr, stats.falseACKSRS, repeatedIdx, sortedIdx);
            end
        end % of function updateCounters(obj)
    end

    methods (Static)
        function checkSymbolAllocation(symbolAllocation)
            if symbolAllocation(2) < 4
                error('PUCCH Format1 only allows the allocation of a number of OFDM symbols in the range 4-14 - requested %d.', ...
                    symbolAllocation(2));
            end
        end

        function checkPRBs(nPRBs)
            if nPRBs ~= 1
                error ('PUCCH Format1 only allows one allocated PRB, given %d.', nPRBs);
            end
        end

        function checkUCIBits(NumACKBits, NumSRBits, NumCSI1Bits, NumCSI2Bits)
            if (NumSRBits > 0) || (NumCSI1Bits > 0) || (NumCSI2Bits > 0)
                error(['For PUCCH Format1, only ACK bits are allowed. '...
                    'Provided SR: %d, CSI Part1: %d, CSI Part2: %d.'], ...
                    NumSRBits, NumCSI1Bits, NumCSI2Bits);
            end
            if NumACKBits > 2
                error(['For PUCCH Format1, maximum 2 HARQ-ACK bits are allowed. '...
                    'Provided %d.'], NumACKBits);
            end
        end

        % Creates a temporary structure of metrics to collect data for the current simulation.
        function stats = setupTmpStats(nPoints)
            stats = struct(...
                'missedACK', zeros(nPoints, 1), ...    % number of MATLAB missed ACKs
                'NACK2ACK', zeros(nPoints, 1), ...     % number of MATLAB NACKs received as ACKs
                'falseACK', zeros(nPoints, 1), ...     % number of MATLAB false ACKs
                'missedACKSRS', zeros(nPoints, 1), ... % number of SRS missed ACKs
                'NACK2ACKSRS', zeros(nPoints, 1), ...  % number of SRS NACKs received as ACKs
                'falseACKSRS', zeros(nPoints, 1), ...  % number of SRS false ACKs
                'nACKs', zeros(nPoints, 1), ...        % number of transmitted ACKs
                'nNACKs', zeros(nPoints, 1), ...       % number of transmitted NACKs
                'nOccasions', zeros(nPoints, 1) ...    % number of ACK occasions (false alarm tests)
                );
        end

        function stats = updateStatsMATLAB(stats, uci, uciRx, ~, isDetectTest, snrIdx)
            if isDetectTest
                % If MATLAB's PUCCH decoder was able to detect a PUCCH and
                % uciRx contains the resulting bits.
                if ~isempty(uciRx{1})
                    % NACK to ACK.
                    stats.NACK2ACK(snrIdx) = stats.NACK2ACK(snrIdx) + sum(~uci & uciRx{1});
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

        function stats = updateStatsSRS(stats, uci, msg, isDetectTest, snrIdx)
            uciRxSRS = msg.HARQAckPayload;
            if isDetectTest
                % If SRS's PUCCH decoder was able to detect a PUCCH.
                if msg.isValid
                    % NACK to ACK.
                    stats.NACK2ACKSRS(snrIdx) = stats.NACK2ACKSRS(snrIdx) + sum(~uci & uciRxSRS);
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

        function printMessagesMATLAB(stats, usedFrames, ~, SNRIn, isDetectTest, snrIdx)
            if isDetectTest
                fprintf(['PUCCH Format 1 - NACK to ACK rate for %d frame(s) at ', ...
                'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.NACK2ACK(snrIdx)/stats.nNACKs(snrIdx));
                fprintf(['PUCCH Format 1 - ACK missed detection rate for %d frame(s) at ', ...
                'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.missedACK(snrIdx)/stats.nACKs(snrIdx));
            else
                fprintf(['PUCCH Format 1 - false ACK detection rate for %d frame(s) at ', ...
                'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACK(snrIdx)/stats.nOccasions(snrIdx));
            end
        end

        function printMessagesSRS(stats, usedFrames, ~, SNRIn, isDetectTest, snrIdx)
            if isDetectTest
                fprintf(['SRS - PUCCH Format 1 - NACK to ACK rate for %d frame(s) at ', ...
                    'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.NACK2ACKSRS(snrIdx)/stats.nNACKs(snrIdx));
                fprintf(['SRS - PUCCH Format 1 - ACK missed detection rate for %d frame(s) at ', ...
                    'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.missedACKSRS(snrIdx)/stats.nACKs(snrIdx));
            else
                fprintf(['SRS - PUCCH Format 1 - false ACK detection rate for %d frame(s) at ', ...
                    'SNR %.1f dB: %g\n'], usedFrames, SNRIn(snrIdx), stats.falseACKSRS(snrIdx)/stats.nOccasions(snrIdx));
            end
        end
    end % of methods (Static)

    methods
        function fdr = get.FalseACKDetectionRateMATLAB(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseACKDetectionRateMATLAB property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end
            fdr = obj.FalseACKsMATLABCtr ./ obj.ACKOccasionsCtr;
        end

        function fdr = get.FalseACKDetectionRateSRS(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseACKDetectionRateSRS property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end
            fdr = obj.FalseACKsSRSCtr ./ obj.ACKOccasionsCtr;
        end

        function n2a = get.NACK2ACKDetectionRateMATLAB(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The NACK2ACKDetectionRateMATLAB property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                n2a = [];
                return
            end
            n2a = obj.NACK2ACKsMATLABCtr ./ obj.TransmittedNACKsCtr;
        end

        function n2a = get.NACK2ACKDetectionRateSRS(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The NACK2ACKDetectionRateSRS property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                n2a = [];
                return
            end
            n2a = obj.NACK2ACKsSRSCtr ./ obj.TransmittedNACKsCtr;
        end

        function ackd = get.ACKDetectionRateMATLAB(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The ACKDetectionRateMATLAB property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                ackd = [];
                return
            end
            ackd = 1 - obj.MissedACKsMATLABCtr ./ obj.TransmittedACKsCtr;
        end

        function ackd = get.ACKDetectionRateSRS(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The ACKDetectionRateSRS property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                ackd = [];
                return
            end
            ackd = 1 - obj.MissedACKsSRSCtr ./ obj.TransmittedACKsCtr;
        end

        function flag = hasresults(obj)
            flag = ~isempty(obj.SNRrange);
        end

        function [codedUCI, stats] = UCIEncode(obj, uci, ouci, ~, stats, snrIdx)
            % For Format1, no encoding.
            codedUCI = uci;
            if obj.isDetectionTest
                stats.nACKs(snrIdx) = stats.nACKs(snrIdx) + sum(uci);
                stats.nNACKs(snrIdx) = stats.nNACKs(snrIdx) + sum(~uci);
            else
                stats.nOccasions(snrIdx) = stats.nOccasions(snrIdx) + ouci;
            end
        end % of function UCIEncode()

        function counts = getCounters(obj, implementationType)
            counts = struct();
            counts.SNRrange = obj.SNRrange;

            getMatlab = ~strcmp(implementationType, 'srs');
            getSRS = ~strcmp(implementationType, 'matlab');
            if obj.isDetectionTest
                counts.TransmittedACKsCtr = obj.TransmittedACKsCtr;
                counts.TransmittedNACKsCtr = obj.TransmittedNACKsCtr;
                if getSRS
                    counts.MissedACKsSRSCtr = obj.MissedACKsSRSCtr;
                    counts.NACK2ACKsSRSCtr = obj.NACK2ACKsSRSCtr;
                end
                if getMatlab
                    counts.MissedACKsMATLABCtr = obj.MissedACKsMATLABCtr;
                    counts.NACK2ACKsMATLABCtr = obj.NACK2ACKsMATLABCtr;
                end
            else
                counts.ACKOccasionsCtr = obj.ACKOccasionsCtr;
                if getSRS
                    counts.FalseACKsSRSCtr = obj.FalseACKsSRSCtr;
                end
                if getMatlab
                    counts.FalseACKsMATLABCtr = obj.FalseACKsMATLABCtr;
                end
            end
        end % of function getCounters(obj)

        function statistics = getStatistics(obj, implementationType)
            statistics = struct();

            getMatlab = ~strcmp(implementationType, 'srs');
            getSRS = ~strcmp(implementationType, 'matlab');
            if obj.isDetectionTest
                if getSRS
                    statistics.ACKDetectionRateSRS = obj.ACKDetectionRateSRS;
                    statistics.NACK2ACKDetectionRateSRS = obj.NACK2ACKDetectionRateSRS;
                end
                if getMatlab
                    statistics.ACKDetectionRateMATLAB = obj.ACKDetectionRateMATLAB;
                    statistics.NACK2ACKDetectionRateMATLAB = obj.NACK2ACKDetectionRateMATLAB;
                end
            else
                if getSRS
                    statistics.FalseACKDetectionRateSRS = obj.FalseACKDetectionRateSRS;
                end
                if getMatlab
                    statistics.FalseACKDetectionRateMATLAB = obj.FalseACKDetectionRateMATLAB;
                end
            end
        end % of function getStatistics(obj)

        function flag = isSimOver(obj, stats, snrIdx, implementationType)
            useMATLAB = ~strcmp(implementationType, 'srs');
            useSRS = ~strcmp(implementationType, 'matlab');

            if obj.isDetectionTest
                isSimOverMATLAB = (stats.missedACK(snrIdx) >= 100) && (stats.NACK2ACK(snrIdx) >= 100);
                isSimOverSRS = (stats.missedACKSRS(snrIdx) >= 100) && (stats.NACK2ACKSRS(snrIdx) >= 100);
            else
                isSimOverMATLAB = (stats.falseACK(snrIdx) >= 100);
                isSimOverSRS = (stats.falseACKSRS(snrIdx) >= 100);
            end
            isSimOverMATLAB = ~useMATLAB || isSimOverMATLAB;
            isSimOverSRS = ~useSRS || isSimOverSRS;

            flag = isSimOverMATLAB && isSimOverSRS;
        end

        function plot(obj, implementationType, subcarrierSpacing)

            plotMATLAB = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
            plotSRS = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

            titleString = sprintf('PUCCH F1 / SCS=%dkHz / %d ACK bits', subcarrierSpacing, obj.NumACKBits);
            legendstrings = {};

            figure;
            set(gca, "YScale", "log")
            if plotMATLAB
                if obj.isDetectionTest
                    semilogy(obj.SNRrange, obj.NACK2ACKsMATLABCtr ./ obj.TransmittedNACKsCtr, 'o-.', ...
                        'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                    legendstrings{end + 1} = 'MATLAB - NACK to ACK';

                    hold on;
                    semilogy(obj.SNRrange, obj.MissedACKsMATLABCtr ./ obj.TransmittedACKsCtr, 'square:', ...
                        'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                    legendstrings{end + 1} = 'MATLAB - Missed ACK';
                    hold off;
                else
                    semilogy(obj.SNRrange, obj.FalseACKsMATLABCtr ./ obj.ACKOccasionsCtr, 'o-.', ...
                        'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                    legendstrings{end + 1} = 'MATLAB - False ACK';
                end
            end

            if plotSRS
                hold on;
                if obj.isDetectionTest
                    semilogy(obj.SNRrange, obj.NACK2ACKsSRSCtr ./ obj.TransmittedNACKsCtr, 'o-.', ...
                        'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                    legendstrings{end + 1} = 'SRS - NACK to ACK';

                    semilogy(obj.SNRrange, obj.MissedACKsSRSCtr ./ obj.TransmittedACKsCtr, 'square:', ...
                        'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                    legendstrings{end + 1} = 'SRS - Missed ACK';
                else
                    semilogy(obj.SNRrange, obj.FalseACKsSRSCtr ./ obj.ACKOccasionsCtr, 'o-.', ...
                        'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                    legendstrings{end + 1} = 'SRS - False ACK';
                end
                hold off;
            end

            xlabel('SNR (dB)'); ylabel('Probability'); grid on; legend(legendstrings);
            title(titleString);
        end % of function plot(obj, implementationType, subcarrierSpacing)

    end % of methods
end % of classdef FormatDetailsF1
