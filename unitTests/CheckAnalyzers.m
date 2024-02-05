%CheckAnalyzers Unit tests for the SRS analyzers.
%   This class, based on the matlab.unittest.TestCase framework, runs some simple
%   tests on the analyzers in 'apps/analyzers'.
%
%   CheckAnalyzers Properties (Constant):
%
%   wd - Path of the directory containing this test.
%
%   CheckAnalyzers Methods (TestClassSetup):
%
%   testSetup  - Common test setup.
%
%   CheckAnalyzers Methods (Test, TestTags = {'matlab code'}):
%
%   checkParserPUSCH    - Checks that the parser for PUSCH logs.
%   checkParserPUCCHF1  - Checks that the parser for PUCCH Format 1 logs.
%   checkParserPUCCHF2  - Checks that the parser for PUCCH Format 2 logs.
%
%   Example
%      runtests('CheckAnalyzers')
%
%   See also matlab.unittest.

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

classdef CheckAnalyzers < matlab.unittest.TestCase
    properties (Constant)
        %Path of the directory containing the test.
        %   Must be set at construction time because the test then changes its
        %   working directory.
        wd = pwd
    end % of properties (Constant)

    methods (TestClassSetup)
        function testSetup(obj)
        %Common test setup.
        %   Changes the working folder to 'apps/analyzers' and silences the warnings
        %   caused by redefining some MATLAB functions.
            import matlab.unittest.fixtures.CurrentFolderFixture

            obj.applyFixture(CurrentFolderFixture('../apps/analyzers'));

            warn = warning('query', 'MATLAB:dispatcher:nameConflict');
            warning('off', 'MATLAB:dispatcher:nameConflict');
            obj.addTeardown(@warning, warn.state, 'MATLAB:dispatcher:nameConflict');
        end % of function testSetup(obj)
    end % of methods (TestClassSetup)

    methods (Test, TestTags = {'matlab code'})
        function checkParserPUSCH(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2023-08-05T16:59:48.857764 [UL-PHY1 ] [D] [   749.9] PUSCH: rnti=0x4601 h_id=3 prb=[4, 271) symb=[0, 14) mod=64QAM rv=0 tbs=24597 crc=OK iter=2.1 snr=30.7dB t=1532.4us', newline, ...
                'rnti=0x4601', newline, ...
                'h_id=3', newline, ...
                'bwp=[0, 273)', newline, ...
                'prb=[4, 271)', newline, ...
                'symb=[0, 14)', newline, ...
                'oack=0', newline, ...
                'ocsi1=0', newline, ...
                'ocsi2=0', newline, ...
                'alpha=0.0', newline, ...
                'betas=[0.0, 0.0, 0.0]', newline, ...
                'mod=64QAM', newline, ...
                'tcr=0.92578125', newline, ...
                'rv=0', newline, ...
                'bg=1', newline, ...
                'new_data=true', newline, ...
                'n_id=1', newline, ...
                'dmrs_mask=00100001000100', newline, ...
                'n_scr_id=1', newline, ...
                'n_scid=false', newline, ...
                'n_cdm_g_wd=2', newline, ...
                'dmrs_type=1', newline, ...
                'lbrm=3168bytes', newline, ...
                'slot=749.9', newline, ...
                'cp=normal', newline, ...
                'nof_layers=1', newline, ...
                'ports=0', newline, ...
                'dc_position={na}', newline, ...
                'crc=OK', newline, ...
                'iter=2.1', newline, ...
                'max_iter=3', newline, ...
                'min_iter=2', newline, ...
                'nof_cb=24', newline, ...
                'snr=30.7dB', newline, ...
                'epre=-8.7dB', newline, ...
                'rsrp=-8.7dB', newline, ...
                't_align=0.0us'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 273};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, pusch, extra] = srsParseLogs;

            % Check the carrier output.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.NCellID, 1, 'Wrong NCellID.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.CyclicPrefix, 'normal', 'Wrong cyclic prefix.');
            obj.assertEqual(carrier.NSizeGrid, 273, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');
            obj.assertEqual(carrier.NSlot, 9, 'Wrong slot number.');
            obj.assertEqual(carrier.NFrame, 749, 'Wrong frame number.');
            obj.assertEqual(carrier.SymbolsPerSlot, 14, 'Wrong number of OFDM symbols per slot.');
            obj.assertEqual(carrier.SlotsPerSubframe, 2, 'Wrong number of slots per subframe.');
            obj.assertEqual(carrier.SlotsPerFrame, 20, 'Wrong number of slots per frame.');

            % Check the pusch output.
            obj.assertClass(pusch, 'nrPUSCHConfig', 'Output "pusch" is not an nrPUSCHConfig object.');
            obj.assertEqual(pusch.NSizeBWP, 273, 'Wrong BWP size.');
            obj.assertEqual(pusch.NStartBWP, 0, 'Wrong BWP start.');
            obj.assertEqual(pusch.Modulation, '64QAM', 'Wrong modulation.');
            obj.assertEqual(pusch.NumLayers, 1, 'Wrong number of layers.');
            obj.assertEqual(pusch.MappingType, 'A', 'Wrong mapping type.');
            obj.assertEqual(pusch.SymbolAllocation, [0 14], 'Wrong OFDM symbol allocation.');
            obj.assertEqual(pusch.PRBSet, 4:270, 'Wrong PRB set.');
            obj.assertEqual(pusch.TransformPrecoding, 0, 'Wrong transform precoding.');
            obj.assertEqual(pusch.TransmissionScheme, 'nonCodebook', 'Wrong transmission scheme.');
            obj.assertEqual(pusch.NumAntennaPorts, 1, 'Wrong number of antenna ports.');
            obj.assertEqual(pusch.TPMI, 0, 'Wrong transmitted precoding matrix indicator.');
            obj.assertEqual(pusch.FrequencyHopping, 'neither', 'Wrong frequency hopping.');
            obj.assertEqual(pusch.SecondHopStartPRB, 1, 'Wrong starting PRB index of second hop.');
            obj.assertEqual(pusch.BetaOffsetACK, 20, 'Wrong beta offset factor of HARQ-ACK.');
            obj.assertEqual(pusch.BetaOffsetCSI1, 6.2500, 'Wrong beta offset factor of CSI part 1.');
            obj.assertEqual(pusch.BetaOffsetCSI2, 6.2500, 'Wrong beta offset factor of CSI part 2.');
            obj.assertEqual(pusch.UCIScaling, 1, 'Wrong UCI scaling factor.');
            obj.assertEqual(pusch.NID, 1, 'Wrong PUSCH scrambling identity.');
            obj.assertEqual(pusch.RNTI, 17921, 'Wrong radio network temporary identifier.');
            obj.assertEqual(pusch.NRAPID, [], 'Wrong random access preamble index.');
            obj.assertEqual(double(pusch.EnablePTRS), 0, 'Wrong enable PT-RS flag.');
            obj.assertEqual(pusch.DMRS.CustomSymbolSet, [2 7 11], 'Wrong DM-RS OFDM symbol locations.');
            obj.assertEqual(pusch.DMRS.DMRSConfigurationType, 1, 'Wrong DM-RS configuration type.');
            obj.assertEqual(pusch.DMRS.NIDNSCID, 1, 'Wrong DM-RS scrambling identities for CP-OFDM.');
            obj.assertEqual(pusch.DMRS.NSCID, 0, 'Wrong DM-RS scrambling initialization for CP-OFDM.');
            obj.assertEqual(pusch.DMRS.NumCDMGroupsWithoutData, 2, 'Wrong number of CDM groups without data.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEqual(fieldnames(extra), {'RV'; 'TargetCodeRate'; 'TransportBlockLength'; 'dcPosition'}, 'Wrong extra field names.');
            obj.assertEqual(extra.RV, 0, 'Wrong redundancy version.');
            obj.assertEqual(extra.TargetCodeRate, 0.92578125, 'Wrong target code rate.');
            obj.assertEqual(extra.TransportBlockLength, 196776, 'Wrong transport block size.');
            obj.assertEmpty(extra.dcPosition, 'Wrong transport block size.');
        end % of function checkParser(obj)

        function checkParserPUCCHF1(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2023-08-05T16:59:49.046269 [UL-PHY2 ] [D] [   768.9] PUCCH: rnti=0x4601 format=1 prb1=0 prb2=na symb=[0, 14) cs=0 occ=0 ack=2 t=60.2us', newline, ...
                'rnti=0x4601', newline, ...
                'format=1', newline, ...
                'bwp=[0, 273)', newline, ...
                'prb1=0', newline, ...
                'prb2=na', newline, ...
                'symb=[0, 14)', newline, ...
                'n_id=1', newline, ...
                'cs=0', newline, ...
                'occ=0', newline, ...
                'slot=768.9', newline, ...
                'cp=normal', newline, ...
                'ports=0', newline, ...
                'status=invalid', newline, ...
                'ack=2', newline, ...
                'detection_metric=0.6', newline, ...
                'epre=-63.9dB', newline, ...
                'rsrp=-82.8dB', newline, ...
                'sinr=-19.0dB', newline, ...
                't_align=-0.1us'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 273};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, pucch, extra] = srsParseLogs;

            % Check the carrier output.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.NCellID, 1, 'Wrong NCellID.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.CyclicPrefix, 'normal', 'Wrong cyclic prefix.');
            obj.assertEqual(carrier.NSizeGrid, 273, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');
            obj.assertEqual(carrier.NSlot, 9, 'Wrong slot number.');
            obj.assertEqual(carrier.NFrame, 768, 'Wrong frame number.');
            obj.assertEqual(carrier.SymbolsPerSlot, 14, 'Wrong number of OFDM symbols per slot.');
            obj.assertEqual(carrier.SlotsPerSubframe, 2, 'Wrong number of slots per subframe.');
            obj.assertEqual(carrier.SlotsPerFrame, 20, 'Wrong number of slots per frame.');

            % Check the pucch output.
            obj.assertClass(pucch, 'nrPUCCH1Config', 'Output "pucch" is not an nrPUCCH1Config object.');
            obj.assertEqual(pucch.NSizeBWP, 273, 'Wrong BWP size.');
            obj.assertEqual(pucch.NStartBWP, 0, 'Wrong BWP start.');
            obj.assertEqual(pucch.SymbolAllocation, [0 14], 'Wrong OFDM symbol allocation.');
            obj.assertEqual(pucch.PRBSet, 0, 'Wrong PRB set.');
            obj.assertEqual(pucch.FrequencyHopping, 'neither', 'Wrong frequency hopping.');
            obj.assertEqual(pucch.SecondHopStartPRB, 1, 'Wrong starting PRB index of second hop.');
            obj.assertEqual(pucch.GroupHopping, 'neither', 'Wrong group hopping configuration.');
            obj.assertEqual(pucch.HoppingID, 1, 'Wrong hopping identity.');
            obj.assertEqual(pucch.InitialCyclicShift, 0, 'Wrong initial cyclic shift.');
            obj.assertEqual(pucch.OCCI, 0, 'Wrong orthogonal cover code index.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEmpty(extra, 'Output "extra" is not empty.');
        end % of function checkParserPUCCHF1(obj)

        function checkParserPUCCHF2(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2023-08-05T16:59:39.365189 [UL-PHY2 ] [D] [   824.8] PUCCH: rnti=0x4601 format=2 prb=[3, 4) prb2=na symb=[12, 14) csi1=1011111 t=82.0us', newline, ...
                'rnti=0x4601', newline, ...
                'format=2', newline, ...
                'bwp=[0, 273)', newline, ...
                'prb=[3, 4)', newline, ...
                'prb2=na', newline, ...
                'symb=[12, 14)', newline, ...
                'n_id=1', newline, ...
                'n_id0=1', newline, ...
                'slot=824.8', newline, ...
                'cp=normal', newline, ...
                'ports=0', newline, ...
                'status=valid', newline, ...
                'csi1=1011111', newline, ...
                'epre=-26.4dB', newline, ...
                'rsrp=-26.5dB', newline, ...
                'sinr=+27.6dB', newline, ...
                't_align=0.0us'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 273};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, pucch, extra] = srsParseLogs;

            % Check the carrier output.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.NCellID, 1, 'Wrong NCellID.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.CyclicPrefix, 'normal', 'Wrong cyclic prefix.');
            obj.assertEqual(carrier.NSizeGrid, 273, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');
            obj.assertEqual(carrier.NSlot, 8, 'Wrong slot number.');
            obj.assertEqual(carrier.NFrame, 824, 'Wrong frame number.');
            obj.assertEqual(carrier.SymbolsPerSlot, 14, 'Wrong number of OFDM symbols per slot.');
            obj.assertEqual(carrier.SlotsPerSubframe, 2, 'Wrong number of slots per subframe.');
            obj.assertEqual(carrier.SlotsPerFrame, 20, 'Wrong number of slots per frame.');

            % Check the pucch output.
            obj.assertClass(pucch, 'nrPUCCH2Config', 'Output "pucch" is not an nrPUCCH2Config object.');
            obj.assertEqual(pucch.NSizeBWP, 273, 'Wrong BWP size.');
            obj.assertEqual(pucch.NStartBWP, 0, 'Wrong BWP start.');
            obj.assertEqual(pucch.SymbolAllocation, [12 2], 'Wrong OFDM symbol allocation.');
            obj.assertEqual(pucch.PRBSet, 3, 'Wrong PRB set.');
            obj.assertEqual(pucch.FrequencyHopping, 'neither', 'Wrong frequency hopping.');
            obj.assertEqual(pucch.SecondHopStartPRB, 1, 'Wrong starting PRB index of second hop.');
            obj.assertEqual(pucch.NID, 1, 'Wrong PUCCH scrambling identity.');
            obj.assertEqual(pucch.RNTI, 17921, 'Wrong radio network temporary identifier.');
            obj.assertEqual(pucch.NID0, 1, 'Wrong DM-RS scrambling identity.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEmpty(extra, 'Output "extra" is not empty.');
        end % of function checkParserPUCCHF2(obj)
    end % of methods (Test, TestTags = {'matlab code'})

    methods (Access=private)
        function injectClipboardStub(obj, logdata)
            import matlab.unittest.fixtures.PathFixture;

            % Use the PathFixture to temporarily add the folder to the path
            % and restore it when the test method completes.
            obj.applyFixture(PathFixture([obj.wd, '/overloads']));

            % Register the fake pause function to return the desired user answer.
            clipboard('', logdata);
        end % of function injectClipboardStub(obj, logdata)

        function injectInputStub(obj, answers)
            import matlab.unittest.fixtures.PathFixture;

            % Use the PathFixture to temporarily add the folder to the path
            % and restore it when the test method completes.
            obj.applyFixture(PathFixture([obj.wd, '/overloads']));

            % Register the fake input function to return the desired user answer.
            input('', '', answers);
        end % of function injectInputStub(obj, answer)
    end % of methods (Access=private)

end % of classdef CheckAnalyzers
