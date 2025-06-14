%CheckPUCCHF0Conformance Battery of conformance for the PUCCH Format 0.
%   This class, based on the matlab.unittest.TestCase framework, performs a battery
%   of conformance tests on the PUCCH Format 0. Specifically, the tests are a
%   subset of those described in TS38.104 Section 8.3.2 and TS38.141 Section 8.3.1.
%   The tests consist in running a short simulation and ensuring that some metrics
%   (i.e. ACK detection rate or false ACK detection rate, depending on the case)
%   meet their target value.
%
%   CheckPUCCHF0Conformance Properties (TestParameter):
%
%   TestConfig  - PUCCH Format 0 test configurations.
%
%   CheckPUCCHF0Conformance Methods (Test, TestTags = {'conformance'}):
%
%   checkPUCCHF0detection  - Estimates the ACK detection rate for the given
%                            PUCCH Format 0 configuration.
%   checkPUCCHF0falseack   - Estimates the false ACK detection rate for the given
%                            PUCCH Format 0 configuration.
%
%   Example
%      runtests('CheckPUCCHF0Conformance')
%
%   See also matlab.unittest, PUCCHPERF.

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

classdef CheckPUCCHF0Conformance < matlab.unittest.TestCase
    properties (Constant, Hidden)
        %Folder for storing the test results in csv format.
        OutputFolder = 'conformanceResults'
        %File for storing the results in csv format.
        OutputFile = fullfile(pwd, CheckPUCCHF0Conformance.OutputFolder, ['conformancePUCCHF0', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss')), '.csv'])
    end % of properties (Constant, Hidden)

    properties (TestParameter)
        %PUCCH Format 0 test configurations.
        %   Defines, for each test, the bandwidth, the subcarrier spacing, the number
        %   of receive antennas and the target SNR.
        TestConfig = generateTestConfig()
    end % of properties (TestParameter)

    methods (TestClassSetup)
        function preparecsv(obj)
        %Creates a csv file for storing the results of all tests.

            if ~exist(obj.OutputFolder, 'dir')
                mkdir(obj.OutputFolder);
            end
            fff = fopen(obj.OutputFile, 'w');

            % Write file header.
            fprintf(fff, '#datatype measurement,tag,tag,double,dateTime:RFC3339\n');
            fprintf(fff, '#default,,,\n');
            fprintf(fff, 'm,suite,test,value,time\n');

            fclose(fff);
        end % of function preparecsv(obj)
    end % of methods (TestClassSetup)

    methods (Test, TestTags = {'conformance'})
        function checkPUCCHF0detection(obj, TestConfig)
        %Estimates the ACK detection rate for the given PUCCH Format 0 configuration.
        %   The probability of ACK detection is defined as the probability of detecting an
        %   ACK bit when the signal is present. For more information, see TS38.104 Section 8.3.2.1
        %   and TS38.141 Section 8.3.1.1.

            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            pp = obj.preparePUCCH(TestConfig);

            pp.TestType = 'Detection';

            mu = TestConfig.SubcarrierSpacing / 15 - 1;
            nFrames = 2000 / 2^mu;
            try
                pp(TestConfig.SNR, nFrames);
            catch ME
                obj.assertFail(['PUCCHPERF simulation failed with error: ', ME.message]);
            end

            % Export ack-detection probability in csv format to be imported in grafana.
            writecsv(obj, TestConfig, 'ACK detection', pp.Statistics.ACKDetectionRateSRS);

            obj.verifyGreaterThanOrEqual(pp.Statistics.ACKDetectionRateSRS, 0.99, 'WARNING: The PUCCH F0 ACK detection rate should not be lower than 99%.');
            obj.assertGreaterThanOrEqual(pp.Statistics.ACKDetectionRateSRS, 0.95, ...
                'ERROR: The PUCCH F0 ACK detection rate is below the hard acceptance threshold of 95%.');
        end % of function checkPUCCHF0detection(obj, TestConfig)

        function checkPUCCHF0falseack(obj, TestConfig)
        %Estimates the false ACK detection rate for the given PUCCH Format 0 configuration.
        %   The probability of false detection of the ACK is defined as the probability of
        %   erroneous detection of an ACK bit when the input is only noise. For more
        %   information, see TS38.141 Sections 8.3.1.1.

            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            pp = obj.preparePUCCH(TestConfig);

            pp.TestType = 'False Alarm';

            mu = TestConfig.SubcarrierSpacing / 15 - 1;
            nFrames = 2000 / 2^mu;
            try
                pp(TestConfig.SNR, nFrames);
            catch ME
                obj.assertFail(['PUCCHPERF simulation failed with error: ', ME.message]);
            end

            % Export false-ack probability in csv format to be imported in grafana.
            writecsv(obj, TestConfig, 'false ACK', pp.Statistics.FalseACKDetectionRateSRS);

            obj.verifyLessThanOrEqual(pp.Statistics.FalseACKDetectionRateSRS, 0.01, ...
                'WARNING: The PUCCH F0 false ACK detection rate should not be higher than 1%.');
            obj.assertLessThanOrEqual(pp.Statistics.FalseACKDetectionRateSRS, 0.05, ...
                'ERROR: The PUCCH F0 false ACK detection rate is above the hard acceptance threshold of 5%.');
        end % of function checkPUCCHF0falseack(obj, TestConfig)
    end % of methods (Test, TestTags = {'conformance'})

    methods (Access = private)
        function pp = preparePUCCH(obj, TestConfig)
        %Configures a PUCCHPERF object.

            import matlab.unittest.constraints.IsFile

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');

            obj.assertThat('../../../+srsMEX/+phy/@srsPUCCHProcessor/pucch_processor_mex.mexa64', IsFile, ...
                'Could not find PUCCH processor mex executable.');

            pp.PUCCHFormat = 0;
            pp.SubcarrierSpacing = TestConfig.SubcarrierSpacing;
            pp.NSizeGrid = TestConfig.NSizeGrid;
            pp.PRBSet = 0;
            if (TestConfig.NSymbols == 1)
                pp.SymbolAllocation = [13 1];
                pp.FrequencyHopping = 'neither';
            else
                pp.SymbolAllocation = [12 2];
                pp.FrequencyHopping = 'intraSlot';
                % The PUCCHPERF object already uses the last PRB in the band for the second hop.
            end
            pp.NumACKBits = 1;
            pp.NRxAnts = TestConfig.NRxAnts;
            pp.DelayProfile = 'TDLC300';
            pp.MaximumDopplerShift = 100;
            pp.ImplementationType = 'srs';
            pp.QuickSimulation = false;
            pp.DisplaySimulationInformation = true;

        end % of function pp = preparePUCCH(obj, TestConfig)

        function writecsv(obj, config, metric, prob)
        %Writes the test entry in the csv file.

            casename = sprintf('%s / %d Ant / %d Symbol / %d PRB', config.Table, ...
                config.NRxAnts, config.NSymbols, config.NSizeGrid);

            fff = fopen(obj.OutputFile, 'a');
            currTime = getenv("CI_PIPELINE_CREATED_AT");
            if isempty(currTime)
                currTime = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
            end
            fprintf(fff, '%s,matlab/PUCCH F0 conformance,%s,%.6f,%s\n', metric, casename, prob, currTime);

            fclose(fff);
        end % of function writecsv(obj)
    end % of methods (Access = private)
end % of classdef CheckPUCCHF0Conformance < matlab.unittest.TestCase

function TestConfig = generateTestConfig()
    TestConfig = { ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         25, ... 5 MHz ...
            'NSymbols',          1, ...
            'SNR',               9.4 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         52, ... 10 MHz ...
            'NSymbols',          1, ...
            'SNR',               8.8 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         106, ... 20 MHz ...
            'NSymbols',          1, ...
            'SNR',               9.3 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         25, ... 5 MHz ...
            'NSymbols',          2, ...
            'SNR',               2.8 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         52, ... 10 MHz ...
            'NSymbols',          2, ...
            'SNR',               3.7 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         106, ... 20 MHz ...
            'NSymbols',          2, ...
            'SNR',               3.3 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         25, ... 5 MHz ...
            'NSymbols',          1, ...
            'SNR',               3.0 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         52, ... 10 MHz ...
            'NSymbols',          1, ...
            'SNR',               2.9 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         106, ... 20 MHz ...
            'NSymbols',          1, ...
            'SNR',               3.2 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         25, ... 5 MHz ...
            'NSymbols',          2, ...
            'SNR',               -1.0 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         52, ... 10 MHz ...
            'NSymbols',          2, ...
            'SNR',               -0.5 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-1', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 15, ...
            'NSizeGrid',         106, ... 20 MHz ...
            'NSymbols',          2, ...
            'SNR',               -0.8 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         24, ... 10 MHz ...
            'NSymbols',          1, ...
            'SNR',               9.8 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         51, ... 20 MHz ...
            'NSymbols',          1, ...
            'SNR',               9.8 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         106, ... 40 MHz ...
            'NSymbols',          1, ...
            'SNR',               9.5 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         273, ... 100 MHz ...
            'NSymbols',          1, ...
            'SNR',               9.2 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         24, ... 10 MHz ...
            'NSymbols',          2, ...
            'SNR',               4.2 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         51, ... 20 MHz ...
            'NSymbols',          2, ...
            'SNR',               3.6 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         106, ... 40 MHz ...
            'NSymbols',          2, ...
            'SNR',               3.8 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           2, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         273, ... 100 MHz ...
            'NSymbols',          2, ...
            'SNR',               3.5 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         24, ... 10 MHz ...
            'NSymbols',          1, ...
            'SNR',               3.4 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         51, ... 20 MHz ...
            'NSymbols',          1, ...
            'SNR',               3.4 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         106, ... 40 MHz ...
            'NSymbols',          1, ...
            'SNR',               3.0 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         273, ... 100 MHz ...
            'NSymbols',          1, ...
            'SNR',               3.3 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         24, ... 10 MHz ...
            'NSymbols',          2, ...
            'SNR',               -0.3 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         51, ... 20 MHz ...
            'NSymbols',          2, ...
            'SNR',               -0.4 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         106, ... 40 MHz ...
            'NSymbols',          2, ...
            'SNR',               -0.5 ...
        ), ...
        struct( ...
            'Table',             'TS38.104 V15.19.0 Table 8.3.2.2-2', ...
            'NRxAnts',           4, ...
            'SubcarrierSpacing', 30, ...
            'NSizeGrid',         273, ... 100 MHz ...
            'NSymbols',          2, ...
            'SNR',               -0.8 ...
        ), ...
    };
end % of function TestConfig = generateTestConfig()
