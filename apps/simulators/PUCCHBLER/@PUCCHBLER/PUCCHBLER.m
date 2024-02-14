%PUCCHBLER PUCCH performance simulator.
%   PUCCHSIM = PUCCHBLER creates a PUCCH simulator object, PUCCHSIM. This object
%   simulates a PUCCH transmission according to the specified setup (see list of
%   PUCCHBLER properties below) and measures the detection probability or the
%   block error rate depending on the PUCCH format and/or the number of UCI bits.
%
%   Step method syntax
%
%   step(PUCCHSIM, SNRIN) runs a PUCCH simulation corresponding to ten 10-ms
%   frames for each one of the SNR values (dB) specified in SNRIN (a real-valued
%   array). When the simulation is over, the results will be available as properties
%   of the PUCCHSIM object (see below).
%
%   step(PUCCHSIM, SNRIN, NFRAMES) runs simulations corresponding to NFRAMES 10-ms
%   frames. Setting parameter QuickSimulation to true, each simulated point is
%   stopped earlier when reaching 100 failed block transmissions.
%
%   Being a MATLAB system object, the PUCCHSIM object may be called directly as
%   a function instead of using the step method. For example, step(PUCCHSIM, SNRIN)
%   is equivalent to PUCCHSIM(SNRIN).
%
%   Note: Successive calls of the step method will result in a combined set
%   of simulation results spanning all the provided SNR values (common SNR values
%   will be overwritten by the last call of the step method). Call the reset
%   method to start a new simulation from scratch without changing the parameters.
%
%   Note: Calling the step method locks the object (the locked status can be
%   verified with the logical method isLocked). Once the object is locked,
%   simulation parameters cannot be changed (unless they are marked as tunable)
%   until the release method is called. It is worth mentioning that releasing
%   a PUCCHBLER object implies resetting the simulation results.
%
%   Note: PUCCHBLER objects can be saved and loaded normally as all MATLAB objects.
%   Saving an unlocked object only stores the simulation configuration. Saving
%   a locked object also stores all simulation results so that the simulation
%   can be resumed after loading the object.
%
%   PUCCHBLER methods:
%
%   step        - Runs a PUCCH simulation (see above).
%   release     - Allows property value changes (implies reset).
%   clone       - Creates PUCCHBLER object with same property values.
%   isLocked    - Locked status (logical).
%   reset       - Resets simulated data.
%   plot        - Plots detection/BLER curves (if simulated data are present).
%
%   PUCCHBLER properties (all nontunable, unless otherwise specified):
%
%   NTxAnts                      - Number of transmit antennas (currently fixed to 1).
%   NRxAnts                      - Number of receive antennas.
%   PerfectChannelEstimator      - Perfect channel estimation flag.
%   DisplaySimulationInformation - Flag for displaying simulation information.
%   NSizeGrid                    - Bandwidth as a number of resource blocks.
%   SubcarrierSpacing            - Subcarrier spacing in kHz.
%   NCellID                      - Cell identity.
%   PRBSet                       - PUCCH allocated PRBs (specify as an array, e.g. 0:51).
%   SymbolAllocation             - PUCCH OFDM symbol allocation.
%   RNTI                         - Radio network temporary identifier (0...65535).
%   PUCCHFormat                  - PUCCH format (1, 2, 3).
%   FrequencyHopping             - Frequency hopping ('intraSlot', 'interSlot', 'either')
%   Modulation                   - Modulation scheme (inactive if "PUCCHFormat ~= 3").
%   NumACKBits                   - Number of HARQ-ACK bits.
%   NumSRBits                    - Number of SR bits.
%   NumCSI1Bits                  - Number of CSI Part 1 bits.
%   NumCSI2Bits                  - Number of CSI Part 2 bits.
%   DelayProfile                 - Channel delay profile ('AWGN'(no delay, no Doppler),
%                                  'TDL-C'(rural scenario), 'TDLC300' (simplified rural scenario)).
%   DelaySpread                  - Delay spread in seconds (TDL-C delay profile only).
%   MaximumDopplerShift          - Maximum Doppler shift in hertz (TDL-C and TDLC300 delay profile only).
%   ImplementationType           - PUCCH implementation type ('matlab', 'srs' or 'both').
%   TestType                     - Test type ('Detection', 'False Alarm').
%   QuickSimulation              - Quick-simulation flag: set to true to stop
%                                  each point after 100 errors (tunable).
%
%   When the simulation is over, the object allows access to the following
%   results properties (depending on TestType).
%
%   SNRrange                     - Simulated SNR range in dB.
%   TotalBlocksCtr               - Counter of transmitted UCI blocks.
%   MissedBlocksMATLABCtr        - Counter of missed UCI blocks (PUCCH Format 2 or 3, MATLAB case).
%   MissedBlocksSRSCtr           - Counter of missed UCI blocks (PUCCH Format 2 or 3, SRS case).
%   BlockErrorRateMATLAB         - UCI block error (or missed detection) rate (PUCCH Format 2 or 3, MATLAB case).
%   BlockErrorRateSRS            - UCI block error (or missed detection) rate (PUCCH Format 2 or 3, SRS case).
%   FalseBlocksMATLABCtr         - Counter of falsely detected UCI blocks (PUCCH Format 2 or 3, MATLAB case).
%   FalseBlocksSRSCtr            - Counter of falsely detected UCI blocks (PUCCH Format 2 or 3, SRS case).
%   FalseDetectionRateMATLAB     - False detection rate of UCI blocks (PUCCH Format 2 or 3, MATLAB case).
%   FalseDetectionRateSRS        - False detection rate of UCI blocks (PUCCH Format 2 or 3, SRS case).
%   TransmittedACKsCtr           - Counter of tranmsitted ACK bits (PUCCH Format 1).
%   TransmittedNACKsCtr          - Counter of transmitted NACKs (or ACK "occasions" in 'False Alarm' tests -
%                                  PUCCH Format 1).
%   MissedACKsMATLABCtr          - Counter of missed ACK bits (PUCCH Format 1, MATLAB case).
%   MissedACKsSRSCtr             - Counter of missed ACK bits (PUCCH Format 1, SRS case).
%   FalseACKsMATLABCtr           - Counter of false ACK bits (PUCCH Format 1, MATLAB case).
%   FalseACKsSRSCtr              - Counter of false ACK bits (PUCCH Format 1, SRS case).
%   FalseACKDetectionRateMATLAB  - False ACK detection rate (PUCCH Format 1, MATLAB case).
%   FalseACKDetectionRateSRS     - False ACK detection rate (PUCCH Format 1, SRS case).
%   NACK2ACKDetectionRateMATLAB  - NACK-to-ACK detection rate (PUCCH Format 1, MATLAB case).
%   NACK2ACKDetectionRateSRS     - NACK-to-ACK detection rate (PUCCH Format 1, SRS case).
%   ACKDetectionRateMATLAB       - ACK Detection rate (PUCCH Format 1, MATLAB case).
%   ACKDetectionRateSRS          - ACK Detection rate (PUCCH Format 1, SRS case).
%
%   Remark: The simulation loop is heavily based on the <a href="https://www.mathworks.com/help/5g/ug/nr-pucch-block-error-rate.html">NR PUCCH Block Error Rate</a> MATLAB example by MathWorks.

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

