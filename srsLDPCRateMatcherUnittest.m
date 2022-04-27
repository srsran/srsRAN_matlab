%srsLDPCRateMatcherUnittest Unit tests for the LDPC encoder.
%   This class implements unit tests for the LDPC encoder using the matlab.unittest
%   framework. The simplest use consists in creating an object with
%       testCase = srsLDPCRateMatcherUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsLDPCRateMatcherUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ldpc_rate_matcher').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., '/phy/upper/channel_coding/ldpc').
%   liftSize      - The lifting size used for simulations (i.e., 14).
%   Nref          - The limited buffer rate matching length used for simulations
%                   (i.e., 700).
%
%   srsLDPCRateMatcherUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsLDPCRateMatcherUnittest Properties (TestParameter):
%
%   baseGraph  - LDPC base graph.
%   rv         - Redundancy version.
%   rmLength   - The rate-matched length (relative to the full codeblock length).
%   modScheme  - Modulation scheme.
%   isLBRM     - Limited buffer rate matching flag.
%
%   srsLDPCRateMatcherUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector for the given configuration.
%
%   srsLDPCRateMatcherUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrLDPCEncode.

classdef srsLDPCRateMatcherUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ldpc_rate_matcher'

        %Type of the tested block, including layers.
        srsBlockType = 'phy/upper/channel_coding/ldpc'

        %Lifting size used for the simulation.
        liftSize = 14

        %Limited buffer rate matching length.
        Nref = 700
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ldpc_rate_matcher' tests will be erased).
        outputPath = {['testLDPCratematcher', datestr(now, 30)]}
    end

    properties (TestParameter)
        %LDPC base graph (1, 2).
        baseGraph = {1, 2}

        %Redundancy version (0, 1, 2, 3).
        rv = {0, 1, 2, 3}

        %Rate-matched length (relative to codeblock length).
        rmLength = {0.5, 0.8, 1, 1.2}

        %Modulation scheme, described as a three-entry cell array. The first
        %entry is the modulation order, the second and the third are the
        %corresponding labels for MATLAB and SRSGNB, respectively.
        %Example: modScheme = {4, '16QAM', 'QAM16'}
        modScheme = {{1, 'BPSK', 'BPSK'}, {2, 'QPSK', 'QPSK'}, {4, '16QAM', 'QAM16'}, ...
            {6, '64QAM', 'QAM64'}, {8, '256QAM', 'QAM256'}}

        %Limited buffer rate matching indicator.
        isLBRM = {false, true}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors.

            fprintf(fileID, '#include "srsgnb/phy/modulation_scheme.h"\n');
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDefinitionToHeaderFile(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors.

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'unsigned rm_length = 0;\n');
            fprintf(fileID, 'unsigned rv = 0;\n');
            fprintf(fileID, 'modulation_scheme mod_scheme = {};\n');
            fprintf(fileID, 'unsigned n_ref = 0;\n');
            fprintf(fileID, 'bool is_lbrm = false;\n');
            fprintf(fileID, 'unsigned nof_filler = 0;\n');
            fprintf(fileID, 'file_vector<uint8_t> full_cblock;\n');
            fprintf(fileID, 'file_vector<uint8_t> rm_cblock;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'}, ParameterCombination = 'pairwise')
        function testvectorGenerationCases(obj, baseGraph, rmLength, rv, ...
                modScheme, isLBRM)
        %testvectorGenerationCases Generates a test vector for the given base graph,
        %   rate-matched length, redundancy version, modulation scheme and LBRM flag.

            import srsTest.helpers.writeUint8File
            import srsTest.helpers.logical2str

            % generate a unique test ID
            testID = obj.generateTestID;

            % Here, baseMsgLength does NOT include the shortened bits.
            baseMsgLength = 20;
            baseCBlckLength = 66;
            if baseGraph == 2
                baseMsgLength = 8;
            baseCBlckLength = 50;
            end

            msgLength = baseMsgLength * obj.liftSize;
            CBlckLength = baseCBlckLength * obj.liftSize;

            % Fraction of filler bits
            fracFillers = 0.1;
            nFiller = ceil(msgLength * fracFillers);
            fillerIdx = msgLength - (nFiller - 1:-1:0);

            % Generate a random "codeblock" (for this simulation, the codeblock
            % doesn't need to be a true codeblock).
            codeblock = randi([0, 1], CBlckLength, 1);
            codeblock(fillerIdx) = -1;

            % SRSGNB rate matcher works on a codeblock basis and its transparent
            % to the number of transmission layers, which is therefore fixed
            % to 1 in these simulations.
            nTxLayers = 1;
            % Rate matching
            outLength = floor(CBlckLength * rmLength / modScheme{1}) * modScheme{1};
            if isLBRM
                rmCodeblock = nrRateMatchLDPC(codeblock, outLength, rv, ...
                    modScheme{2}, nTxLayers, obj.Nref);
            else
                rmCodeblock = nrRateMatchLDPC(codeblock, outLength, rv, ...
                    modScheme{2}, nTxLayers);
            end


            % use SRS convention for filler bits
            codeblock(codeblock == -1) = 254;

            % write full codeblock
            obj.saveDataFile('_test_input', testID, @writeUint8File, codeblock);

            % write rate_matched codeblock
            obj.saveDataFile('_test_output', testID, @writeUint8File, rmCodeblock);

            % generate the test case entry
            modSchemeString = ['modulation_scheme::', modScheme{3}];
            testCaseString = obj.testCaseToString(testID, ...
                {outLength, rv, modSchemeString, obj.Nref, ...
                    logical2str(isLBRM), nFiller}, false, '_test_input', '_test_output');

            % add the test to the file header
            obj.addTestToHeaderFile(obj.headerFileID, testCaseString);

        end % of function addTestIncludesToHeaderFile
    end % of methods (Access = protected)

end % of classdef srsLDPCRateMatcherUnittest
