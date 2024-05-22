%runSRSRANUnittest Main srsRAN test interface.
%   runSRSRANUnittest(BLOCKNAME, 'testvector') generates test vectors for the
%   srsRAN block BLOCKNAME. The resulting test vectores are stored in the folder
%   'testvector_outputs' in the current directory. Example:
%      runSRSRANUnittest('modulation_mapper', 'testvector')
%
%   runSRSRANUnittest(BLOCKNAME, 'testmex') tests the srsRAN block
%   BLOCKNAME by running a MEX version of it.
%
%   runSRSRANUnittest(..., RandomShuffle=true) runs the tests using the 'shuffle'
%   random generator initialization instead of 'default'.
%
%   runSRSRANUnittest('all', ...) runs all the tests of the specified type.
%
%   TEST = runSRSRANUnittest(...) returns a Test object TEST withouth running it.
%   The test can be later executed with the command TEST.run.

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

function test = runSRSRANUnittest(blockName, testType, opt)
    arguments
        blockName          char   {mustBeSRSBlock}
        testType           char   {mustBeMember(testType, {'testvector', 'testmex'})}
        opt.RandomShuffle logical {mustBeNumericOrLogical} = false
    end

    import matlab.unittest.TestSuite
    import matlab.unittest.parameters.Parameter

    % define the absolute output paths
    outputPath = [pwd '/testvector_outputs'];
    extParams = Parameter.fromData('outputPath', {outputPath}, 'RandomDefault', {~opt.RandomShuffle});

    if ~strcmp(blockName, 'all')
        unittestClass = name2Class(blockName);
        nrPHYtestvectorTests = TestSuite.fromClass(unittestClass, ...
            'Tag', testType, 'ExternalParameters', extParams);
        if isempty(nrPHYtestvectorTests)
            warning('No ''%s'' tests for the ''%s'' block.', testType, blockName);
        end
    else
        nrPHYtestvectorTests = TestSuite.fromFolder('.', 'Tag', testType, ...
            'ExternalParameters', extParams);
    end
    if nargout == 1
        test = nrPHYtestvectorTests;
    else
        nrPHYtestvectorTests.run;
    end % of if nargout == 1
end % of runSRSRANUnittest

function mustBeSRSBlock(a)
    validBlocks = union({'all'}, srsTest.listSRSblocks);
    mustBeMember(a, validBlocks);
end

function unittestClass = name2Class(name)
    switch name
        case 'channel_equalizer'
            unittestClass = ?srsChEqualizerUnittest;
        case 'demodulation_mapper'
            unittestClass = ?srsDemodulationMapperUnittest;
        case 'dft_processor'
            unittestClass = ?srsDFTProcessorUnittest;
        case 'dmrs_pbch_processor'
            unittestClass = ?srsPBCHdmrsUnittest;
        case 'dmrs_pdcch_processor'
            unittestClass = ?srsPDCCHdmrsUnittest;
        case 'dmrs_pdsch_processor'
            unittestClass = ?srsPDSCHdmrsUnittest;
        case 'dmrs_pucch_processor'
            unittestClass = ?srsPUCCHdmrsUnittest;
        case 'dmrs_pusch_estimator'
            unittestClass = ?srsPUSCHdmrsUnittest;
        case 'ldpc_encoder'
            unittestClass = ?srsLDPCEncoderUnittest;
        case 'ldpc_rate_matcher'
            unittestClass = ?srsLDPCRateMatcherUnittest;
        case 'ldpc_segmenter'
            unittestClass = ?srsLDPCSegmenterUnittest;
        case 'low_papr_sequence_generator'
            unittestClass = ?srsLowPAPRSequenceUnittest;
        case 'modulation_mapper'
            unittestClass = ?srsModulationMapperUnittest;
        case 'nzp_csi_rs_generator'
            unittestClass = ?srsNZPCSIRSGeneratorUnittest;
        case 'ofdm_demodulator'
            unittestClass = ?srsOFDMDemodulatorUnittest;
        case 'ofdm_modulator'
            unittestClass = ?srsOFDMModulatorUnittest;
        case 'ofdm_prach_demodulator'
            unittestClass = ? srsPRACHDemodulatorUnittest;
        case 'ofh_compression'
            unittestClass = ?srsOFHCompressionUnittest;
        case 'pbch_encoder'
            unittestClass = ?srsPBCHEncoderUnittest;
        case 'pbch_modulator'
            unittestClass = ?srsPBCHModulatorUnittest;
        case 'pdcch_candidates_common'
            unittestClass = ?srsPDCCHCandidatesCommonUnittest;
        case 'pdcch_candidates_ue'
            unittestClass = ?srsPDCCHCandidatesUeUnittest;
        case 'pdcch_encoder'
            unittestClass = ?srsPDCCHEncoderUnittest;
        case 'pdcch_modulator'
            unittestClass = ?srsPDCCHModulatorUnittest;
        case 'pdcch_processor'
            unittestClass = ?srsPDCCHProcessorUnittest;
        case 'pdsch_encoder'
            unittestClass = ?srsPDSCHEncoderUnittest;
        case 'pdsch_modulator'
            unittestClass = ?srsPDSCHModulatorUnittest;
        case 'pdsch_processor'
            unittestClass = ?srsPDSCHProcessorUnittest;
        case 'port_channel_estimator'
            unittestClass = ?srsChEstimatorUnittest;
        case 'prach_detector'
            unittestClass = ?srsPRACHDetectorUnittest;
        case 'prach_generator'
            unittestClass = ?srsPRACHGeneratorUnittest;
        case 'pucch_demodulator_format2'
            unittestClass = ?srsPUCCHDemodulatorFormat2Unittest;
        case 'pucch_detector'
            unittestClass = ?srsPUCCHDetectorFormat1Unittest;
        case 'pucch_processor_format0'
            unittestClass = ?srsPUCCHProcessorFormat0Unittest;
        case 'pucch_processor_format1'
            unittestClass = ?srsPUCCHProcessorFormat1Unittest;
        case 'pucch_processor_format2'
            unittestClass = ?srsPUCCHProcessorFormat2Unittest;
        case 'pusch_decoder'
            unittestClass = ?srsPUSCHDecoderUnittest;
        case 'pusch_demodulator'
            unittestClass = ?srsPUSCHDemodulatorUnittest;
        case 'pusch_processor'
            unittestClass = ?srsPUSCHProcessorUnittest;
        case 'pusch_tpmi_select'
            unittestClass = ?srsTPMISelectUnittest;
        case 'short_block_detector'
            unittestClass = ?srsShortBlockDetectorUnittest;
        case 'short_block_encoder'
            unittestClass = ?srsShortBlockEncoderUnittest;
        case 'srs_estimator'
            unittestClass = ?srsSRSEstimatorUnittest;
        case 'ssb_processor'
            unittestClass = ?srsSSBProcessorUnittest;
        case 'tbs_calculator'
            unittestClass = ?srsTBSCalculatorUnittest;
        case 'uci_decoder'
            unittestClass = ?srsUCIDecoderUnittest;
        case 'ulsch_demultiplex'
            unittestClass = ?srsULSCHDemultiplexUnittest;
        case 'ulsch_info'
            unittestClass = ?srsULSCHInfoUnittest;
        otherwise
            error('srsran_matlab:runSRSRANUnittest:unknownBlock', ...
                'No unit test for block %s.\n', name);
    end
end
