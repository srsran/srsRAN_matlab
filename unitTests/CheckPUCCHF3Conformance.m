%CheckPUCCHF3Conformance Battery of conformance tests for the PUCCH Format 3.
%   This class, based on the matlab.unittest.TestCase framework, performs a battery
%   of conformance tests on the PUCCH Format 3. Specifically, the tests are a
%   subset of those described in TS38.104 Section 8.3.5 and TS38.141 Section 8.3.4.
%   The tests consist in running a short simulation and ensuring that the decoder
%   block error rate meets its target value.
%
%   CheckPUCCHF3Conformance Properties (Constant):
%
%   NSlots  - Number of simulated slots.
%
%   CheckPUCCHF3Conformance Properties (TestParameter):
%
%   TestConfig  - PUCCH Format 3 test configurations.
%
%   CheckPUCCHF3Conformance Methods (Test, TestTags = {'conformance'}):
%
%   checkPUCCHF3BLER             - Estimates the UCI block error rate for the given
%                                  PUCCH Format 3 configuration.
%
%   Example
%      runtests('CheckPUCCHF3Conformance')
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

classdef CheckPUCCHF3Conformance < matlab.unittest.TestCase
    properties (Constant, Hidden)
        %Folder for storing the test results in csv format.
        OutputFolder = 'conformanceResults'
        %File for storing the results in csv format.
        OutputFile = fullfile(pwd, CheckPUCCHF3Conformance.OutputFolder, ['conformancePUCCHF3', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss')), '.csv'])
    end % of properties (Constant, Hidden)

    properties (Constant)
        %Number of simulated slots.
        NSlots = 20000;
    end % of properties (Constant)

    properties (TestParameter)
        %PUCCH Format 3 test configurations.
        %   Defines, for each test, the subcarrier spacing, test number, number of receive antennas,
        %   DM-RS configuration, bandwidth, and target SNR.
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
        function checkPUCCHF3BLER(obj, TestConfig)
            %Estimates the UCI block error rate for the given PUCCH Format 3 configuration.
            %   The UCI BLER is defined as the probability of incorrectly decoding the UCI
            %   information, assuming it is sent. The payload is of 16 UCI bits, with no CSI Part 2.
            %   For more information, see TS38.104 Section 8.3.5 and TS38.141 Section 8.3.4.

            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.assumeLessThanOrEqual(TestConfig.NRxAnts, 4, ...
                'Configurations with more than 4 Rx antennas are not supported yet.');

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));
            pp = obj.preparePUCCH(TestConfig);

            mu = TestConfig.SubcarrierSpacing / 15 - 1;
            nFrames = obj.NSlots / 10 / 2^mu;
            try
                pp(TestConfig.SNR, nFrames);
            catch ME
                obj.assertFail(['PUCCHPERF simulation failed with error: ', ME.message]);
            end

            % Export UCI BLER in csv format to be imported in grafana.
            writecsv(obj, TestConfig, 'UCI BLER', pp.Statistics.BlockErrorRateSRS);

            obj.verifyLessThanOrEqual(pp.Statistics.BlockErrorRateSRS, 0.01, ...
                'WARNING: The PUCCH F3 UCI BLER should not be higher than 1%.');
            obj.assertLessThanOrEqual(pp.Statistics.BlockErrorRateSRS, 0.05, ...
                'ERROR: The PUCCH F3 UCI BLER is above the hard acceptance threshold of 5%.');
        end % of function checkPUCCHF3BLER(obj, TestConfig)

    end % of methods (Test, TestTags = {'conformance'})

    methods (Access = private)
        function pp = preparePUCCH(obj, TestConfig)
            %Configures a PUCCHPERF object for a UCI of 16 bits.

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

            pp.PUCCHFormat = 3;
            pp.SubcarrierSpacing = TestConfig.SubcarrierSpacing;
            pp.NSizeGrid = TestConfig.NSizeGrid;
            if TestConfig.Test == 1
                % Test 1.
                pp.PRBSet = 0;                  % 1st PRB (before FH) 0 / 1 PRB
                pp.SymbolAllocation = [0 14];   % 1st symbol 0 / 14 symbols
            else
                % Test 2.
                pp.PRBSet = 0:2;                % 1st PRB (before FH) 0 / 3 PRBs
                pp.SymbolAllocation = [0 4];    % 1st symbol 0 / 4 symbols
            end
            pp.FrequencyHopping = 'intraSlot';
            % The PUCCHPERF object takes care of picking the last PRBs in the second hop.
            pp.NumACKBits = 16;
            pp.NRxAnts = TestConfig.NRxAnts;
            pp.DelayProfile = 'TDLC300';
            pp.MaximumDopplerShift = 100;
            pp.ImplementationType = 'srs';
            pp.PerfectChannelEstimator = false;
            pp.QuickSimulation = false;
            pp.DisplaySimulationInformation = true;
            pp.Modulation = 'QPSK';
            pp.AdditionalDMRS = TestConfig.AdditionalDMRS;
        end % of function pp = preparePUCCH(obj, TestConfig)

        function writecsv(obj, config, metric, prob)
            %Writes the test entry in the csv file.
            if config.AdditionalDMRS
                AdditionalDMRSStr = '+DM-RS On';
            else
                AdditionalDMRSStr = '+DM-RS Off';
            end

            casename = sprintf('%s / Test %d / %d Ant / %d PRB / %s', config.Table, ...
                config.Test, config.NRxAnts, config.NSizeGrid, AdditionalDMRSStr);

            fff = fopen(obj.OutputFile, 'a');
            currTime = getenv("CI_PIPELINE_CREATED_AT");
            if isempty(currTime)
                currTime = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
            end
            fprintf(fff, '%s,matlab/PUCCH F3 conformance,%s,%.6f,%s\n', metric, casename, prob, currTime);

            fclose(fff);
        end % of function writecsv(obj)
    end % of methods (Access = private)
