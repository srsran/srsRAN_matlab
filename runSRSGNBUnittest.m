%runSRSGNBUnittest Main SRSGNB test interface.
%   runSRSGNBUnittest(BLOCKNAME, 'testvector') generates test vectors for the
%   SRSGNB block BLOCKNAME. The resulting test vectores are stored in the folder
%   'testvector_outputs' in the current directory. Example:
%      runSRSGNBUnittest('modulation_mapper', 'testvector')
%
%   runSRSGNBUnittest(BLOCKNAME, 'srsPHYvalidation') tests the SRSGNB block
%   BLOCKNAME by running a MEX version of it.
%
%   runSRSGNBUnittest('all', ...) runs all the tests of the specified type.
%
%   TEST = runSRSGNBUnittest(...) returns a Test object TEST withouth running it.
%   The test can be later executed with the command TEST.run.

function test = runSRSGNBUnittest(blockName, testType)
    arguments
        blockName char {mustBeSRSBlock}
        testType  char {mustBeMember(testType, {'testvector'})}
    end

    import matlab.unittest.TestSuite
    import matlab.unittest.parameters.Parameter

    % define the absolute output paths
    outputPath = [pwd '/testvector_outputs'];
    extParams = Parameter.fromData('outputPath', {outputPath});

    if ~strcmp(blockName, 'all')
        unittestClass = name2Class(blockName);
        nrPHYtestvectorTests = TestSuite.fromClass(unittestClass, ...
            'Tag', testType, 'ExternalParameters', extParams);
    else
        nrPHYtestvectorTests = TestSuite.fromFolder('.', 'Tag', testType, ...
            'ExternalParameters', extParams);
    end
    if nargout == 1
        test = nrPHYtestvectorTests;
    else
        nrPHYtestvectorTests.run;
    end % of if nargout == 1
end % of runSRSGNBUnittest

function mustBeSRSBlock(a)
    validBlocks = union({'all'}, srsTest.listSRSblocks);
    mustBeMember(a, validBlocks);
end

function unittestClass = name2Class(name)
    switch name
        case 'demodulation_mapper'
            unittestClass = ?srsDemodulationMapperUnittest;
        case 'dmrs_pbch_processor'
            unittestClass = ?srsPBCHdmrsUnittest;
        case 'dmrs_pdcch_processor'
            unittestClass = ?srsPDCCHdmrsUnittest;
        case 'dmrs_pdsch_processor'
            unittestClass = ?srsPDSCHdmrsUnittest;
        case 'ldpc_encoder'
            unittestClass = ?srsLDPCEncoderUnittest;
        case 'ldpc_rate_matcher'
            unittestClass = ?srsLDPCRateMatcherUnittest;
        case 'ldpc_segmenter'
            unittestClass = ?srsLDPCSegmenterUnittest;
        case 'modulation_mapper'
            unittestClass = ?srsModulationMapperUnittest;
        case 'ofdm_demodulator'
            unittestClass = ?srsOFDMDemodulatorUnittest;
        case 'ofdm_modulator'
            unittestClass = ?srsOFDMModulatorUnittest;
        case 'pbch_encoder'
            unittestClass = ?srsPBCHEncoderUnittest;
        case 'pbch_modulator'
            unittestClass = ?srsPBCHModulatorUnittest;
        case 'pdcch_encoder'
            unittestClass = ?srsPDCCHEncoderUnittest;
        case 'pdcch_modulator'
            unittestClass = ?srsPDCCHModulatorUnittest;
        case 'pdsch_encoder'
            unittestClass = ?srsPDSCHEncoderUnittest;
        case 'pdsch_modulator'
            unittestClass = ?srsPDSCHModulatorUnittest;
        case 'ssb_processor'
            unittestClass = ?srsSSBProcessorUnittest;
        otherwise
            error('SRSGNB:runSRSGNBUnittest:unknownBlock', ...
                'No unit test for block %s.\n', name);
    end
end
