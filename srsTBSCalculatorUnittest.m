%srsTBSCalculatorUnittest Unit tests for TBS calculation.
%   This class implements unit tests for the TBS calculation. The simplest
%   use consists in creating an object with 
%       testCase = srsTBSCalculatorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsTBSCalculatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'tbs_calculator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'scheduler/support').
%
%   srsTBSCalculatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsTBSCalculatorUnittest Properties (TestParameter):
%
%   modulation - Modulation scheme for each codeword. It must be specified
%                as one of {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'}.
%                Modulation scheme can be specified as a character array or
%                string scalar for one codeword or two codewords. In case
%                of two codewords, the same modulation scheme is applied to
%                both codewords. Alternatively, a cell array of character
%                vectors or string array can be used to specify different
%                modulation schemes for each codeword.
%   nlayers    - Number of transmission layers (1...4 for one codeword,
%                5...8 for two codewords).
%   nprb       - Number of physical resource blocks (PRBs) allocated for
%                the physical shared channel. The value must be a scalar
%                nonnegative integer. The nominal value of NPRB is in the
%                range of 0...275.
%   nsymb      - Number of symbols allocated for the data transmission in
%                the physical shared channel.
%   ndmrsprb   - Number of resource elements for DMRS allocated for the
%                data transmission in the physical shared channel.
%   tcr        - Target code rate for each codeword. It is a scalar for one
%                codeword or a two-element vector for two codewords, with
%                each value between 0 and 1. Alternatively, two codewords
%                can also be configured with single target code rate.
%   xoh        - It specifies the additional overhead, which controls the
%                number of REs available for the data transmission in the
%                shared channel, within one PRB for one slot. It must be a
%                scalar nonnegative integer. The nominal value of XOH is
%                one of {0, 6, 12, 18}, provided by the higher-layer
%                parameter xOverhead in PDSCH-ServingCellConfig IE or
%                PUSCH-ServingCellConfig IE.
%   tbscaling  - It specifies the scaling factor(s) used in the calculation
%                of intermediate number of information bits. The nominal
%                value of TBSCALING is one of {0.25, 0.5, 1}, as defined in
%                TS 38.214 Table 5.1.3.2-2.
%
%   srsTBSCalculatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsTBSCalculatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest, nrTBS.
classdef srsTBSCalculatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'tbs_calculator'

        %Type of the tested block.
        srsBlockType = 'scheduler/support'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'pdccg_candidates_common' tests will be erased).
        outputPath = {['testTBSCalculator', datestr(now, 30)]}
    end

    properties (TestParameter)
        modulation = {2, 4, 6, 8};

        nlayers = {1, 4};

        nprb = {52};

        nsymb = {12};

        ndmrsprb = {6, 36};

        tcr = {0.1, 0.4};

        xoh = {0, 18};

        tbscaling = {1, 0.25};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "srsgnb/scheduler/support/tbs_calculator.h"\n');
            fprintf(fileID, '#include <vector>\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                '\n'...
                'struct test_case_t {\n'...
                '  tbs_calculator_pdsch_configuration config;\n'...
                '  unsigned                           tbs;\n'...
                '};\n'
                ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, modulation, nlayers, nprb, nsymb, ndmrsprb, tcr, xoh, tbscaling)
        %testvectorGenerationCases Generates a test vector for the given
        %   parameters.

        import srsMatlabWrappers.phy.helpers.srsGetModulation
        import srsTest.helpers.cellarray2str

        NREPerPRB = nsymb * 12 - ndmrsprb;

        modulations = srsGetModulation(modulation);

        tbs = nrTBS(modulations{1}, nlayers, nprb, NREPerPRB,tcr, xoh, tbscaling);
        tbs = tbs(1);

        % generate a unique test ID
        testID = testCase.generateTestID;

        % prepare configuration cell
        configCell = {{nsymb, ndmrsprb, xoh, tcr, modulation, nlayers, ...
            round(-log2(tbscaling)), nprb}, tbs};

        % generate the test case entry
        testCaseString = testCase.testCaseToString(testID, configCell,...
            false);

        % add the test to the file header
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsTBSCalculatorUnittest< srsTest.srsBlockUnittest
