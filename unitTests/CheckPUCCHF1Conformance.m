%CheckPUCCHF1Conformance Battery of conformance for the PUCCH Format 1.
%   This class, based on the matlab.unittest.TestCase framework, performs a battery
%   of conformance tests on the PUCCH Format 1. Specifically, the tests are a
%   subset of those described in TS38.104 Section 8.3.3 and TS38.141 Section 8.3.2.
%   The tests consist in running a short simulation and ensuring that some metrics
%   (i.e. ACK detection rate, NACK to ACK detection rate or false ACK detection
%   rate, depending on the case) meet their target value.
%
%   CheckPUCCHF1Conformance Properties (TestParameter):
%
%   TestConfig  - PUCCH Format 1 test configurations.
%
%   CheckPUCCHF1Conformance Methods (Test, TestTags = {'conformance'}):
%
%   checkPUCCHF1detection  - Estimates the ACK detection rate and the NACK-to-ACK
%                            detection rate for the given PUCCH Format 1 configuration.
%   checkPUCCHF1falseack   - Estimates the false ACK detection rate for the given
%                            PUCCH Format 1 configuration.
%
%   Example
%      runtests('CheckPUCCHF1Conformance')
%
%   See also matlab.unittest, PUCCHBLER.

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

classdef CheckPUCCHF1Conformance < matlab.unittest.TestCase
    properties (TestParameter)
        %PUCCH Format 1 test configurations.
        %   Defines, for each test, the bandwidth, the subcarrier spacing, the number
        %   or receive antennas and the target SNR.
        TestConfig = generateTestConfig()
    end % of properties (TestParameter)

    methods (Test, TestTags = {'conformance'})
        function checkPUCCHF1detection(obj, TestConfig)
        %Estimates the ACK detection rate and the NACK-to-ACK detection rate for the
        %   given PUCCH Format 1 configuration.
        %   The probability of ACK detection is defined as the probability of detecting an
        %   ACK bit when the signal is present. For more information, see TS38.104 Section 8.3.3.2
        %   and TS38.141 Section 8.3.2.2.
        %   The probability of NACK-to-ACK detection is the probability of detecting an
        %   ACK bit when an NACK bit was transmitted. For more information, see TS38.104
        %   Section 8.3.3.1 and TS38.141 Section 8.3.2.1.

            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHBLER'));

            pp = obj.preparePUCCH(TestConfig);

            pp.TestType = 'Detection';

            mu = TestConfig.SubcarrierSpacing / 15 - 1;
            nFrames = 20000 / 2^mu;
            try
                pp(TestConfig.SNRsignal, nFrames);
            catch ME
                obj.assertFail(['PUCCHBLER simulation failed with error: ', ME.message]);
            end

            obj.verifyGreaterThanOrEqual(pp.ACKDetectionRateSRS, 0.99, 'The PUCCH F1 ACK detection rate should not be lower than 99%.');
            obj.assertGreaterThanOrEqual(pp.ACKDetectionRateSRS, 0.95, 'The PUCCH F1 ACK detection rate should not be lower than 99%.');

            obj.verifyLessThanOrEqual(pp.NACK2ACKDetectionRateSRS, 0.001, ...
                'The PUCCH F1 NACK-to-ACK detection rate should not be larger than 0.1%.');
            obj.assertLessThanOrEqual(pp.NACK2ACKDetectionRateSRS, 0.005, ...
                'The PUCCH F1 NACK-to-ACK detection rate should not be larger than 0.1%.');

            % TODO: export Detection Rate (and possibly other metrics) to grafana.
        end % of function checkPUCCHF1detection(obj, TestConfig)

        function checkPUCCHF1falseack(obj, TestConfig)
        %Estimates the false ACK detection rate for the given PUCCH Format 1 configuration.
        %   The probability of false detection of the ACK is defined as the probability of
        %   erroneous detection of an ACK bit when the input is only noise. For more
        %   information, see TS38.141 Sections 8.3.2.1 and 8.3.2.2.

            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHBLER'));

            pp = obj.preparePUCCH(TestConfig);

            pp.TestType = 'False Alarm';

            mu = TestConfig.SubcarrierSpacing / 15 - 1;
            nFrames = 2000 / 2^mu;
            try
                pp(TestConfig.SNRnosignal, nFrames);
            catch ME
                obj.assertFail(['PUCCHBLER simulation failed with error: ', ME.message]);
            end

            obj.verifyLessThanOrEqual(pp.FalseACKDetectionRateSRS, 0.01, ...
                'The PUCCH F1 false ACK detection rate should not be higher than 1%.');
            obj.assertLessThanOrEqual(pp.FalseACKDetectionRateSRS, 0.05, ...
                'The PUCCH F1 false ACK detection rate should not be higher than 1%.');

            % TODO: export Detection Rate (and possibly other metrics) to grafana.
        end % of function checkPUCCHF1falseack(obj, TestConfig)
    end % of methods (Test, TestTags = {'conformance'})

    methods (Access = private)
        function pp = preparePUCCH(obj, TestConfig)
        %Configures a PUCCHBLER object.

            import matlab.unittest.constraints.IsFile

            try
                pp = PUCCHBLER;
            catch ME
                obj.assertFail(['Could not create a PUCCHBLER object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PUCCHBLER', 'The created object is not a PUCCHBLER object.');

            obj.assertThat('../../../+srsMEX/+phy/@srsPUCCHProcessor/pucch_processor_mex.mexa64', IsFile, ...
                'Could not find PUCCH processor mex executable.');

            pp.PUCCHFormat = 1;
            pp.SubcarrierSpacing = TestConfig.SubcarrierSpacing;
            pp.NSizeGrid = TestConfig.NSizeGrid;
            pp.PRBSet = 0;
            pp.SymbolAllocation = [0 14];
            pp.NumACKBits = 2;
            pp.NRxAnts = TestConfig.NRxAnts;
            pp.DelayProfile = 'TDLC300';
            pp.MaximumDopplerShift = 100;
            pp.ImplementationType = 'srs';
            pp.PerfectChannelEstimator = false;
            % TODO: enable intra-slot frequency hopping when ready in srsRAN.

        end % of function pp = preparePUCCH(obj, TestConfig)
    end % of methods (Access = private)
end % of classdef CheckPUCCHF1Conformance < matlab.unittest.TestCase

function TestConfig = generateTestConfig()
    TestConfig = { ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         25, ... 5 MHz ...
            'SNRsignal',         -3.8, ... NACK to ACK test ...
            'SNRnosignal',       -5.0 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         25, ... 5 MHz ...
            'SNRsignal',         -8.4, ... NACK to ACK test ...
            'SNRnosignal',       -8.6 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         52, ... 10 MHz ...
            'SNRsignal',         -3.6, ... NACK to ACK test ...
            'SNRnosignal',       -4.4 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         52, ... 10 MHz ...
            'SNRsignal',         -7.6, ... NACK to ACK test ...
            'SNRnosignal',       -8.2 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         106, ... 20 MHz ...
            'SNRsignal',         -3.6, ... NACK to ACK test ...
            'SNRnosignal',       -5.0 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         106, ... 20 MHz ...
            'SNRsignal',         -8.4, ... NACK to ACK test ...
            'SNRnosignal',       -8.5 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         24, ... 10 MHz ...
            'SNRsignal',         -2.8, ... NACK to ACK test ...
            'SNRnosignal',       -3.9 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         24, ... 10 MHz ...
            'SNRsignal',         -8.1, ... NACK to ACK test ...
            'SNRnosignal',       -8.0 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         51, ... 20 MHz ...
            'SNRsignal',         -3.2, ... NACK to ACK test ...
            'SNRnosignal',       -4.4 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         51, ... 20 MHz ...
            'SNRsignal',         -8.3, ... NACK to ACK test ...
            'SNRnosignal',       -8.1 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         106, ... 40 MHz ...
            'SNRsignal',         -3.9, ... NACK to ACK test ...
            'SNRnosignal',       -4.4 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         106, ... 40 MHz ...
            'SNRsignal',         -7.5, ... NACK to ACK test ...
            'SNRnosignal',       -8.4 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         273, ... 100 MHz ...
            'SNRsignal',         -3.5, ... NACK to ACK test ...
            'SNRnosignal',       -4.2 ... missed ACK test ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.3.x.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         273, ... 100 MHz ...
            'SNRsignal',         -8.0, ... NACK to ACK test ...
            'SNRnosignal',       -8.3 ... missed ACK test ...
        ), ...
    };
end % of function TestConfig = generateTestConfig()