end % of classdef CheckPUCCHF3Conformance < matlab.unittest.TestCase

function TestConfig = generateTestConfig()
TestConfig = { ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               0.2 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               1.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               0.3 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -0.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               0.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -0.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -3.8 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               -3.3 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -3.8 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -4.3 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               -4.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -4.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -7.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               -6.7 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -6.9 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -7.7 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               -7.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -7.7 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               1.4 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               2.2 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               2.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -3.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               -2.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -2.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         25, ... 5 MHz ...
        'SNR',               -6.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         52, ... 10 MHz ...
        'SNR',               -6.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-1', ...
        'SubcarrierSpacing', 15, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 20 MHz ...
        'SNR',               -6.2 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               0.9 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               0.6 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               0.6 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               0.9 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               0.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               0.3 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               0.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               0.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               -3.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               -3.4 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               -3.2 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               -3.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               -3.7 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               -4.1 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               -4.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               -4.2 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               -6.6 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               -6.7 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               -6.8 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               -6.8 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               -7.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               -7.6 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               -7.6 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              1, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    true, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               -7.7 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               1.8 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               2.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               2.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           2, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               1.5 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               -2.9 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               -3.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               -2.4 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           4, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               -3.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         24, ... 10 MHz ...
        'SNR',               -6.4 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         51, ... 20 MHz ...
        'SNR',               -6.0 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         106, ... 40 MHz ...
        'SNR',               -6.4 ...
    ), ...
    struct( ...
        'Table',             'TS38.104 V15.19.0 Table 8.3.5.2-2', ...
        'SubcarrierSpacing', 30, ...
        'Test',              2, ...
        'NRxAnts',           8, ...
        'AdditionalDMRS',    false, ...
        'NSizeGrid',         273, ... 100 MHz ...
        'SNR',               -6.2 ...
    ), ...
    };
end
