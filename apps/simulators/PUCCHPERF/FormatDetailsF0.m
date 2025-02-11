%FormatDetailsF0 PUCCH Format 0 detail class for PUCCHPERF.
%
%   Helper class for the PUCCH performance simulator PUCCHPERF. It provides
%   metrics and method implementations specific for PUCCH Format 0. The class
%   is not meant to be used outside PUCCHPERF.
%
%   FormatDetailsF0 properties (read-only):
%
%   SNRrange                     - Simulated SNR range in dB.
%   TotalBlocksCtr               - Counter of transmitted UCI blocks.
%   TransmittedACKsCtr           - Counter of tranmsitted ACK bits.
%   MissedACKsMATLABCtr          - Counter of missed ACK bits (MATLAB case).
%   MissedACKsSRSCtr             - Counter of missed ACK bits (SRS case).
%   FalseACKsMATLABCtr           - Counter of false ACK bits (MATLAB case).
%   FalseACKsSRSCtr              - Counter of false ACK bits (SRS case).
%   FalseACKDetectionRateMATLAB  - False ACK detection rate (MATLAB case).
%   FalseACKDetectionRateSRS     - False ACK detection rate (SRS case).
%   ACKDetectionRateMATLAB       - ACK Detection rate (MATLAB case).
%   ACKDetectionRateSRS          - ACK Detection rate (SRS case).
%   MissedSRsMATLABCtr           - Counter of missed SR bits (MATLAB case).
%   MissedSRsSRSCtr              - Counter of missed SR bits (SRS case).
%   FalseSRsMATLABCtr            - Counter of false SR bits (MATLAB case).
%   FalseSRsSRSCtr               - Counter of false SR bits (SRS case).
%   SRDetectionRateMATLAB        - SR Detection rate (MATLAB case).
%   SRDetectionRateSRS           - SR Detection rate (SRS case).
%   FalseSRDetectionRateMATLAB   - False SR Detection rate (MATLAB case).
%   FalseSRDetectionRateSRS      - False SR Detection rate (SRS case).
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