classdef PUCCHBLER < matlab.System
    properties (Constant)
        %Number of transmit antennas.
        NTxAnts = 1
        %Maximum number of UCI bits.
        MaxUCIBits = 1706
    end % of constant properties

    properties (Nontunable)
        %Perfect channel estimation flag.
        PerfectChannelEstimator (1, 1) logical = true
        %Number of receive antennas.
        NRxAnts = 1
        %Bandwidth in number of resource blocks.
        NSizeGrid (1, 1) double {mustBeInteger, mustBePositive} = 25
        %Subcarrier spacing in kHz (15, 30).
        SubcarrierSpacing (1, 1) double {mustBeMember(SubcarrierSpacing, [15, 30])} = 15
        %Cell identity.
        NCellID (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(NCellID, 0, 1007)} = 1
        %PUCCH allocated PRBs.
        PRBSet = 0:3
        %PUCCH OFDM symbol allocation in each slot.
        %   Specify as a two-element array, where the first element represents the
        %   start of symbol allocation (0-based) and the second element represents
        %   the number of allocated OFDM symbols (e.g., [0 14]).
        SymbolAllocation = [13, 1]
        %Radio network temporary identifier (0...65535).
        RNTI (1, 1) double {mustBeReal, mustBeInteger, mustBeInRange(RNTI, 0, 65535)} = 1
        %Modulation scheme (only when "PUCCHFormat == 3").
        %   Choose between 'BPSK', 'pi/2-BPSK', 'QPSK'.
        Modulation (1, :) char {mustBeMember(Modulation, {'BPSK', 'pi/2-BPSK', 'QPSK'})} = 'QPSK'
        %PUCCH Format (1, 2, 3).
        PUCCHFormat double {mustBeInteger, mustBeInRange(PUCCHFormat, 1, 3)} = 2
        %Frequency hopping ('intraSlot', 'interSlot', 'either')
        FrequencyHopping  {mustBeMember(FrequencyHopping, {'intraSlot', 'interSlot', 'neither'})} = 'neither'
        %Number of HARQ-ACK bits.
        NumACKBits double {mustBeInteger, mustBeInRange(NumACKBits, 0, 1706)} = 4
        %Number of SR bits.
        NumSRBits double {mustBeInteger, mustBeInRange(NumSRBits, 0, 4)} = 0
        %Number of CSI Part 1 bits.
        NumCSI1Bits double {mustBeInteger, mustBeInRange(NumCSI1Bits, 0, 1706)} = 0
        %Number of CSI Part 2 bits.
        NumCSI2Bits double {mustBeInteger, mustBeInRange(NumCSI2Bits, 0, 1706)} = 0
        %Channel delay profile ('AWGN'(no delay), 'TDL-C'(rural scenario), 'TDLC300' (simplified rural scenario)).
        DelayProfile (1, :) char {mustBeMember(DelayProfile, {'AWGN', 'TDL-C', 'TDLC300'})} = 'AWGN'
        %Delay spread in seconds (TDL-C delay profile only).
        DelaySpread (1, 1) double {mustBeReal, mustBeNonnegative} = 300e-9
        %Maximum Doppler shift in hertz (TDL-C and TDLC300 delay profile only).
        MaximumDopplerShift (1, 1) double {mustBeReal, mustBeNonnegative} = 100
        %PUCCH implementation type ('matlab', 'srs', 'both').
        ImplementationType (1, :) char {mustBeMember(ImplementationType, {'matlab', 'srs', 'both'})} = 'matlab'
        %Test type.
        %   Possible values are ('Detection', 'False Alarm'). Default is 'Detection'.
        TestType (1, :) char {mustBeMember(TestType, {'Detection', 'False Alarm'})} = 'Detection'
    end % of properties (Nontunable)

    properties % Tunable
        %Flag for displaying simulation information.
        DisplaySimulationInformation (1, 1) logical = false
        %Quick-simulation flag: set to true to stop each point after 100 errors.
        QuickSimulation (1, 1) logical = true
    end % of properties Tunable

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
        %Counter of tranmsitted ACK bits.
        TransmittedACKsCtr = []
        %Counter of transmitted NACKs (or ACK "occasions" in 'False Alarm' tests).
        TransmittedNACKsCtr = []
        %Counter of missed ACK bits (MATLAB case).
        MissedACKsMATLABCtr = []
        %Counter of missed ACK bits (SRS case).
        MissedACKsSRSCtr = []
        %Counter of false ACK bits (MATLAB case).
        FalseACKsMATLABCtr = []
        %Counter of false ACK bits (SRS case).
        FalseACKsSRSCtr = []
    end % of properties (SetAccess = private)

    properties (Dependent)
        %UCI block error rate (for PUCCH F2/F3, MATLAB case).
        BlockErrorRateMATLAB
        %UCI block error rate (for PUCCH F2/F3, SRS case).
        BlockErrorRateSRS
        %False detection rate of UCI blocks (for PUCCH F2/F3, MATLAB case).
        FalseDetectionRateMATLAB
        %False detection rate of UCI blocks (for PUCCH F2/F3, SRS case).
        FalseDetectionRateSRS
        %False ACK detection rate (for PUCCH F1, MATLAB case).
        %   Probability of detecting an ACK when the input is only noise (or DTX).
        FalseACKDetectionRateMATLAB
        %False ACK detection rate (for PUCCH F1, SRS case).
        %   Probability of detecting an ACK when the input is only noise (or DTX).
        FalseACKDetectionRateSRS
        %NACK-to-ACK detection rate (for PUCCH F1, MATLAB case).
        %   Probability of detecting an ACK when a NACK is transmitted.
        NACK2ACKDetectionRateMATLAB
        %NACK-to-ACK detection rate (for PUCCH F1, SRS case).
        %   Probability of detecting an ACK when a NACK is transmitted.
        NACK2ACKDetectionRateSRS
        %ACK Detection rate (for PUCCH F1, MATLAB case).
        %   Probability of detecting an ACK when the ACK is transmitted.
        ACKDetectionRateMATLAB
        %ACK Detection rate (for PUCCH F1, SRS case).
        %   Probability of detecting an ACK when the ACK is transmitted.
        ACKDetectionRateSRS
    end % of properties (Dependable)

    properties (Access = private, Hidden)
        %Carrier configuration.
        Carrier
        %FFT size.
        Nfft
        %PUCCH configuration.
        PUCCH
        %Channel system object.
        Channel
        %Handle to a function for updating MATLAB stats.
        updateStats
        %Handle to a function for updating SRS stats.
        updateStatsSRS
        %Handle to a function for printing MATLAB simulation info.
        printMessages
        %Handle to a function for printing SRS simulation info.
        printMessagesSRS
    end % of properties (Access = private, Hidden)

    properties (Access = private, Dependent, Hidden)
        %Boolean flag test type: true if strcmp(TestType, 'Detection'), false otherwise.
        isDetectionTest
    end % of properties (Access = private, Dependent, Hidden)

    methods (Access = private)

        function checkPUCCHandSymbolAllocation(obj)
            if ((obj.PUCCHFormat == 1) && (obj.SymbolAllocation(2) < 4))
                error('PUCCH Format1 only allows the allocation of a number of OFDM symbols in the range 4-14 - requested %d.', ...
                    obj.SymbolAllocation(2));
            end

            if ((obj.PUCCHFormat == 2) && (obj.SymbolAllocation(2) > 2))
                error('PUCCH Format2 only allows the allocation of 1 or 2 OFDM symbols - requested %d.', obj.SymbolAllocation(2));
            end

            if ((obj.PUCCHFormat == 3) && (obj.SymbolAllocation(2) < 4))
                error('PUCCH Format3 requires the allocation of at least 4 OFDM symbols - requested %d.', obj.SymbolAllocation(2));
            end
        end % of function checkPUCCHandSymbolAll(obj)

        function checkPUCCHandPRBs(obj)
            nPRBs = numel(obj.PRBSet);

            if ((obj.PUCCHFormat == 1) && (nPRBs ~= 1))
                error ('PUCCH Format1 only allows one allocated PRB, given %d.', nPRBs);
            end

            if ((obj.PUCCHFormat == 2) && ((nPRBs < 1) || (nPRBs > 16)))
                error ('PUCCH Format2 requires a number of allocated PRBs between 1 and 16, given %d.', nPRBs);
            end
        end

        function checkPRBSetandGrid(obj)
            if (max(obj.PRBSet) > obj.NSizeGrid - 1)
                error('PRB allocation and resource grid are incompatible.');
            end
        end

        function checkImplementationandChEstPerf(obj)
            if (~strcmp(obj.ImplementationType, 'matlab') && obj.PerfectChannelEstimator)
                error('Perfect channel estimation only works with ImplementationType=''matlab''.');
            end
        end

        function checkImplementationandHopping(obj)
            if (~strcmp(obj.ImplementationType, 'matlab') && ~strcmp(obj.FrequencyHopping, 'neither'))
                error('Intra- or inter-slot frequency hopping only works with ImplementationType=''matlab''.');
            end
        end

        function checkImplementationandFormat(obj)
            if (~strcmp(obj.ImplementationType, 'matlab') && (obj.PUCCHFormat > 2))
                error('PUCCH formats other than Format1 and Format2 only work with ImplementationType=''matlab''.');
            end
        end

        function checkUCIBits(obj)
            totalBits = obj.NumACKBits + obj.NumSRBits + obj.NumCSI1Bits + obj.NumCSI2Bits;

            if (obj.PUCCHFormat == 1)
                if (obj.NumSRBits > 0) || (obj.NumCSI1Bits > 0) || (obj.NumCSI2Bits > 0)
                    error(['For PUCCH Format1, only ACK bits are allowed. '...
                        'Provided SR: %d, CSI Part1: %d, CSI Part2: %d.'], ...
                        obj.NumSRBits, obj.NumCSI1Bits, obj.NumCSI2Bits);
                end
                if obj.NumACKBits > 2
                    error(['For PUCCH Format1, maximum 2 HARQ-ACK bits are allowed. '...
                        'Provided %d.'], obj.NumACKBits);
                end
            end

            if (obj.PUCCHFormat == 2) && ((totalBits < 3) || (totalBits > obj.MaxUCIBits))
                error(['For PUCCH Format2, the total number of UCI bits should be between 3 and 1706. ' ...
                    'Provided %d (HARQ-ACK: %d, SR: %d, CSI Part1: %d, CSI Part2: %d).'], ...
                totalBits, obj.NumACKBits, obj.NumSRBits, obj.NumCSI1Bits, obj.NumCSI2Bits);
            end
        end

    end % of methods (Access = private)

    methods % public

        function set.SymbolAllocation(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'size', [1, 2], '>=', 0, '<=', 14});
            if (value(2) == 0)
                error('At least one OFDM should be allocated for PUCCH transmission.');
            end
            if (value(1) + value(2) > 14)
                error('Cannot allocate %d OFDM symbols starting from OFDM symbol %d.', value(2), value(1));
            end
            obj.SymbolAllocation = value;
        end

        function set.PRBSet(obj, value)
            validateattributes(value, 'numeric', {'real', 'integer', 'vector', 'nonempty', ...
                '>=', 0, '<=', 274});
            if any(value(2:end) - value(1:end-1) ~= 1)
                error('The PRB allocation set should be contiguous.');
            end
            obj.PRBSet = value;
        end

        function isDT = get.isDetectionTest(obj)
            isDT = strcmp(obj.TestType, 'Detection');
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

        function fdr = get.FalseACKDetectionRateMATLAB(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseACKDetectionRateMATLAB property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end
            fdr = obj.FalseACKsMATLABCtr ./ obj.TransmittedNACKsCtr;
        end

        function fdr = get.FalseACKDetectionRateSRS(obj)
            if obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The FalseACKDetectionRateSRS property is inactive when TestType == ''Detection''.');
                warning('on', 'backtrace');
                fdr = [];
                return
            end
            fdr = obj.FalseACKsSRSCtr ./ obj.TransmittedNACKsCtr;
        end

        function n2a = get.NACK2ACKDetectionRateMATLAB(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The NACK2ACKDetectionRateMATLAB property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                n2a = [];
                return
            end
            n2a = obj.FalseACKsMATLABCtr ./ obj.TransmittedNACKsCtr;
        end

        function n2a = get.NACK2ACKDetectionRateSRS(obj)
            if ~obj.isDetectionTest
                warning('off', 'backtrace');
                warning('The NACK2ACKDetectionRateSRS property is inactive when TestType == ''False Alarm''.');
                warning('on', 'backtrace');
                n2a = [];
                return
            end
            n2a = obj.FalseACKsSRSCtr ./ obj.TransmittedNACKsCtr;
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

        function plot(obj)
        %Display the measured throughput and BLER.

            if (isempty(obj.SNRrange))
                warning('Empty simulation data.');
                return;
            end

            if (obj.PUCCHFormat == 1)
                plotF1(obj);
            else
                plotF2(obj);
            end

        end % of function plot()

    end % of methods public

    methods (Access = protected)

        % Signatures of methods defined in dedicated files.
        setupImpl(obj)
        stepImpl(obj, SNRIn, nFrames)

        function validatePropertiesImpl(obj)
            obj.checkPUCCHandSymbolAllocation();
            obj.checkPUCCHandPRBs();
            obj.checkPRBSetandGrid();
            obj.checkImplementationandChEstPerf();
            obj.checkUCIBits();
            obj.checkImplementationandHopping();
            obj.checkImplementationandFormat();
        end % of function validatePropertiesImpl(obj)

        function resetImpl(obj)
            % Reset internal system objects.
            reset(obj.Channel);

            % Reset simulation results.
            obj.SNRrange = [];
            obj.TotalBlocksCtr = [];
            obj.MissedBlocksMATLABCtr = [];
            obj.MissedBlocksSRSCtr = [];
            obj.FalseBlocksMATLABCtr = [];
            obj.FalseBlocksSRSCtr = [];
            obj.TransmittedACKsCtr = [];
            obj.TransmittedNACKsCtr = [];
            obj.MissedACKsMATLABCtr = [];
            obj.MissedACKsSRSCtr = [];
            obj.FalseACKsMATLABCtr = [];
            obj.FalseACKsSRSCtr = [];
        end % of function resetImpl(obj)

        function releaseImpl(obj)
            obj.resetImpl();
            % Release internal system objects.
            release(obj.Channel);
        end % of function releaseImpl(obj)

        function flag = isInactivePropertyImpl(obj, property)
            isFormat1 = (obj.PUCCHFormat == 1);
            switch property
                case 'DelaySpread'
                    flag = strcmp(obj.DelayProfile, 'AWGN') || strcmp(obj.DelayProfile, 'TDLC300');
                case 'MaximumDopplerShift'
                    flag = strcmp(obj.DelayProfile, 'AWGN');
                case 'Modulation'
                    flag = ((obj.PUCCHFormat == 1) || (obj.PUCCHFormat == 2));
                case {'SNRrange', 'TotalBlocksCtr'}
                    flag = isempty(obj.SNRrange);
                case 'MissedBlocksMATLABCtr'
                    flag = isempty(obj.SNRrange) || isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case 'MissedBlocksSRSCtr'
                    flag = isempty(obj.SNRrange) || isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                case 'BlockErrorRateMATLAB'
                    flag = isempty(obj.MissedBlocksMATLABCtr) || isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case 'BlockErrorRateSRS'
                    flag = isempty(obj.MissedBlocksSRSCtr) || isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                case 'FalseBlocksMATLABCtr'
                    flag = isempty(obj.SNRrange) || isFormat1 || obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case 'FalseBlocksSRSCtr'
                    flag = isempty(obj.SNRrange) || isFormat1 || obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                case 'FalseDetectionRateMATLAB'
                    flag = isempty(obj.SNRrange) || isFormat1 || obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case 'FalseDetectionRateSRS'
                    flag = isempty(obj.SNRrange) || isFormat1 || obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                case 'TransmittedACKsCtr'
                    flag = isempty(obj.SNRrange) || ~isFormat1 || ~obj.isDetectionTest;
                case 'TransmittedNACKsCtr'
                    flag = isempty(obj.SNRrange) || ~isFormat1;
                case 'NACK2ACKDetectionRateMATLAB'
                    flag = isempty(obj.SNRrange) || ~isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case {'MissedACKsMATLABCtr', 'ACKDetectionRateMATLAB'}
                    flag = isempty(obj.SNRrange) || ~isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case {'FalseACKsMATLABCtr', 'FalseACKDetectionRateMATLAB'}
                    flag = isempty(obj.SNRrange) || ~isFormat1 || obj.isDetectionTest || strcmp(obj.ImplementationType, 'srs');
                case 'NACK2ACKDetectionRateSRS'
                    flag = isempty(obj.SNRrange) || ~isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                case {'MissedACKsSRSCtr', 'ACKDetectionRateSRS'}
                    flag = isempty(obj.SNRrange) || ~isFormat1 || ~obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                case {'FalseACKsSRSCtr', 'FalseACKDetectionRateSRS'}
                    flag = isempty(obj.SNRrange) || ~isFormat1 || obj.isDetectionTest || strcmp(obj.ImplementationType, 'matlab');
                otherwise
                    flag = false;
            end
        end % of function flag = isInactivePropertyImpl(obj, property)

        function groups = getPropertyGroups(obj)

            confProps = {...
                ... Generic.
                'NCellID', 'RNTI', ...
                ... Resource grid.
                'SubcarrierSpacing', 'NSizeGrid', ...
                ... PUCCH.
                'PUCCHFormat', 'PRBSet', 'SymbolAllocation', 'Modulation', 'FrequencyHopping', ...
                'NumACKBits', 'NumSRBits', 'NumCSI1Bits', 'NumCSI2Bits', ...
                ... Antennas and layers.
                'NRxAnts', 'NTxAnts', ...
                ... Channel model.
                'DelayProfile', 'DelaySpread', 'MaximumDopplerShift', 'PerfectChannelEstimator', ...
                ... Other simulation details.
                'ImplementationType', 'TestType', 'QuickSimulation', 'DisplaySimulationInformation'};
            groups = matlab.mixin.util.PropertyGroup(confProps, 'Configuration');

            results = {'SNRrange', 'TotalBlocksCtr', 'MissedBlocksMATLABCtr', 'MissedBlocksSRSCtr', ...
                'BlockErrorRateMATLAB', 'BlockErrorRateSRS', 'FalseBlocksMATLABCtr', 'FalseBlocksSRSCtr', ...
                'FalseDetectionRateMATLAB', 'FalseDetectionRateSRS', 'TransmittedACKsCtr', ...
                'TransmittedNACKsCtr', 'MissedACKsMATLABCtr', 'FalseACKsMATLABCtr', ...
                'MissedACKsSRSCtr', 'FalseACKsSRSCtr', ...
                'FalseACKDetectionRateMATLAB', 'NACK2ACKDetectionRateMATLAB', 'ACKDetectionRateMATLAB', ...
                'FalseACKDetectionRateSRS', 'NACK2ACKDetectionRateSRS', 'ACKDetectionRateSRS'};
            resProps = {};
            for i = 1:numel(results)
                tt = results{i};
                if ~isInactivePropertyImpl(obj, tt)
                    resProps = [resProps, tt]; %#ok<AGROW>
                end
            end
            if ~isempty(resProps)
                groups = [groups, matlab.mixin.util.PropertyGroup(resProps, 'Simulation Results')];
            end
        end % of function groups = getPropertyGroups(obj)

        function s = saveObjectImpl(obj)
            % Save all public properties.
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                % Save child objects.
                s.Carrier = obj.Carrier;
                s.PUCCH = obj.PUCCH;
                s.Channel = matlab.System.saveObject(obj.Channel);

                % Save FFT size.
                s.Nfft = obj.Nfft;

                % Save handlers to helper functions.
                s.updateStats = obj.updateStats;
                s.updateStatsSRS = obj.updateStatsSRS;
                s.printMessages = obj.printMessages;
                s.printMessagesSRS = obj.printMessagesSRS;

                % Save counters.
                s.SNRrange = obj.SNRrange;
                s.TotalBlocksCtr = obj.TotalBlocksCtr;
                s.MissedBlocksMATLABCtr = obj.MissedBlocksMATLABCtr;
                s.MissedBlocksSRSCtr = obj.MissedBlocksSRSCtr;
                s.FalseBlocksMATLABCtr = obj.FalseBlocksMATLABCtr;
                s.FalseBlocksSRSCtr = obj.FalseBlocksSRSCtr;
                s.TransmittedACKsCtr = obj.TransmittedACKsCtr;
                s.TransmittedNACKsCtr = obj.TransmittedNACKsCtr;
                s.MissedACKsMATLABCtr = obj.MissedACKsMATLABCtr;
                s.FalseACKsMATLABCtr = obj.FalseACKsMATLABCtr;
                s.MissedACKsSRSCtr = obj.MissedACKsSRSCtr;
                s.FalseACKsSRSCtr = obj.FalseACKsSRSCtr;
            end
        end % of function s = saveObjectImpl(obj)

        function loadObjectImpl(obj, s, wasInUse)
            if wasInUse
                % Load child objects.
                obj.Carrier = s.Carrier;
                obj.PUCCH = s.PUCCH;
                obj.Channel = matlab.System.loadObject(s.Channel);

                % Load FFT size.
                obj.Nfft = s.Nfft;

                % Load handlers to helper functions.
                obj.updateStats = s.updateStats;
                obj.updateStatsSRS = s.updateStatsSRS;
                obj.printMessages = s.printMessages;
                obj.printMessagesSRS = s.printMessagesSRS;

                % Load counters.
                obj.SNRrange = s.SNRrange;
                obj.TotalBlocksCtr = s.TotalBlocksCtr;
                obj.MissedBlocksMATLABCtr = s.MissedBlocksMATLABCtr;
                obj.MissedBlocksSRSCtr = s.MissedBlocksSRSCtr;
                obj.FalseBlocksMATLABCtr = s.FalseBlocksMATLABCtr;
                obj.FalseBlocksSRSCtr = s.FalseBlocksSRSCtr;
                obj.TransmittedACKsCtr = s.TransmittedACKsCtr;
                obj.TransmittedNACKsCtr = s.TransmittedNACKsCtr;
                obj.MissedACKsMATLABCtr = s.MissedACKsMATLABCtr;
                obj.FalseACKsMATLABCtr = s.FalseACKsMATLABCtr;
                obj.MissedACKsSRSCtr = s.MissedACKsSRSCtr;
                obj.FalseACKsSRSCtr = s.FalseACKsSRSCtr;
            end

            % Load all public properties.
            loadObjectImpl@matlab.System(obj, s, wasInUse);
        end % function loadObjectImpl(obj, s, wasInUse)

    end % of methods (Access = protected)
end % of classdef PUCCHBLER < matlab.System

% %% Local Functions

function plotF1(obj)
    implementationType = obj.ImplementationType;

    plotMATLAB = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
    plotSRS = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

    titleString = sprintf('PUCCH F%d / SCS=%dkHz / %d ACK bits', obj.PUCCHFormat, ...
        obj.SubcarrierSpacing, obj.NumACKBits);
    legendstrings = {};

    figure;
    set(gca, "YScale", "log")
    if plotMATLAB
        semilogy(obj.SNRrange, obj.FalseACKsMATLABCtr ./ obj.TransmittedNACKsCtr, 'o-.', ...
            'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
        if obj.isDetectionTest
            legendstrings{end + 1} = 'MATLAB - NACK to ACK';

            hold on;
            semilogy(obj.SNRrange, obj.MissedACKsMATLABCtr ./ obj.TransmittedACKsCtr, 'square:', ...
                'LineWidth', 1, 'Color', [0 0.4470 0.7410]);
            legendstrings{end + 1} = 'MATLAB - Missed ACK';
            hold off;
        else
            legendstrings{end + 1} = 'MATLAB - False ACK';
        end
    end

    if plotSRS
        hold on;
        semilogy(obj.SNRrange, obj.FalseACKsSRSCtr ./ obj.TransmittedNACKsCtr, 'o-.', ...
            'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
        if obj.isDetectionTest
            legendstrings{end + 1} = 'SRS - NACK to ACK';

            semilogy(obj.SNRrange, obj.MissedACKsSRSCtr ./ obj.TransmittedACKsCtr, 'square:', ...
                'LineWidth', 1, 'Color', [0.8500 0.3250 0.0980]);
            legendstrings{end + 1} = 'SRS - Missed ACK';
        else
            legendstrings{end + 1} = 'SRS - False ACK';
        end
        hold off;
    end

    xlabel('SNR (dB)'); ylabel('Probability'); grid on; legend(legendstrings);
    title(titleString);
end

function plotF2(obj)
    implementationType = obj.ImplementationType;

    plotMATLAB = (strcmp(implementationType, 'matlab') || strcmp(implementationType, 'both'));
    plotSRS = (strcmp(implementationType, 'srs') || strcmp(implementationType, 'both'));

    titleString = sprintf('PUCCH F%d / SCS=%dkHz / %d UCI bits', obj.PUCCHFormat, ...
        obj.SubcarrierSpacing, obj.NumACKBits + obj.NumSRBits + obj.NumCSI1Bits + obj.NumCSI2Bits);
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
end
