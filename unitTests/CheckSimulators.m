%CheckSimulators Unit tests for the SRS link-level simulators.
%   This class, based on the matlab.unittest.TestCase framework, performs basic
%   tests on the simulators in 'apps/simulators'. In few words, it checks whether
%   a simulator object can be created, if it is of the correct type and it runs
%   a very short simulation.
%
%   CheckSimulators Methods (Test, TestTags = {'matlab code'}):
%
%   testPUSCHBLERmatlab   - Verifies the PUSCHBLER simulator class using MATLAB objects only.
%   testPRACHPERFmatlab   - Verifies the PRACHPERF simulator class using MATLAB objects only.
%   testPUCCHPERFF0matlab - Verifies the PUCCHPERF simulator class for PUCCH F0 using MATLAB objects only.
%   testPUCCHPERFF1matlab - Verifies the PUCCHPERF simulator class for PUCCH F1 using MATLAB objects only.
%   testPUCCHPERFF2matlab - Verifies the PUCCHPERF simulator class for PUCCH F2 using MATLAB objects only.
%   testPUCCHPERFF3matlab - Verifies the PUCCHPERF simulator class for PUCCH F3 using MATLAB objects only.
%
%   CheckSimulators Methods (Test, TestTags = {'mex code'}):
%
%   testPUSCHBLERmex   - Verifies the PUSCHBLER simulator class also using MEX implementations.
%   testPUCCHPERFF0mex - Verifies the PUCCHPERF simulator class PUCCH F0 also using MEX implementations.
%   testPUCCHPERFF1mex - Verifies the PUCCHPERF simulator class PUCCH F1 also using MEX implementations.
%   testPUCCHPERFF2mex - Verifies the PUCCHPERF simulator class PUCCH F2 also using MEX implementations.
%   testPUCCHPERFF3mex - Verifies the PUCCHPERF simulator class PUCCH F3 also using MEX implementations.
%
%   Example
%      runtests('CheckSimulators')
%
%   See also matlab.unittest.

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

