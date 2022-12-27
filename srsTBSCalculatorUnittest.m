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
%   modulation - Modulation order.
%   nlayers    - Number of transmission layers (1...4 for one codeword,
%                5...8 for two codewords).
%   nprb       - Number of physical resource blocks (PRBs) allocated for
%                the physical shared channel.
%   nsymb      - Number of symbols allocated for the data transmission in
%                the physical shared channel.
%   ndmrsprb   - Number of resource elements for DMRS allocated for the
%                data transmission in the physical shared channel.
%   tcr        - Target code rate.
%   xoh        - Additional overhead.
%   tbscaling  - Scaling factor(s) for intermediate number of information
%                bits. 
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
        outputPath = {['testTBSCalculator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %It must be specified as one of (2, 4, 6, 8). They refer to QPSK,
        %16-QAM, 64-QAM and 256-QAM respectively. 
        modulation = {2, 4, 6, 8};

        %The value must be a scalar nonnegative integer. The nominal value
        %of NLAYERS is in the range of (1...8).
        nlayers = {1, 4};

        %The value must be a scalar nonnegative integer. The nominal value
        %of NPRB is in the range of (1...275).
        nprb = {6, 11};

        %The value must be a scalar nonnegative integer. The nominal value
        %of NSYMB is in the range of (1...14).
        nsymb = {12};

        %The value must be a scalar nonnegative integer. The nominal value
        %depends on the number of CDM groups, the DMRS type density and
        %the number of symbols udes for DMRS transmission.
        %
        %For example, for a Type1 DMRS has a density of six RE per PRB and
        %symbol. With two additional positions and two CDM groups without
        %data, it results in 36 RE per PRB.
        ndmrsprb = {6, 36};

        %Represented in floating point between 0 and 1.
        tcr = {0.1, 0.9};

        %Controls the number of REs available for the data transmission in
        %the shared channel, within one PRB for one slot. It must be a
        %scalar nonnegative integer. The nominal value of XOH is one of (0,
        %6, 12, 18), provided by the higher-layer parameter xOverhead in
        %PDSCH-ServingCellConfig IE or PUSCH-ServingCellConfig IE.
        xoh = {0, 12};

        %The nominal value of TBSCALING is one of (0.25, 0.5, 1), as
        %defined in TS 38.214 Table 5.1.3.2-2.
        tbscaling = {1, 0.25};
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, '#include "lib/scheduler/support/tbs_calculator.h"\n');
            fprintf(fileID, '#include <vector>\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                '\n'...
                'struct test_case_t {\n'...
                '  tbs_calculator_configuration config;\n'...
                '  unsigned                     tbs;\n'...
                '};\n'
                ]);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, modulation, nlayers, nprb, nsymb, ndmrsprb, tcr, xoh, tbscaling)
        %testvectorGenerationCases Generates a test vector for the
        %   modulation, nlayers, nprb, ndmrsprb, tcr, xoh and tbscaling.

        import srsMatlabWrappers.phy.helpers.srsGetModulation
        import srsTest.helpers.cellarray2str
        import srsTest.helpers.mcsDescription2Cell

        NREPerPRB = nsymb * 12 - ndmrsprb;

        modulations = srsGetModulation(modulation);

        tbs = nrTBS(modulations{1}, nlayers, nprb, NREPerPRB, tcr, xoh, tbscaling);
        tbs = tbs(1);

        % generate a unique test ID
        testID = testCase.generateTestID;

        mcsDescrCell = mcsDescription2Cell(modulations{1}, tcr);



        % Prepare configuration cell.
        configCell = {...
            nsymb, ...                   % nof_symb_sh
            ndmrsprb, ...                % nof_dmrs_prb
            xoh, ...                     % nof_oh_prb
            mcsDescrCell, ...            % mcs_descr
            nlayers, ...                 % nof_layers
            round(-log2(tbscaling)), ... % tb_scaling_field
            nprb, ...
            };

        % Prepare test case cell.
        testCaseCell = {
            configCell, ... % config
            tbs, ...        % tbs
            };

        % generate the test case entry
        testCaseString = testCase.testCaseToString(testID, testCaseCell,...
            false);

        % add the test to the file header
        testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsTBSCalculatorUnittest< srsTest.srsBlockUnittest
