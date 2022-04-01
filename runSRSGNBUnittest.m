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

function runSRSGNBUnittest(blockName, testType)
    arguments
        blockName char {mustBeSRSBlock(blockName)}
        testType char {mustBeMember(testType, {'testvector'})}
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
    nrPHYtestvectorTests.run;

end

function mustBeSRSBlock(a)

    % List of implemented blocks, in alphabetical order.
    validBlocks = {...
        'all', ...
        'dmrs_pbch_processor', ...
        'dmrs_pdcch_processor', ...
        'dmrs_pdsch_processor', ...
        'modulation_mapper', ...
        'pbch_modulator', ...
        'pdcch_modulator', ...
        'pdsch_modulator', ...
        'pbch_encoder', ...
        };
    mustBeMember(a, validBlocks);
end

function unittestClass = name2Class(name)
    switch name
        case 'dmrs_pbch_processor'
            unittestClass = ?srsPBCHdmrsUnittest;
        case 'dmrs_pdcch_processor'
            unittestClass = ?srsPDCCHdmrsUnittest;
        case 'dmrs_pdsch_processor'
            unittestClass = ?srsPDSCHdmrsUnittest;
        case 'modulation_mapper'
            unittestClass = ?srsModulationMapperUnittest;
        case 'pbch_modulator'
            unittestClass = ?srsPBCHModulatorUnittest;
        case 'pdcch_modulator'
            unittestClass = ?srsPDCCHModulatorUnittest;
        case 'pdsch_modulator'
            unittestClass = ?srsPDSCHModulatorUnittest;
        case 'pbch_encoder'
            unittestClass = ?srsPBCHEncoderUnittest;
        otherwise
            error('SRSGNB:runSRSGNBUnittest:unknownBlock', ...
                'No unit test for block %s.\n', name);
    end
end
