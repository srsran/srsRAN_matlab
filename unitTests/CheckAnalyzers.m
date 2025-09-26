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
%   checkParserPUSCH    - Checks the parser for PUSCH logs.
%   checkParserPUCCHF0  - Checks the parser for PUCCH Format 0 logs.
%   checkParserPUCCHF1  - Checks the parser for PUCCH Format 1 logs.
%   checkParserPUCCHF2  - Checks the parser for PUCCH Format 2 logs.
%   checkParserPUCCHF3  - Checks the parser for PUCCH Format 3 logs.
%   checkParserPUCCHF4  - Checks the parser for PUCCH Format 4 logs.
%   checkParserPRACH    - Checks the parser for PRACH logs.
%
%   Example
%      runtests('CheckAnalyzers')
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
            logs = ['2023-08-05T16:59:48.857764 [PHY     ] [D] [   749.9] PUSCH: rnti=0x4601 h_id=3 prb=[4, 271) symb=[0, 14) mod=64QAM rv=0 tbs=24597 crc=OK iter=2.1 sinr=30.7dB t=1532.4us uci_t=0.0us ret_t=0.0us', newline, ...
                'rnti=0x4601', newline, ...
                'h_id=3', newline, ...
                'bwp=[0, 273)', newline, ...
                'prb=[4, 271)', newline, ...
                'symb=[0, 14)', newline, ...
                'oack=0', newline, ...
                'ocsi1=0', newline, ...
                'part2=entries=[]', newline, ...
                'alpha=0.0', newline, ...
                'betas=[0.0, 0.0, 0.0]', newline, ...
                'mod=64QAM', newline, ...
                'tcr=0.92578125', newline, ...
                'rv=0', newline, ...
                'bg=1', newline, ...
                'new_data=true', newline, ...
                'n_id=1', newline, ...
                'dmrs_mask={2, 7, 11}', newline, ...
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
                'sinr_ch_est=30.7dB', newline, ...
                'sinr_eq[sel]=30.7dB', newline, ...
                'sinr_evm=22.1dB', newline, ...
                'evm=0.07', newline, ...
                'epre=-8.7dB', newline, ...
                'rsrp=-8.7dB', newline, ...
                'sinr=+31.1dB', newline, ...
                't_align=0.0us', newline, ...
                'cfo=-0.0Hz'];
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
            obj.assertEqual(double(pusch.TransformPrecoding), 0, 'Wrong transform precoding.');
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
            obj.assertEqual(pusch.DMRS.CustomSymbolSet(:), [2; 7; 11], 'Wrong DM-RS OFDM symbol locations.');
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

        function checkParserPUCCHF0(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2025-02-10T09:51:20.776423 [PHY     ] [D] [  214.17] PUCCH: rnti=0x4601 format=0 prb1=0 prb2=na symb=[0, 2) cs=0 ack=1 sinr=15.4dB t=7.4us', newline, ...
                'rnti=0x4601', newline, ...
                'format=0', newline, ...
                'bwp=[0, 133)', newline, ...
                'slot=214.17', newline, ...
                'prb1=0', newline, ...
                'prb2=na', newline, ...
                'symb=[0, 2)', newline, ...
                'cs=4', newline, ...
                'n_id=1', newline, ...
                'sr_opportunity=false', newline, ...
                'ports=0', newline, ...
                'status=valid', newline, ...
                'ack=1', newline, ...
                'sinr_eq[sel]=15.4dB', newline ...
                'epre=-11.8dB', newline, ...
                'rsrp=+1.8dB', newline, ...
                'sinr=+15.4dB', newline, ...
                't_align=na', newline, ...
                'cfo=na'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 133};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, pucch, extra] = srsParseLogs;

            % Check the carrier output.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.NCellID, 1, 'Wrong NCellID.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.CyclicPrefix, 'normal', 'Wrong cyclic prefix.');
            obj.assertEqual(carrier.NSizeGrid, 133, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');
            obj.assertEqual(carrier.NSlot, 17, 'Wrong slot number.');
            obj.assertEqual(carrier.NFrame, 214, 'Wrong frame number.');
            obj.assertEqual(carrier.SymbolsPerSlot, 14, 'Wrong number of OFDM symbols per slot.');
            obj.assertEqual(carrier.SlotsPerSubframe, 2, 'Wrong number of slots per subframe.');
            obj.assertEqual(carrier.SlotsPerFrame, 20, 'Wrong number of slots per frame.');

            % Check the pucch output.
            obj.assertClass(pucch, 'nrPUCCH0Config', 'Output "pucch" is not an nrPUCCH0Config object.');
            obj.assertEqual(pucch.NSizeBWP, 133, 'Wrong BWP size.');
            obj.assertEqual(pucch.NStartBWP, 0, 'Wrong BWP start.');
            obj.assertEqual(pucch.SymbolAllocation, [0 2], 'Wrong OFDM symbol allocation.');
            obj.assertEqual(pucch.PRBSet, 0, 'Wrong PRB set.');
            obj.assertEqual(pucch.FrequencyHopping, 'neither', 'Wrong frequency hopping.');
            obj.assertEqual(pucch.SecondHopStartPRB, 1, 'Wrong starting PRB index of second hop.');
            obj.assertEqual(pucch.Interlacing, false, 'Wrong interlacing.');
            obj.assertEqual(pucch.RBSetIndex, 0, 'Wrong RB set index.');
            obj.assertEqual(pucch.InterlaceIndex, 0, 'Wrong interlace index.');
            obj.assertEqual(pucch.GroupHopping, 'neither', 'Wrong group hopping.');
            obj.assertEqual(pucch.HoppingID, 1, 'Wrong hopping ID.');
            obj.assertEqual(pucch.InitialCyclicShift, 4, 'Wrong initial cyclic shift.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEmpty(extra, 'Output "extra" is not empty.');
        end % of function checkParserPUCCHF0(obj)

        function checkParserPUCCHF1(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2023-08-05T16:59:49.046269 [PHY     ] [D] [   768.9] PUCCH: rnti=0x4601 format=1 prb1=0 prb2=na symb=[0, 14) cs=0 occ=0 sr=yes t=60.2us', newline, ...
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
                'sr=yes', newline, ...
                'detection_metric=0.6', newline, ...
                'sinr_ch_est[sel]=44.3dB', newline ...
                'epre=-63.9dB', newline, ...
                'rsrp=-82.8dB', newline, ...
                'sinr=-19.0dB', newline, ...
                't_align=-0.1us', newline, ...
                'cfo=+0.1Hz'];
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
            logs = ['2023-08-05T16:59:39.365189 [PHY     ] [D] [   824.8] PUCCH: rnti=0x4601 format=2 prb=[3, 4) prb2=na symb=[12, 14) csi1=1011111 t=82.0us', newline, ...
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
                'sinr_ch_est[sel]=33.2dB', newline ...
                'epre=-26.4dB', newline, ...
                'rsrp=-26.5dB', newline, ...
                'sinr=+27.6dB', newline, ...
                't_align=0.0us', newline, ...
                'cfo=+0.3Hz'];
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

        function checkParserPUCCHF3(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2025-01-16T14:46:53.620414 [PHY     ] [D] [    20.8] PUCCH: rnti=0x4601 format=3 prb=[124, 125) prb2=na symb=[4, 8) csi1=0001 sinr=27.0dB t=92.3us', newline, ...
                'rnti=0x4601', newline, ...
                'format=3', newline, ...
                'bwp=[0, 133)', newline, ...
                'prb=[124, 125)', newline, ...
                'prb2=na', newline, ...
                'symb=[4, 8)', newline, ...
                'n_id_scr=1', newline, ...
                'n_id_hop=1', newline, ...
                'slot=20.8', newline, ...
                'cp=normal', newline, ...
                'ports=0', newline, ...
                'pi2_bpsk=false', newline, ...
                'add_dmrs=false', newline, ...
                'status=valid', newline, ...
                'csi1=0001', newline, ...
                'sinr_ch_est[sel]=27.0dB', newline ...
                'epre=-11.8dB', newline, ...
                'rsrp=-11.8dB', newline, ...
                'sinr=+27.0dB', newline, ...
                't_align=0.00us', newline, ...
                'cfo=na'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 133};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, pucch, extra] = srsParseLogs;

            % Check the carrier output.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.NCellID, 1, 'Wrong NCellID.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.CyclicPrefix, 'normal', 'Wrong cyclic prefix.');
            obj.assertEqual(carrier.NSizeGrid, 133, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');
            obj.assertEqual(carrier.NSlot, 8, 'Wrong slot number.');
            obj.assertEqual(carrier.NFrame, 20, 'Wrong frame number.');
            obj.assertEqual(carrier.SymbolsPerSlot, 14, 'Wrong number of OFDM symbols per slot.');
            obj.assertEqual(carrier.SlotsPerSubframe, 2, 'Wrong number of slots per subframe.');
            obj.assertEqual(carrier.SlotsPerFrame, 20, 'Wrong number of slots per frame.');

            % Check the pucch output.
            obj.assertClass(pucch, 'nrPUCCH3Config', 'Output "pucch" is not an nrPUCCH3Config object.');
            obj.assertEqual(pucch.NSizeBWP, 133, 'Wrong BWP size.');
            obj.assertEqual(pucch.NStartBWP, 0, 'Wrong BWP start.');
            obj.assertEqual(pucch.Modulation, 'QPSK', 'Wrong modulation.');
            obj.assertEqual(pucch.SymbolAllocation, [4 4], 'Wrong OFDM symbol allocation.');
            obj.assertEqual(pucch.PRBSet, 124, 'Wrong PRB set.');
            obj.assertEqual(pucch.FrequencyHopping, 'neither', 'Wrong frequency hopping.');
            obj.assertEqual(pucch.SecondHopStartPRB, 1, 'Wrong starting PRB index of second hop.');
            obj.assertEqual(pucch.GroupHopping, 'neither', 'Wrong group hopping.');
            obj.assertEqual(pucch.HoppingID, 1, 'Wrong hopping identity.');
            obj.assertEqual(pucch.NID, 1, 'Wrong PUCCH scrambling identity.');
            obj.assertEqual(pucch.RNTI, 17921, 'Wrong radio network temporary identifier.');
            obj.assertEqual(pucch.NID0, [], 'Wrong DM-RS scrambling identity.');
            obj.assertEqual(pucch.AdditionalDMRS, false, 'Wrong additional DM-RS.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEmpty(extra, 'Output "extra" is not empty.');
        end % of function checkParserPUCCHF3(obj)

        function checkParserPUCCHF4(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2025-01-16T14:50:28.741569 [PHY     ] [D] [    20.8] PUCCH: rnti=0x4601 format=4 prb=[10, 11) prb2=na symb=[0, 14) csi1=0001 sinr=27.2dB t=131.1us', newline, ...
                'rnti=0x4601', newline, ...
                'format=4', newline, ...
                'bwp=[0, 133)', newline, ...
                'prb=[10, 11)', newline, ...
                'prb2=na', newline, ...
                'symb=[0, 14)', newline, ...
                'n_id_scr=1', newline, ...
                'n_id_hop=1', newline, ...
                'slot=20.8', newline, ...
                'cp=normal', newline, ...
                'ports=0', newline, ...
                'pi2_bpsk=false', newline, ...
                'add_dmrs=false', newline, ...
                'occ=0', newline, ...
                'occ_len=2', newline, ...
                'status=valid', newline, ...
                'csi1=0001', newline, ...
                'sinr_ch_est[sel]=27.2dB', newline ...
                'epre=-11.8dB', newline, ...
                'rsrp=-11.8dB', newline, ...
                'sinr=+27.2dB', newline, ...
                't_align=0.00us', newline, ...
                'cfo=-5.5Hz'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 133};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, pucch, extra] = srsParseLogs;

            % Check the carrier output.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.NCellID, 1, 'Wrong NCellID.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.CyclicPrefix, 'normal', 'Wrong cyclic prefix.');
            obj.assertEqual(carrier.NSizeGrid, 133, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');
            obj.assertEqual(carrier.NSlot, 8, 'Wrong slot number.');
            obj.assertEqual(carrier.NFrame, 20, 'Wrong frame number.');
            obj.assertEqual(carrier.SymbolsPerSlot, 14, 'Wrong number of OFDM symbols per slot.');
            obj.assertEqual(carrier.SlotsPerSubframe, 2, 'Wrong number of slots per subframe.');
            obj.assertEqual(carrier.SlotsPerFrame, 20, 'Wrong number of slots per frame.');

            % Check the pucch output.
            obj.assertClass(pucch, 'nrPUCCH4Config', 'Output "pucch" is not an nrPUCCH4Config object.');
            obj.assertEqual(pucch.NSizeBWP, 133, 'Wrong BWP size.');
            obj.assertEqual(pucch.NStartBWP, 0, 'Wrong BWP start.');
            obj.assertEqual(pucch.Modulation, 'QPSK', 'Wrong modulation.');
            obj.assertEqual(pucch.SymbolAllocation, [0 14], 'Wrong OFDM symbol allocation.');
            obj.assertEqual(pucch.PRBSet, 10, 'Wrong PRB set.');
            obj.assertEqual(pucch.FrequencyHopping, 'neither', 'Wrong frequency hopping.');
            obj.assertEqual(pucch.SecondHopStartPRB, 1, 'Wrong starting PRB index of second hop.');
            obj.assertEqual(pucch.GroupHopping, 'neither', 'Wrong group hopping.');
            obj.assertEqual(pucch.HoppingID, 1, 'Wrong hopping identity.');
            obj.assertEqual(pucch.SpreadingFactor, 2, 'Wrong spreading factor.');
            obj.assertEqual(pucch.OCCI, 0, 'Wrong OCC index.');
            obj.assertEqual(pucch.NID, 1, 'Wrong PUCCH scrambling identity.');
            obj.assertEqual(pucch.RNTI, 17921, 'Wrong radio network temporary identifier.');
            obj.assertEqual(pucch.NID0, [], 'Wrong DM-RS scrambling identity.');
            obj.assertEqual(pucch.AdditionalDMRS, false, 'Wrong additional DM-RS.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEmpty(extra, 'Output "extra" is not empty.');
        end % of function checkParserPUCCHF4(obj)

        function checkParserPRACH(obj)
            % Create a log and feed it to the stub pause function.
            logs = ['2025-09-26T07:51:13.573645 [PHY     ] [D] [   16.19] PRACH: rsi=1 rssi=+6.2dB detected_preambles=[{idx=17 ta=0.00us detection_metric=8.0}] t=123.3us', newline, ...
                'rsi=1', newline, ...
                'preambles=[0, 64)', newline, ...
                'format=B4', newline, ...
                'set=unrestricted', newline, ...
                'zcz=0', newline, ...
                'scs=30kHz', newline, ...
                'nof_rx_ports=1', newline, ...
                'rssi=+6.2dB', newline, ...
                'res=0.1us', newline, ...
                'max_ta=12.08us', newline, ...
                'detected_preambles=[{idx=17 ta=0.00us detection_metric=8.0}]'];
            obj.injectClipboardStub(logs);

            % Prepare answers and feed them to the stub input function.
            answers = {'y', 30, 24};
            obj.injectInputStub(answers);

            % Run the parser.
            [carrier, prach, extra] = srsParseLogs;

            % Check the carrier output. Despite the object is not needed for running
            % the PRACH analyzer, the parser still sets the subcarrier spacing and
            % the grid size.
            obj.assertClass(carrier, 'nrCarrierConfig', 'Output "carrier" is not an nrCarrierConfig object.');
            obj.assertEqual(carrier.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(carrier.NSizeGrid, 24, 'Wrong resource grid size.');
            obj.assertEqual(carrier.NStartGrid, 0, 'Wrong start of resource grid.');

            % Check the prach output.
            obj.assertClass(prach, 'nrPRACHConfig', 'Output "prach" is not an nrPRACHConfig onject.');
            obj.assertEqual(prach.FrequencyRange, 'FR1', 'Wrong frequency range.');
            obj.assertEqual(prach.DuplexMode, 'TDD', 'Wrong duplex mode.');
            obj.assertEqual(prach.SubcarrierSpacing, 30, 'Wrong subcarrier spacing.');
            obj.assertEqual(prach.LRA, 139, 'Wrong sequence length.');
            obj.assertEqual(prach.SequenceIndex, 1, 'Wrong sequence index.');
            obj.assertEqual(prach.PreambleIndex, 17, 'Wrong preamble index.');
            obj.assertEqual(prach.RestrictedSet, 'UnrestrictedSet', 'Wrong type of restricted set.');
            obj.assertEqual(prach.ZeroCorrelationZone, 0, 'Wrong zero correlation zone.');
            obj.assertEqual(prach.Format, 'B4', 'Wrong preamble format.');

            % Check the extra output.
            obj.assertClass(extra, 'struct', 'Output "extra" is not a struct.');
            obj.assertEmpty(extra, 'Output "extra" is not empty.');
        end % of function checkParserPRACH(obj)
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
