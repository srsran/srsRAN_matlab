%CheckSimulators Unit tests for the SRS link-level simulators.
%   This class, based on the matlab.unittest.TestCase framework, performs basic
%   tests on the simulators in 'apps/simulators'. In few words, it checks whether
%   a simulator object can be created, if it is of the correct type and it runs
%   a very short simulation.
%
%   CheckSimulators Methods (Test, TestTags = {'matlab code'}):
%
%   testPUSCHBLERmatlab  - Verifies the PUSCHBLER simulator class using MATLAB objects only.
%   testPRACHPERFmatlab  - Verifies the PRACHPERF simulator class using MATLAB objects only.
%
%   CheckSimulators Methods (Test, TestTags = {'mex code'}):
%
%   testPUSCHBLERmex  - Verifies the PUSCHBLER simulator class also using MEX implementations.
%
%   Example
%      runtests('CheckSimulators')
%
%   See also matlab.unittest.

%   Copyright 2021-2023 Software Radio Systems Limited
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

            obj.assertEqual(pp.SNRrange, snrs, 'Wrong SNR range.');
            obj.assertEqual(pp.TBS, 1800, 'Wrong transport block size.');
            obj.assertEqual(pp.MaxThroughput, 1.8, 'Wrong maximum throughput.');
            obj.assertEqual(pp.ThroughputMATLAB, [0; 0; 0.0178; 0.1636; 0.5755], "Wrong througuput curve.", RelTol=0.02);
            obj.assertEqual(pp.BlockErrorRateMATLAB, [1; 1; 0.9901; 0.9091; 0.6803], "Wrong BLER curve.", RelTol=0.02);
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
            obj.assertEqual(pp.OffsetError, [0.2127 0.2461], 'Wrong offset error.', RelTol=0.02);

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
    end % of methods (Test, TestTags = {'matlab code'})

    methods (Test, TestTags = {'mex code'})
        function testPUSCHBLERmex(obj)
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

            pp.DecoderType = 'srs';
            snrs = -5.6:0.2:-4.8;
            try
                pp(snrs, 100)
            catch ME
                obj.assertFail(['PUSCHBLER could not run because of exception: ', ...
                    ME.message]);
            end

            obj.assertEqual(pp.SNRrange, snrs, 'Wrong SNR range.');
            obj.assertEqual(pp.TBS, 1800, 'Wrong transport block size.');
            obj.assertEqual(pp.MaxThroughput, 1.8, 'Wrong maximum throughput.');
            obj.assertEqual(pp.ThroughputSRS, [0; 0; 0.0178; 0.2874; 0.9304], "Wrong througuput curve.", RelTol=0.02);
            obj.assertEqual(pp.BlockErrorRateSRS, [1; 1; 0.9901; 0.8403; 0.4831], "Wrong BLER curve.", RelTol=0.02);
        end % of function testPUSCHBLERmex(obj)
    end % of methods (Test, TestTags = {'mex code'})
end % of classdef CheckSimulators < matlab.unittest.TestCase