classdef FormatDetailsF0 < handle
    properties (SetAccess = private)
        %SNR range in dB.
        SNRrange = []
        %Counter of transmitted UCI messages.
        TotalBlocksCtr = []
        %Counter of tranmsitted ACK bits.
        TransmittedACKsCtr = []
        %Counter of missed ACK bits (MATLAB case).
        MissedACKsMATLABCtr = []
        %Counter of missed ACK bits (SRS case).
        MissedACKsSRSCtr = []
        %Counter of false ACK bits (MATLAB case).
        FalseACKsMATLABCtr = []
        %Counter of false ACK bits (SRS case).
        FalseACKsSRSCtr = []
        %Counter of missed SR bits (MATLAB case).
        MissedSRsMATLABCtr = []
        %Counter of missed SR bits (SRS case).
        MissedSRsSRSCtr = []
        %Counter of false SR bits (MATLAB case).
        FalseSRsMATLABCtr = []
        %Counter of false SR bits (SRS case).
        FalseSRsSRSCtr = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %False ACK detection rate.
        %   Probability of detecting an ACK when the input is only noise (or DTX).
        FalseACKDetectionRateMATLAB
        %False ACK detection rate.
        %   Probability of detecting an ACK when the input is only noise (or DTX).
        FalseACKDetectionRateSRS
        %ACK Detection rate.
        %   Probability of detecting an ACK when the ACK is transmitted.
        ACKDetectionRateMATLAB
        %ACK Detection rate.
        %   Probability of detecting an ACK when the ACK is transmitted.
        ACKDetectionRateSRS
        %SR Detection rate.
        %   Probability of detecting an SR bit when it is transmitted.
        SRDetectionRateMATLAB
        %SR Detection rate.
        %   Probability of detecting an SR bit when it is transmitted.
        SRDetectionRateSRS
        %False SR detection rate.
        %   Probability of detecting an SR when the input is only noise.
        FalseSRDetectionRateMATLAB
        %False SR detection rate.
        %   Probability of detecting an SR when the input is only noise.
        FalseSRDetectionRateSRS
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
        function obj = FormatDetailsF0(nACKBits, nSRBits, isdetection)
            obj.NumACKBits = nACKBits;
            obj.NumSRBits = nSRBits;
            obj.isDetectionTest = isdetection;
        end % of function FormatDetailsF0(nACKBits, isdetection)

        function reset(obj)
            obj.SNRrange = [];
            obj.TotalBlocksCtr = [];
            obj.TransmittedACKsCtr = [];
            obj.MissedACKsMATLABCtr = [];
            obj.MissedACKsSRSCtr = [];
            obj.MissedSRsMATLABCtr = [];
            obj.MissedSRsSRSCtr = [];
            obj.FalseACKsMATLABCtr = [];
            obj.FalseACKsSRSCtr = [];
            obj.FalseSRsMATLABCtr = [];
            obj.FalseSRsSRSCtr = [];
        end % of function reset()

        function updateCounters(obj, stats, SNRIn, totalBlocks)
            [~, repeatedIdx] = intersect(obj.SNRrange, SNRIn(:));
            obj.SNRrange(repeatedIdx) = [];
            [obj.SNRrange, sortedIdx] = sort([obj.SNRrange; SNRIn(:)]);
            obj.TotalBlocksCtr = joinArrays(obj.TotalBlocksCtr, totalBlocks, repeatedIdx, sortedIdx);
            if obj.isDetectionTest
                obj.TransmittedACKsCtr = joinArrays(obj.TransmittedACKsCtr, stats.nACKs, repeatedIdx, sortedIdx);
                obj.MissedACKsMATLABCtr = joinArrays(obj.MissedACKsMATLABCtr, stats.errorACK, repeatedIdx, sortedIdx);
                obj.MissedACKsSRSCtr = joinArrays(obj.MissedACKsSRSCtr, stats.errorACKSRS, repeatedIdx, sortedIdx);
                obj.MissedSRsMATLABCtr = joinArrays(obj.MissedSRsMATLABCtr, stats.errorSR, repeatedIdx, sortedIdx);
                obj.MissedSRsSRSCtr = joinArrays(obj.MissedSRsSRSCtr, stats.errorSRSRS, repeatedIdx, sortedIdx);
            else
                obj.FalseACKsMATLABCtr = joinArrays(obj.FalseACKsMATLABCtr, stats.falseACK, repeatedIdx, sortedIdx);
                obj.FalseACKsSRSCtr = joinArrays(obj.FalseACKsSRSCtr, stats.falseACKSRS, repeatedIdx, sortedIdx);
                obj.FalseSRsMATLABCtr = joinArrays(obj.FalseSRsMATLABCtr, stats.falseACK, repeatedIdx, sortedIdx);
                obj.FalseSRsSRSCtr = joinArrays(obj.FalseSRsSRSCtr, stats.falseACKSRS, repeatedIdx, sortedIdx);
            end
        end % of function updateCounters(obj)
    end

    methods (Static)
        function checkSymbolAllocation(symbolAllocation)
            if symbolAllocation(2) > 2
                error('PUCCH Format0 only allows the allocation of a number of OFDM symbols in the range 1-2 - requested %d.', ...
                    symbolAllocation(2));
            end
        end % of function checkSymbolAllocation(symbolAllocation)

        function checkPRBs(nPRBs)
            if nPRBs ~= 1
                error ('PUCCH Format0 only allows one allocated PRB, given %d.', nPRBs);
            end
        end % of function checkPRBs(nPRBs)

        function checkUCIBits(NumACKBits, NumSRBits, NumCSI1Bits, NumCSI2Bits)
            if (NumCSI1Bits > 0) || (NumCSI2Bits > 0)
                error(['For PUCCH Format0, only ACK and SR bits are allowed. '...
                'Provided CSI Part1: %d, CSI Part2: %d.'], ...
                NumCSI1Bits, NumCSI2Bits);
            end
            if (NumACKBits > 2)
                error(['For PUCCH Format0, maximum 2 HARQ-ACK bits are allowed. '...
                'Provided %d.'], NumACKBits);
            end
            if (NumSRBits > 1)
                error(['For PUCCH Format0, maximum 1 SR bit is allowed. '...
                'Provided %d.'], NumSRBits);
            end
        end % of function checkUCIBits(NumACKBits, NumSRBits, NumCSI1Bits, ...)

        % Creates a temporary structure of metrics to collect data for the current simulation.
        function stats = setupTmpStats(nPoints)
            stats = struct(...
                'errorACK', zeros(nPoints, 1), ...     % number of MATLAB erroneous ACKs
                'falseACK', zeros(nPoints, 1), ...     % number of MATLAB false ACKs
                'errorSR', zeros(nPoints, 1), ...      % number of MATLAB erroneous SR bits
                'falseSR', zeros(nPoints, 1), ...      % number of MATLAB false SR bits
                'errorACKSRS', zeros(nPoints, 1), ...  % number of SRS erroneous ACKs
                'falseACKSRS', zeros(nPoints, 1), ...  % number of SRS false ACKs
                'errorSRSRS', zeros(nPoints, 1), ...   % number of SRS erroneous SR bits
                'falseSRSRS', zeros(nPoints, 1), ...   % number of SRS false SR bits
                'nACKs', zeros(nPoints, 1), ...        % number of ACK occasions
                'nSRs', zeros(nPoints, 1) ...          % number of SR occasions
                );
        end % of function setupTmpStats(nPoints)

        function [codedUCI, stats] = UCIEncode(uci, ouci, ~, stats, snrIdx)
            % For Format0, no encoding.
            codedUCI = uci;
            stats.nACKs(snrIdx) = stats.nACKs(snrIdx) + ouci(1);
            stats.nSRs(snrIdx) = stats.nSRs(snrIdx) + ouci(2);
        end % of function UCIEncode(~, uci, stats)

        function stats = updateStatsMATLAB(stats, uci, uciRx, ouci, isDetectTest, snrIdx)
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

        function stats = updateStatsSRS(stats, uci, msg, isDetectTest, snrIdx)
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

        function printMessagesMATLAB(stats, usedFrames, nSRs, SNRIn, isDetectTest, snrIdx)
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

        function printMessagesSRS(stats, usedFrames, nSRs, SNRIn, isDetectTest, snrIdx)
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

            ref = obj.TotalBlocksCtr * obj.NumACKBits;
            fdr = obj.FalseACKsMATLABCtr ./ ref;
        end

        function fdr = get.FalseACKDetectionRateSRS(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseACKDetectionRateSRS property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end

            ref = obj.TotalBlocksCtr * obj.NumACKBits;
            fdr = obj.FalseACKsSRSCtr ./ ref;
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

        function srdr = get.SRDetectionRateMATLAB(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The SRDetectionRateMATLAB property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                srdr = [];
                return
            end
            srdr = 1 - obj.MissedSRsMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function srdr = get.SRDetectionRateSRS(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The SRDetectionRateSRS property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                srdr = [];
                return
            end
            srdr = 1 - obj.MissedSRsSRSCtr ./ obj.TotalBlocksCtr;
        end

        function srfdr = get.FalseSRDetectionRateMATLAB(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseSRDetectionRateMATLAB property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                srfdr = [];
                return
            end
            srfdr = obj.FalseSRsMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function srfdr = get.FalseSRDetectionRateSRS(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseSRDetectionRateSRS property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                srfdr = [];
                return
            end
            srfdr = obj.FalseSRsSRSCtr ./ obj.TotalBlocksCtr;
        end

        function flag = hasresults(obj)
            flag = ~isempty(obj.SNRrange);
        end

        function counts = getCounters(obj, implementationType)
            counts = struct();
            counts.SNRrange = obj.SNRrange;
            counts.TotalBlocksCtr = obj.TotalBlocksCtr;

            getMatlab = ~strcmp(implementationType, 'srs');
            getSRS = ~strcmp(implementationType, 'matlab');
            if obj.isDetectionTest
                counts.TransmittedACKsCtr = obj.TransmittedACKsCtr;
                if getSRS
                    counts.MissedACKsSRSCtr = obj.MissedACKsSRSCtr;
                    counts.MissedSRsSRSCtr = obj.MissedSRsSRSCtr;
                end
                if getMatlab
                    counts.MissedACKsMATLABCtr = obj.MissedACKsMATLABCtr;
                    counts.MissedSRsMATLABCtr = obj.MissedSRsMATLABCtr;
                end
            else
                if getSRS
                    counts.FalseACKsSRSCtr = obj.FalseACKsSRSCtr;
                    counts.FalseSRsSRSCtr = obj.FalseSRsSRSCtr;
                end
                if getMatlab
                    counts.FalseACKsMATLABCtr = obj.FalseACKsMATLABCtr;
                    counts.FalseSRsMATLABCtr = obj.FalseSRsMATLABCtr;
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
                    statistics.SRDetectionRateSRS = obj.SRDetectionRateSRS;
                end
                if getMatlab
                    statistics.ACKDetectionRateMATLAB = obj.ACKDetectionRateMATLAB;
                    statistics.SRDetectionRateMATLAB = obj.SRDetectionRateMATLAB;
                end
            else
                if getSRS
                    statistics.FalseACKDetectionRateSRS = obj.FalseACKDetectionRateSRS;
                    statistics.FalseSRDetectionRateSRS = obj.FalseSRDetectionRateSRS;
                end
                if getMatlab
                    statistics.FalseACKDetectionRateMATLAB = obj.FalseACKDetectionRateMATLAB;
                    statistics.FalseSRDetectionRateMATLAB = obj.FalseSRDetectionRateMATLAB;
                end
            end
        end % of function getStatistics(obj)

        function flag = isSimOver(obj, stats, snrIdx, implementationType)
            useMATLAB = ~strcmp(implementationType, 'srs');
            useSRS = ~strcmp(implementationType, 'matlab');

            isSimOverMATLAB = (stats.falseACK(snrIdx) >= 100) && (~obj.isDetectionTest || (obj.isDetectionTest && (stats.errorACK(snrIdx) >= 100)));
            isSimOverMATLAB = isSimOverMATLAB || (obj.isDetectionTest && (obj.NumSRBits > 0) && (stats.errorSR(snrIdx) >= 100));
            isSimOverMATLAB = ~useMATLAB || isSimOverMATLAB;

            isSimOverSRS = (stats.falseACKSRS(snrIdx) >= 100) && (~obj.isDetectionTest || (obj.isDetectionTest && (stats.errorACKSRS(snrIdx) >= 100)));
            isSimOverSRS = isSimOverSRS || (obj.isDetectionTest && (obj.NumSRBits > 0) && (stats.errorSRSRS(snrIdx) >= 100));
            isSimOverSRS = ~useSRS || isSimOverSRS;

            flag = isSimOverMATLAB && isSimOverSRS;
        end

        % Plot the collected metrics as a function of the SNR.
        function plot(obj, implementationType, subcarrierSpacing)
            if (isempty(obj.SNRrange))
                warning('Empty simulation data.');
                return;
            end

            plotMATLAB = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
            plotSRS = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

            titleString = sprintf('PUCCH F0 / SCS=%dkHz / %d ACK bits', subcarrierSpacing, obj.NumACKBits);
            legendstrings = {};

            figure;
            set(gca, "YScale", "log")
            if plotMATLAB
                hold on;
                if obj.isDetectionTest
                    if (obj.NumACKBits > 0)
                        semilogy(obj.SNRrange, obj.MissedACKsMATLABCtr ./ obj.TransmittedACKsCtr, 'square:', ...
                            'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                        legendstrings{end + 1} = 'MATLAB - ACK Error';
                    end
                    if (obj.NumSRBits > 0)
                        semilogy(obj.SNRrange, obj.MissedSRsMATLABCtr ./ obj.TotalBlocksCtr, 'o-.', ...
                            'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                        legendstrings{end + 1} = 'MATLAB - SR Error';
                    end
                else
                    if (obj.NumACKBits > 0)
                        semilogy(obj.SNRrange, obj.FalseACKsMATLABCtr ./ obj.TotalBlocksCtr / obj.NumACKBits, 'square:', ...
                            'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                        legendstrings{end + 1} = 'MATLAB - False ACK';
                    end
                    if (obj.NumSRBits > 0)
                        semilogy(obj.SNRrange, obj.FalseSRsMATLABCtr ./ obj.TotalBlocksCtr, 'o-.', ...
                            'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
                        legendstrings{end + 1} = 'MATLAB - False SR';
                    end
                end
                hold off;
            end

            if plotSRS
                hold on;
                if obj.isDetectionTest
                    if (obj.NumACKBits > 0)
                        semilogy(obj.SNRrange, obj.MissedACKsSRSCtr ./ obj.TransmittedACKsCtr, 'square:', ...
                            'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                        legendstrings{end + 1} = 'SRS - ACK Error';
                    end
                    if (obj.NumSRBits > 0)
                        semilogy(obj.SNRrange, obj.MissedSRsSRSCtr ./ obj.TotalBlocksCtr, 'o-.', ...
                            'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                        legendstrings{end + 1} = 'MATLAB - SR Error';
                    end
                else
                    if (obj.NumACKBits > 0)
                        semilogy(obj.SNRrange, obj.FalseACKsSRSCtr ./ obj.TotalBlocksCtr / obj.NumACKBits, 'square:', ...
                            'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                        legendstrings{end + 1} = 'SRS - False ACK';
                    end
                    if (obj.NumSRBits > 0)
                        semilogy(obj.SNRrange, obj.FalseSRsSRSCtr ./ obj.TotalBlocksCtr, 'o-.', ...
                            'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
                        legendstrings{end + 1} = 'SRS - False SR';
                    end
                end
                hold off;
            end

            xlabel('SNR (dB)'); ylabel('Probability'); grid on; legend(legendstrings);
            title(titleString);
        end % of function plot(obj, implementationType, subcarrierSpacing)

    end % of methods
end % of classdef FormatF0Details