classdef CheckSimulators < matlab.unittest.TestCase
    properties (TestParameter)
        %Channel estimator implementation type for mex PUSCH tests.
        EstimatorImplPUSCH = {"MEX", "noMEX"}
        %Test type for PUCCH tests.
        PUCCHTestType = {"Detection", "False Alarm"}
    end % of properties (TestParameter)

    methods (TestMethodSetup)
        function resetrandomgenerator(obj)
            % Reset random genenator after storing current state.
            orig = rng('default');
            % Random generator will be restored after the method.
            obj.addTeardown(@rng, orig);
        end % of function resetrandomgenerator(obj)
    end % of methods (TestMethodSetup)

    methods (Test, TestTags = {'matlab code'})
        function testPUSCHBLERmatlab(obj)
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUSCHBLER'));

            try
                pp = PUSCHBLER;
            catch ME
                obj.assertFail(['Could not create a PUSCHBLER object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PUSCHBLER', 'The created object is not a PUSCHBLER object.');

            snrs = -5.6:0.2:-4.8;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUSCHBLER could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.SNRrange, snrs', 'Wrong SNR range.');
            obj.assertEqual(pp.TBS, 1800, 'Wrong transport block size.');
            obj.assertEqual(pp.MaxThroughput, 1.8, 'Wrong maximum throughput.');
            obj.assertEqual(pp.ThroughputMATLAB, [0.6312; 0.6957; 0.7473; 0.7595; 0.7773], "Wrong througuput curve.", RelTol=0.02);
            obj.assertEqual(pp.BlockErrorRateMATLAB, [0.6494; 0.6135; 0.5848; 0.5780; 0.5682], "Wrong BLER curve.", RelTol=0.02);
        end % of function testPUSCHBLERmatlab(obj)

        function testPRACHPERFmatlab(obj)
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PRACHPERF'));

            try
                pp = PRACHPERF;
            catch ME
                obj.assertFail(['Could not create a PRACHPERF object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PRACHPERF', 'The created object is not a PRACHPERF object.');

            snr = -14.2;
            pp.IgnoreCFO = true;

            % Disable verbose PRACH detector warnings.
            prachwarn = warning('query', 'srsran_matlab:srsPRACHdetector');
            warning('off', 'srsran_matlab:srsPRACHdetector');

            % Run detection test.
            try
                pp(snr, 100)
            catch ME
                obj.assertFail(['PRACHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.SNRrange, snr, 'Wrong SNR range.');
            obj.assertEqual(pp.Occasions, 100, 'Wrong number of occasions.');
            obj.assertEqual(pp.Detected, 100, 'Wrong number of detected preambles.');
            obj.assertEqual(pp.DetectedPerfect, 100, 'Wrong number of perfectly detected preambles.');
            obj.assertEqual(pp.ProbabilityDetection, 1, 'Wrong probability of detection.');
            obj.assertEqual(pp.ProbabilityDetectionPerfect, 1, 'Wrong probability of perfect detection.');
            obj.assertEqual(pp.OffsetError, [0.1781 0.2265], 'Wrong offset error.', RelTol=0.02);

            % Run false alarm test.
            pp.release;
            pp.TestType = 'False Alarm';
            try
                pp(snr, 100)
            catch ME
                obj.assertFail(['PRACHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            % Restore verbose PRACH detector warnings.
            warning(prachwarn);

            obj.assertEqual(pp.SNRrange, snr, 'Wrong SNR range.');
            obj.assertEqual(pp.Occasions, 100, 'Wrong number of occasions.');
            obj.assertEqual(pp.Detected, 2, 'Wrong number of detected preambles.', AbsTol=2);
            obj.assertEqual(pp.ProbabilityFalseAlarm, 0.02, 'Wrong probability of detection.', AbsTol=0.02);
        end % of function testPRACHPERFmatlab(obj)

        function testPUCCHPERFF0matlab(obj, PUCCHTestType)
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF/'));

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');

            pp.PUCCHFormat = 0;
            pp.PRBSet = 0;
            pp.SymbolAllocation = [13 1];
            pp.NumACKBits = 1;
            pp.NRxAnts = 2;
            pp.TestType = PUCCHTestType;

            snrs = -15:2:1;
            try
                pp(snrs, 100);
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of excetion: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            if (PUCCHTestType == "Detection")
                obj.assertEqual(pp.Statistics.SRDetectionRateMATLAB, ones(numel(snrs), 1), "Wrong SR detection curve.");
                obj.assertGreaterThanOrEqual(pp.Statistics.ACKDetectionRateMATLAB, ...
                    [0.025; 0.060; 0.090; 0.160; 0.300; 0.440; 0.600; 0.750; 0.870], ...
                    "Wrong ACK detection curve.");
            else
                obj.assertEqual(pp.Statistics.FalseACKDetectionRateMATLAB, 0.02 * ones(numel(snrs), 1), ...
                    "Wrong false ACK detection rate curve.");
            end
        end % of function testPUCCHPERFF0matlab(obj, PUCCHTestType)

        function testPUCCHPERFF1matlab(obj, PUCCHTestType)
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');

            pp.PUCCHFormat = 1;
            pp.PRBSet = 0;
            pp.SymbolAllocation = [0 14];
            pp.NumACKBits = 2;
            pp.NRxAnts = 2;
            pp.FrequencyHopping = 'intraSlot';
            pp.TestType = PUCCHTestType;

            snrs = -32:2:-14;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            if (PUCCHTestType == "Detection")
                obj.assertLessThan(pp.Statistics.NACK2ACKDetectionRateMATLAB, 0.01, "Wrong NACK-to-ACK detection curve.");
                obj.assertEqual(pp.Statistics.ACKDetectionRateMATLAB, [0.0264; 0.0305; 0.0376; 0.0488; 0.0681; 0.1179; 0.1839; 0.2947; 0.4664; 0.6270], ...
                    "Wrong ACK detection rate curve.", RelTol=0.02);
            else
                obj.assertEqual(pp.Statistics.FalseACKDetectionRateMATLAB, 0.0125 * ones(10, 1), "Wrong false ACK detection rate curve.", RelTol=0.04);
            end
        end % of function testPUCCHPERFF1matlab(obj, PUCCHTestType)

        function testPUCCHPERFF2matlab(obj, PUCCHTestType)
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');
            obj.assertEqual(pp.PUCCHFormat, 2, ['The PUCCH Format is set to ' num2str(pp.PUCCHFormat) ' instead of 2.']);

            pp.NRxAnts = 2;
            pp.TestType = PUCCHTestType;

            snrs = -20:2:-4;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            if (PUCCHTestType == "Detection")
                obj.assertEqual(pp.Statistics.BlockErrorRateMATLAB, [0.9804; 0.9615; 0.9434; 0.9174; 0.8547; 0.6849; 0.4673; 0.2519; 0.1431], ...
                    "Wrong BLER curve.", RelTol=0.02);
            else
                obj.assertEqual(pp.Statistics.FalseDetectionRateMATLAB, 0.006 * ones(9, 1), "Wrong false alarm curve.", RelTol=0.02);
            end
        end % of function testPUCCHPERFF2matlab(obj, PUCCHTestType)

        function testPUCCHPERFF3matlab(obj)
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');

            pp.PUCCHFormat = 3;
            pp.PRBSet = 0;
            pp.SymbolAllocation = [0 14];
            pp.Modulation = 'QPSK';
            pp.NumACKBits = 16;
            pp.NRxAnts = 2;
            pp.FrequencyHopping = 'intraSlot';

            snrs = -20:2:-10;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            obj.assertEqual(pp.Statistics.BlockErrorRateMATLAB, [1; 0.9524; 0.8547; 0.6711; 0.4219; 0.2688], ...
                "Wrong BLER curve.", RelTol=0.02);
        end % of function testPUCCHPERFF3matlab(obj)
    end % of methods (Test, TestTags = {'matlab code'})

    methods (Test, TestTags = {'mex code'})
        function testPUSCHBLERmex(obj, EstimatorImplPUSCH)
            import matlab.unittest.fixtures.CurrentFolderFixture
            import matlab.unittest.constraints.IsFile

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUSCHBLER'));

            try
                pp = PUSCHBLER;
            catch ME
                obj.assertFail(['Could not create a PUSCHBLER object because of exception: ', ...
                    ME.message]);
            end

            obj.assertClass(pp, 'PUSCHBLER', 'The created object is not a PUSCHBLER object.');

            obj.assertThat('../../../+srsMEX/+phy/@srsPUSCHDecoder/pusch_decoder_mex.mexa64', IsFile, ...
                'Could not find PUSCH decoder mex executable.');
            obj.assertThat('../../../+srsMEX/+phy/@srsPUSCHDemodulator/pusch_demodulator_mex.mexa64', IsFile, ...
                'Could not find PUSCH demodulator mex executable.');
            obj.assertThat('../../../+srsMEX/+phy/@srsMultiPortChannelEstimator/multiport_channel_estimator_mex.mexa64', IsFile, ...
                'Could not find channel estimator mex executable.');

            pp.QuickSimulation = false;
            pp.ImplementationType = 'srs';
            pp.PerfectChannelEstimator = false;
            pp.SRSEstimatorType = EstimatorImplPUSCH;
            snrs = -5.0:0.2:-4.2;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUSCHBLER could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.SNRrange, snrs', 'Wrong SNR range.');
            obj.assertEqual(pp.TBS, 1800, 'Wrong transport block size.');
            obj.assertEqual(pp.MaxThroughput, 1.8, 'Wrong maximum throughput.');
            obj.assertGreaterThanOrEqual(pp.ThroughputSRS, [0; 0; 0.041; 0.30; 0.70], "Wrong throughput curve.");
            obj.assertLessThanOrEqual(pp.BlockErrorRateSRS, [0.70; 0.70; 0.65; 0.65; 0.62], "Wrong BLER curve.");
        end % of function testPUSCHBLERmex(obj)

        function testPUCCHPERFF0mex(obj, PUCCHTestType)
            import matlab.unittest.fixtures.CurrentFolderFixture
            import matlab.unittest.constraints.IsFile

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF/'));

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
            pp.PRBSet = 0;
            pp.SymbolAllocation = [13 1];
            pp.NumACKBits = 1;
            pp.NRxAnts = 2;
            pp.TestType = PUCCHTestType;
            pp.ImplementationType = 'srs';

            snrs = -15:2:1;
            try
                pp(snrs, 100);
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of excetion: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            if (PUCCHTestType == "Detection")
                obj.assertEqual(pp.Statistics.SRDetectionRateSRS, ones(numel(snrs), 1), "Wrong SR detection curve.");
                obj.assertGreaterThanOrEqual(pp.Statistics.ACKDetectionRateSRS, ...
                    [0.010; 0.030; 0.070; 0.150; 0.250; 0.440; 0.630; 0.775; 0.890], ...
                    "Wrong ACK detection curve.");
            else
                obj.assertLessThanOrEqual(pp.Statistics.FalseACKDetectionRateSRS, 0.008 * ones(numel(snrs), 1), ...
                    "Wrong false ACK detection rate curve.");
            end
        end % of function testPUCCHPERFF0mex(obj, PUCCHTestType)

        function testPUCCHPERFF1mex(obj, PUCCHTestType)
            import matlab.unittest.fixtures.CurrentFolderFixture
            import matlab.unittest.constraints.IsFile

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');

            obj.assertThat('../../../+srsMEX/+phy/@srsPUCCHProcessor/pucch_processor_mex.mexa64', IsFile, ...
                'Could not find PUCCH processor mex executable.');

            pp.PUCCHFormat = 1;
            pp.PRBSet = 0;
            pp.SymbolAllocation = [0 14];
            pp.NumACKBits = 2;
            pp.NRxAnts = 2;
            pp.FrequencyHopping = 'intraSlot';
            pp.TestType = PUCCHTestType;
            pp.ImplementationType = 'srs';
            pp.PerfectChannelEstimator = false;

            snrs = -32:2:-14;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            if (PUCCHTestType == "Detection")
                obj.assertLessThan(pp.Statistics.NACK2ACKDetectionRateSRS, 0.04, "Wrong NACK-to-ACK detection curve.");
                obj.assertGreaterThanOrEqual(pp.Statistics.ACKDetectionRateSRS, ...
                    [0.007; 0.007; 0.013; 0.023; 0.032; 0.075; 0.130; 0.270; 0.430; 0.610], ...
                    "Wrong ACK detection rate curve.");
            else
                obj.assertEqual(pp.Statistics.FalseACKDetectionRateSRS, 0.0075 * ones(10, 1), "Wrong false ACK detection rate curve.", RelTol=0.03);
            end
        end % of function testPUCCHPERFF1mex(obj, PUCCHTestType)

        function testPUCCHPERFF2mex(obj, PUCCHTestType)
            import matlab.unittest.fixtures.CurrentFolderFixture
            import matlab.unittest.constraints.IsFile

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

            try
                pp = PUCCHPERF;
            catch ME
                obj.assertFail(['Could not create a PUCCHPERF object because of exception: ', ...
                ME.message]);
            end

            obj.assertClass(pp, 'PUCCHPERF', 'The created object is not a PUCCHPERF object.');
            obj.assertEqual(pp.PUCCHFormat, 2, ['The PUCCH Format is set to ' num2str(pp.PUCCHFormat) ' instead of 2.']);

            obj.assertThat('../../../+srsMEX/+phy/@srsPUCCHProcessor/pucch_processor_mex.mexa64', IsFile, ...
                'Could not find PUCCH processor mex executable.');

            pp.TestType = PUCCHTestType;
            pp.NRxAnts = 2;
            pp.ImplementationType = 'srs';
            pp.PerfectChannelEstimator = false;

            snrs = -20:2:-4;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            if (PUCCHTestType == "Detection")
                obj.assertLessThanOrEqual(pp.Statistics.BlockErrorRateSRS, ...
                    [0.920; 0.910; 0.890; 0.850; 0.720; 0.600; 0.420; 0.250; 0.160], ...
                    "Wrong BLER curve.");
            else
                obj.assertLessThanOrEqual(pp.Statistics.FalseDetectionRateSRS, 0.008 * ones(9, 1), "Wrong false alarm curve.");
            end
        end % of function testPUCCHPERFF2mex(obj, PUCCHTestType)

        function testPUCCHPERFF3mex(obj)
            import matlab.unittest.fixtures.CurrentFolderFixture
            import matlab.unittest.constraints.IsFile

            obj.applyFixture(CurrentFolderFixture('../apps/simulators/PUCCHPERF'));

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
            pp.PRBSet = 0;
            pp.SymbolAllocation = [0 14];
            pp.Modulation = 'QPSK';
            pp.NumACKBits = 16;
            pp.NRxAnts = 2;
            pp.FrequencyHopping = 'intraSlot';
            pp.ImplementationType = 'srs';
            pp.PerfectChannelEstimator = false;

            snrs = -14:2:-6;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUCCHPERF could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.Counters.SNRrange, snrs', 'Wrong SNR range.');
            obj.assertLessThanOrEqual(pp.Statistics.BlockErrorRateSRS, [1; 0.9434; 0.66; 0.450; 0.290], ...
                "Wrong BLER curve.");
        end % of function testPUCCHPERFF3mex(obj)
    end % of methods (Test, TestTags = {'mex code'})
end % of classdef CheckSimulators < matlab.unittest.TestCase
