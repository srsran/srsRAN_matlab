%FormatDetailsF2 PUCCH Format 2 detail class for PUCCHPERF.
%
%   Helper class for the PUCCH performance simulator PUCCHPERF. It provides
%   metrics and method implementations specific for PUCCH Format 2. The class
%   is not meant to be used outside PUCCHPERF.
%
%   FormatDetailsF2 properties (read-only):
%
%   SNRrange                  - SNR range in dB.
%   TotalBlocksCtr            - Counter of transmitted UCI messages.
%   MissedBlocksMATLABCtr     - Counter of missed UCI messages for MATLAB PUCCH.
%   MissedBlocksSRSCtr        - Counter of missed UCI messages for SRS PUCCH.
%   FalseBlocksMATLABCtr      - Counter of falsely detected UCI blocks (MATLAB case).
%   FalseBlocksSRSCtr         - Counter of falsely detected UCI blocks (SRS case).
%   BlockErrorRateMATLAB      - UCI block error rate (MATLAB case).
%   BlockErrorRateSRS         - UCI block error rate (SRS case).
%   FalseDetectionRateMATLAB  - False detection rate of UCI blocks (MATLAB case).
%   FalseDetectionRateSRS     - False detection rate of UCI blocks (SRS case).
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

classdef FormatDetailsF2 < handle
    properties (SetAccess = private)
        %SNR range in dB.
        SNRrange = []
        %Counter of transmitted UCI messages.
        TotalBlocksCtr = []
        %Counter of missed UCI messages for MATLAB PUCCH.
        MissedBlocksMATLABCtr = []
        %Counter of missed UCI messages for SRS PUCCH.
        MissedBlocksSRSCtr = []
        %Counter of falsely detected UCI blocks (MATLAB case).
        FalseBlocksMATLABCtr = []
        %Counter of falsely detected UCI blocks (SRS case).
        FalseBlocksSRSCtr = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %UCI block error rate (MATLAB case).
        BlockErrorRateMATLAB
        %UCI block error rate (SRS case).
        BlockErrorRateSRS
        %False detection rate of UCI blocks (MATLAB case).
        FalseDetectionRateMATLAB
        %False detection rate of UCI blocks (SRS case).
        FalseDetectionRateSRS
    end

    properties (Hidden)
        %Number of HARQ-ACK bits.
        NumACKBits double {mustBeInteger, mustBeInRange(NumACKBits, 0, 1706)} = 4
        %Number of SR bits.
        NumSRBits double {mustBeInteger, mustBeInRange(NumSRBits, 0, 4)} = 0
        %Number of CSI Part 1 bits.
        NumCSI1Bits double {mustBeInteger, mustBeInRange(NumCSI1Bits, 0, 1706)} = 0
        %Number of CSI Part 2 bits.
        NumCSI2Bits double {mustBeInteger, mustBeInRange(NumCSI2Bits, 0, 1706)} = 0
        %Boolean flag test type: true if strcmp(TestType, 'Detection'), false otherwise.
        isDetectionTest
        %PUCCH format number.
        PUCCHFormat = 2
    end % of properties (Hidden)

    % This class is meant to be used only inside a PUCCHPERF simulation - restrict the constructor
    % and the methods that modify the properties.
    methods (Access = {?PUCCHPERF, ?FormatDetailsF3, ?FormatDetailsF4})
        function obj = FormatDetailsF2(nACKBits, nSRBits, nCSI1Bits, nCSI2Bits, isdetection)
            obj.isDetectionTest = isdetection;
            obj.NumACKBits = nACKBits;
            obj.NumSRBits = nSRBits;
            obj.NumCSI1Bits = nCSI1Bits;
            obj.NumCSI2Bits = nCSI2Bits;
        end % of function FormatDetailsF2(isdetection)

        function reset(obj)
            obj.SNRrange = [];
            obj.TotalBlocksCtr = [];
            obj.MissedBlocksMATLABCtr = [];
            obj.MissedBlocksSRSCtr = [];
            obj.FalseBlocksMATLABCtr = [];
            obj.FalseBlocksSRSCtr = [];
        end

        function updateCounters(obj, stats, SNRIn, totalBlocks)
            [~, repeatedIdx] = intersect(obj.SNRrange, SNRIn(:));
            obj.SNRrange(repeatedIdx) = [];
            [obj.SNRrange, sortedIdx] = sort([obj.SNRrange; SNRIn(:)]);
            obj.TotalBlocksCtr = joinArrays(obj.TotalBlocksCtr, totalBlocks, repeatedIdx, sortedIdx);
            if obj.isDetectionTest
                obj.MissedBlocksMATLABCtr = joinArrays(obj.MissedBlocksMATLABCtr, stats.blerUCI, repeatedIdx, sortedIdx);
                obj.MissedBlocksSRSCtr = joinArrays(obj.MissedBlocksSRSCtr, stats.blerUCISRS, repeatedIdx, sortedIdx);
            else
                obj.FalseBlocksMATLABCtr = joinArrays(obj.FalseBlocksMATLABCtr, stats.blerUCI, repeatedIdx, sortedIdx);
                obj.FalseBlocksSRSCtr = joinArrays(obj.FalseBlocksSRSCtr, stats.blerUCISRS, repeatedIdx, sortedIdx);
            end
        end % of function updateCounters(obj, stats, SNRIn, totalBlocks)
    end

    methods (Static)
        function checkSymbolAllocation(symbolAllocation)
            if (symbolAllocation(2) > 2)
                error('PUCCH Format2 only allows the allocation of 1 or 2 OFDM symbols - requested %d.', symbolAllocation(2));
            end
        end

        % Creates a temporary structure of metrics to collect data for the current simulation.
        function stats = setupTmpStats(nPoints)
            stats = struct(...
                'blerUCI', zeros(nPoints), ...
                'blerUCISRS', zeros(nPoints) ...
                );
        end % of function stats = setupTmpStats(nPoints)

        function [codedUCI, stats] = UCIEncode(uci, ~, bitCapacity, stats, ~)
            % Perform UCI encoding.
            codedUCI = nrUCIEncode(uci, bitCapacity);
        end

        function stats = updateStatsMATLAB(stats, uci, uciRx, ouci, isDetectTest, snrIdx)
            if isDetectTest
                % Decode UCI.
                decucibits = nrUCIDecode(uciRx{1}, ouci);

                % Store values to calculate BLER.
                stats.blerUCI(snrIdx) = stats.blerUCI(snrIdx) + (~isequal(decucibits, uci));
            else % false alarm test
                stats.blerUCI(snrIdx) = stats.blerUCI(snrIdx) + (~isempty(uciRx{1}));
            end % if isDetectTest
        end

        function stats = updateStatsSRS(stats, uci, msg, isDetectTest, snrIdx)
            if isDetectTest
                decucibitssrs = [msg.HARQAckPayload; msg.SRPayload; msg.CSI1Payload; msg.CSI2Payload];
                stats.blerUCISRS(snrIdx) = stats.blerUCISRS(snrIdx) + (~(isequal(decucibitssrs, uci)));
            else % false alarm test
                stats.blerUCISRS(snrIdx) = stats.blerUCISRS(snrIdx) + msg.isValid;
            end
        end

        function flag = isSimOver(stats, snrIdx, implementationType)
            useMATLABpucch = ~strcmp(implementationType, 'srs');
            useSRSpucch = ~strcmp(implementationType, 'matlab');

            flag = (~useMATLABpucch || (stats.blerUCI(snrIdx) >= 100)) && (~useSRSpucch || (stats.blerUCISRS(snrIdx) >= 100));
        end
    end % of methods (Static)

    methods
        function checkPRBs(obj, nPRBs)
            if ((nPRBs < 1) || (nPRBs > 16))
                error ('PUCCH Format%d requires a number of allocated PRBs between 1 and 16, given %d.', obj.PUCCHFormat, nPRBs);
            end
        end

        function checkUCIBits(obj, NumACKBits, NumSRBits, NumCSI1Bits, NumCSI2Bits)
            %Maximum number of UCI bits.
            MaxUCIBits = 1706;

            totalBits = NumACKBits + NumSRBits + NumCSI1Bits + NumCSI2Bits;

            if (totalBits < 3) || (totalBits > MaxUCIBits)
                error(['For PUCCH Format%d, the total number of UCI bits should be between 3 and 1706. ' ...
                    'Provided %d (HARQ-ACK: %d, SR: %d, CSI Part1: %d, CSI Part2: %d).'], ...
                    obj.PUCCHFormat, totalBits, NumACKBits, NumSRBits, NumCSI1Bits, NumCSI2Bits);
            end
        end

        function bler = get.BlockErrorRateMATLAB(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The BlockErrorRateMATLAB property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                bler = [];
                return
            end
            bler = obj.MissedBlocksMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function bler = get.BlockErrorRateSRS(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The BlockErrorRateSRS property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                bler = [];
                return
            end
            bler = obj.MissedBlocksSRSCtr ./ obj.TotalBlocksCtr;
        end

        function fdr = get.FalseDetectionRateMATLAB(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseDetectionRateMATLAB property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end
            fdr = obj.FalseBlocksMATLABCtr ./ obj.TotalBlocksCtr;
        end

        function fdr = get.FalseDetectionRateSRS(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseDetectionRateSRS property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end
            fdr = obj.FalseBlocksSRSCtr ./ obj.TotalBlocksCtr;
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
                if getSRS
                    counts.MissedBlocksSRSCtr = obj.MissedBlocksSRSCtr;
                end
                if getMatlab
                    counts.MissedBlocksMATLABCtr = obj.MissedBlocksMATLABCtr;
                end
            else
                if getSRS
                    counts.FalseBlocksSRSCtr = obj.FalseBlocksSRSCtr;
                end
                if getMatlab
                    counts.FalseBlocksMATLABCtr = obj.FalseBlocksMATLABCtr;
                end
            end
        end % of function counts = getCounters(obj, implementationType)

        function statistics = getStatistics(obj, implementationType)
            statistics = struct();

            getMatlab = ~strcmp(implementationType, 'srs');
            getSRS = ~strcmp(implementationType, 'matlab');
            if obj.isDetectionTest
                if getSRS
                    statistics.BlockErrorRateSRS = obj.BlockErrorRateSRS;
                end
                if getMatlab
                    statistics.BlockErrorRateMATLAB = obj.BlockErrorRateMATLAB;
                end
            else
                if getSRS
                    statistics.FalseDetectionRateSRS = obj.FalseDetectionRateSRS;
                end
                if getMatlab
                    statistics.FalseDetectionRateMATLAB = obj.FalseDetectionRateMATLAB;
                end
            end
        end % of function statistics = getStatistics(obj, implementationType)

        function printMessagesMATLAB(obj, stats, usedFrames, totalBlocks, SNRIn, isDetectTest, snrIdx)
            if isDetectTest
                message = ['UCI BLER of PUCCH Format ', num2str(obj.PUCCHFormat)];
            else
                message = ['UCI false detection rate of PUCCH Format ', num2str(obj.PUCCHFormat)];
            end

            fprintf([message ' for ' num2str(usedFrames) ...
                ' frame(s) at SNR ' num2str(SNRIn(snrIdx)) ' dB: ' num2str(stats.blerUCI(snrIdx)/totalBlocks(snrIdx)) '\n'])
        end % of function printMessages(stats, usedFrames, ~, SNRIn, isDetectTest, snrIdx)

        function printMessagesSRS(obj, stats, usedFrames, totalBlocks, SNRIn, isDetectTest, snrIdx)
            if isDetectTest
                message = ['UCI BLER of PUCCH Format ', num2str(obj.PUCCHFormat)];
            else
                message = ['UCI false detection rate of PUCCH Format ', num2str(obj.PUCCHFormat)];
            end

            fprintf('SRS - ');
            fprintf([message ' for ' num2str(usedFrames) ...
                ' frame(s) at SNR ' num2str(SNRIn(snrIdx)) ' dB: ' num2str(stats.blerUCISRS(snrIdx)/totalBlocks(snrIdx)) '\n'])
        end

        function plot(obj, implementationType, subcarrierSpacing)
            plotMATLAB = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
            plotSRS = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

            titleString = sprintf('PUCCH F%d / SCS=%dkHz / %d UCI bits', obj.PUCCHFormat, subcarrierSpacing, ...
                obj.NumACKBits + obj.NumSRBits + obj.NumCSI1Bits + obj.NumCSI2Bits);
            legendstrings = {};

            if obj.isDetectionTest
                ydataMATLAB = obj.MissedBlocksMATLABCtr;
                ydataSRS = obj.MissedBlocksSRSCtr;
                yLab = 'BLER';
            else
                ydataMATLAB = obj.FalseBlocksMATLABCtr;
                ydataSRS = obj.FalseBlocksSRSCtr;
                yLab = 'False Det. Rate';
            end

            figure;
            set(gca, "YScale", "log")
            if plotMATLAB
                semilogy(obj.SNRrange, ydataMATLAB ./ obj.TotalBlocksCtr, 'o-.', ...
                    'LineWidth', 1)
                legendstrings{end + 1} = 'MATLAB';
            end
            if plotSRS
                hold on;
                semilogy(obj.SNRrange, ydataSRS ./ obj.TotalBlocksCtr, '^-.', ...
                    'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980])
                legendstrings{end + 1} = 'SRS';
                hold off;
            end
            xlabel('SNR (dB)'); ylabel(yLab); grid on; legend(legendstrings);
            title(titleString);
        end % of function plot(obj, implementationType, subcarrierSpacing)
    end % of methods
end % of classdef FormatDetailsF2 < handle
