%PUCCHPERF PUCCH performance simulator.
%   PUCCHSIM = PUCCHPERF creates a PUCCH simulator object, PUCCHSIM. This object
%   simulates a PUCCH transmission according to the specified setup (see list of
%   PUCCHPERF properties below) and measures the detection probability or the
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
%   a PUCCHPERF object implies resetting the simulation results.
%
%   Note: PUCCHPERF objects can be saved and loaded normally as all MATLAB objects.
%   Saving an unlocked object only stores the simulation configuration. Saving
%   a locked object also stores all simulation results so that the simulation
%   can be resumed after loading the object.
%
%   PUCCHPERF methods:
%
%   step        - Runs a PUCCH simulation (see above).
%   release     - Allows property value changes (implies reset).
%   clone       - Creates PUCCHPERF object with same property values.
%   isLocked    - Locked status (logical).
%   reset       - Resets simulated data.
%   plot        - Plots detection/BLER curves (if simulated data are present).
%
%   PUCCHPERF properties (all nontunable, unless otherwise specified):
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
%   PUCCHFormat                  - PUCCH format (0, 1, 2, 3).
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
%   Counters    - Raw simulation data (e.g., SNR values or number of simulated transmissions).
%   Statistics  - Derived simulation statistics (e.g., correct detection rate or BLER).
%
%
%   Remark: The simulation loop is heavily based on the <a href="https://www.mathworks.com/help/5g/ug/nr-pucch-block-error-rate.html">NR PUCCH Block Error Rate</a> MATLAB example by MathWorks.

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

classdef PUCCHPERF < matlab.System
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
        %PUCCH Format (0, 1, 2, 3).
        PUCCHFormat double {mustBeInteger, mustBeInRange(PUCCHFormat, 0, 3)} = 2
        %Frequency hopping ('intraSlot', 'interSlot', 'neither')
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

    properties (Dependent)
        %Raw simulation data (e.g., SNR values or number of simulated transmissions).
        Counters
        %Derived simulation statistics (e.g., correct detection rate or BLER).
        Statistics
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
        %Format-specific metrics and functions.
        FormatDetails
    end % of properties (Access = private, Hidden)

    properties (Access = private, Dependent, Hidden)
        %Boolean flag test type: true if strcmp(TestType, 'Detection'), false otherwise.
        isDetectionTest
    end % of properties (Access = private, Dependent, Hidden)

    methods (Access = private)

        function checkPUCCHandSymbolAllocation(obj)
            obj.FormatDetails.checkSymbolAllocation(obj.SymbolAllocation);
        end % of function checkPUCCHandSymbolAll(obj)

        function checkPUCCHandPRBs(obj)
            nPRBs = numel(obj.PRBSet);
            obj.FormatDetails.checkPRBs(nPRBs);
        end

        function checkPRBSetandGrid(obj)
            if (max(obj.PRBSet) > obj.NSizeGrid - 1)
                error('PRB allocation and resource grid are incompatible.');
            end
        end

        function checkImplementationandChEstPerf(obj)
            if (obj.PUCCHFormat == 0)
                return;
            end
            if (~strcmp(obj.ImplementationType, 'matlab') && obj.PerfectChannelEstimator)
                error('Perfect channel estimation only works with ImplementationType=''matlab''.');
            end
        end

        function checkImplementationandHopping(obj)
            if (~strcmp(obj.ImplementationType, 'matlab') && strcmp(obj.FrequencyHopping, 'interSlot'))
                error('Inter-slot frequency hopping only works with ImplementationType=''matlab''.');
            end
        end

        function checkImplementationandFormat(obj)
            if (~strcmp(obj.ImplementationType, 'matlab') && (obj.PUCCHFormat > 2))
                error('PUCCH formats other than Format0, Format1 and Format2 only work with ImplementationType=''matlab''.');
            end
        end

        function checkUCIBits(obj)
            obj.FormatDetails.checkUCIBits(obj.NumACKBits, obj.NumSRBits, obj.NumCSI1Bits, obj.NumCSI2Bits);
        end

        function checkFormatandTestType(obj)
            totalBits = obj.NumACKBits + obj.NumSRBits + obj.NumCSI1Bits + obj.NumCSI2Bits;
            if ((obj.PUCCHFormat == 2) && (totalBits > 11) && strcmp(obj.TestType, 'False Alarm'))
                error('False alarm tests for PUCCH Format2 do not support more than 11 UCI bits, provided %d.', totalBits);
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

        function counts = get.Counters(obj)
            counts = obj.FormatDetails.getCounters(obj.ImplementationType);
        end

        function stats = get.Statistics(obj)
            stats = obj.FormatDetails.getStatistics(obj.ImplementationType);
        end

        function plot(obj)
            obj.FormatDetails.plot(obj.ImplementationType, obj.SubcarrierSpacing);
        end

    end % of methods public

    methods (Access = protected)

        % Signatures of methods defined in dedicated files.
        setupImpl(obj)
        stepImpl(obj, SNRIn, nFrames)

        function validatePropertiesImpl(obj)
            obj.checkPRBSetandGrid();
            obj.checkImplementationandChEstPerf();
            obj.checkImplementationandHopping();
            obj.checkImplementationandFormat();
            obj.checkFormatandTestType();
        end % of function validatePropertiesImpl(obj)

        function resetImpl(obj)
            % Reset internal system objects.
            reset(obj.Channel);

            % Reset simulation results.
            obj.FormatDetails.reset()
        end % of function resetImpl(obj)

        function releaseImpl(obj)
            obj.resetImpl();
            % Release internal system objects.
            release(obj.Channel);
            % Release the format details.
            obj.FormatDetails = [];
        end % of function releaseImpl(obj)

        function flag = isInactivePropertyImpl(obj, property)
            switch property
                case 'DelaySpread'
                    flag = strcmp(obj.DelayProfile, 'AWGN') || strcmp(obj.DelayProfile, 'TDLC300');
                case 'MaximumDopplerShift'
                    flag = strcmp(obj.DelayProfile, 'AWGN');
                case 'Modulation'
                    flag = (obj.PUCCHFormat ~= 3);
                case 'TestType'
                    flag = (obj.PUCCHFormat >= 3);
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

            if (~isempty(obj.FormatDetails) && obj.FormatDetails.hasresults())
                groups = [groups, matlab.mixin.util.PropertyGroup({'Counters', 'Statistics'}, 'Simulation Results')];
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
                s.FormatDetails = obj.FormatDetails;

                % Save FFT size.
                s.Nfft = obj.Nfft;
            end
        end % of function s = saveObjectImpl(obj)

        function loadObjectImpl(obj, s, wasInUse)
            if wasInUse
                % Load child objects.
                obj.Carrier = s.Carrier;
                obj.PUCCH = s.PUCCH;
                obj.Channel = matlab.System.loadObject(s.Channel);
                obj.FormatDetails = s.FormatDetails;

                % Load FFT size.
                obj.Nfft = s.Nfft;
            end

            % Load all public properties.
            loadObjectImpl@matlab.System(obj, s, wasInUse);
        end % function loadObjectImpl(obj, s, wasInUse)

    end % of methods (Access = protected)
end % of classdef PUCCHPERF < matlab.System

