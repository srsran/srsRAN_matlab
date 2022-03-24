classdef srsPDSCHmodulatorUnittest < matlab.unittest.TestCase
%  SRSPDSCHMODULATORUNITTEST Unit tests for PDSCH modulator functions
%  This class implements unit tests for the PDSCH symbol modulator functions using the
%  matlab.unittest framework. The simplest use consists in creating an object with
%    testCase = PDSCH_MODULATOR_UTEST
%  and then running all the tests with
%    testResults = testCase.run
%
%  SRSPDSCHMODULATORUNITTEST Properties (TestParameter)
%    PDSCHindex - SSB index, possible values = [0, ..., 7]
%    Lmax     - maximum number of SSBs within a SSB set, possible values = [4, 8, 64]
%    NCellID  - PHY-layer cell ID, possible values = [0, ..., 1007]
%    cw       - BCH cw, possible values = randi([0 1], 864, 1)
%
%  NRPDSCHSYMBOLMODULATORUNITTEST Methods:
%    The following methods are available for all test types:
%      * initialize - adds the required folders to the Matlab path and initializes the random seed
%
%    The following methods are available for the testvector generation tests (TestTags = {'testvector'}):
%      * initializeTestvector      - creates the header file and initializes it
%      * testvectorGenerationCases - generates testvectors for all possible combinations of PDSCHindex
%                                    and Lmax, while using a random NCellID and cw for each test
%      * closeTestvector           - closes the header file as required
%
%    The following methods are available for the SRS PHY validation tests (TestTags = {'srsPHYvalidation'}):
%      * x                     - TBD
%      * srsPHYvalidationCases - validates the SRS PHY functions for all possible combinations of PDSCHindex,
%                                Lmax and NCellID, while using a random cw for each test
%      * y                     - TBD
%
%  See also MATLAB.UNITTEST.

    properties (TestParameter)
        outputPath = {''};
        baseFilename = {''};
        testImpl = {''};
        
        SymbolAllocation = [{[0, 14]}, {[1, 13]}, {[2, 12]}];
        Modulation = [{'QPSK'}, {'16QAM'}, {'64QAM'}, {'256QAM'}]
        DMRSAdditionalPosition = [{0}, {1}, {2}, {3}];
    end

    methods (TestClassSetup)
        function initialize(testCase)
            % add main folder to the Matlab path
            p = path;
            testCase.addTeardown(@path, p);
        end
    end

    methods (Test, TestTags = {'testvector'})

       
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, SymbolAllocation, Modulation, DMRSAdditionalPosition)
            % Generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir (filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % Generate default carrier configuration
            carrier = nrCarrierConfig;
            
            % Generate default PDSCH configuration
            pdsch = nrPDSCHConfig;
            
            % Set test specific
            pdsch.SymbolAllocation = SymbolAllocation;
            pdsch.Modulation = Modulation;
            pdsch.DMRS.DMRSAdditionalPosition = DMRSAdditionalPosition;
            
            % Set randomized values
            pdsch.NID = randi([1, 1023], 1, 1);
            pdsch.RNTI = randi([1, 65535], 1, 1);

            if iscell(pdsch.Modulation)
                error('Unsupported');
            else
                switch pdsch.Modulation
                    case 'QPSK'
                        mod_order1 = 2;
                        modulation_str1 = 'modulation_scheme::QPSK';
                    case '16QAM'
                        mod_order1 = 4;
                        modulation_str1 = 'modulation_scheme::QAM16';
                    case '64QAM'
                        mod_order1 = 6;
                        modulation_str1 = 'modulation_scheme::QAM64';
                    case '256QAM'
                        mod_order1 = 8;
                        modulation_str1 = 'modulation_scheme::QAM256';
                end
                mod_order2 = mod_order1;
                modulation_str2 = modulation_str1;
            end

            
            % Calculate number of encoded bits
            nbits = length(nrPDSCHIndices(carrier, pdsch)) * mod_order1;
            
            % Generate codewords
            cws = randi([0,1], nbits, 1);
            
            % write the BCH cw to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, @writeUint8File, cws);

            % call the PDSCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws);

            % write each complex symbol into a binary file, and the associated indices to another
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            
            [prbset,symbolset,dmrssymbols] = nr5g.internal.pxsch.initializeResources(carrier,pdsch,carrier.NSizeGrid);
            
            dmrs_symbol_mask = zeros(1,14);
            dmrs_symbol_mask(dmrssymbols + 1) = 1;

            reserved_str = '{}';
            
            ports_str = '{0}';
            
            rb_allocation_str = ['rb_allocation({', array2str(pdsch.PRBSet), '}, vrb_to_prb_mapping_type::NON_INTERLEAVED)'];
            
            dmrs_type_str = sprintf('dmrs_type::TYPE%d', pdsch.DMRS.DMRSConfigurationType);

            config = [ {pdsch.RNTI}, {carrier.NSizeGrid}, {carrier.NStartGrid}, ...
                {modulation_str1}, {modulation_str2}, {rb_allocation_str}, {pdsch.SymbolAllocation(1)}, ...
                {pdsch.SymbolAllocation(2)}, {dmrs_symbol_mask}, {dmrs_type_str}, {pdsch.DMRS.NumCDMGroupsWithoutData}, {pdsch.NID}, {1}, {reserved_str}, {0}, {ports_str}];
%     
%     unsigned bwp_start_rb;
%     modulation_scheme modulation1;
%     modulation_scheme modulation2;
%     rb_allocation freq_allocation;
%     unsigned start_symbol_index;
%     unsigned nof_symbols;
%     std::array<bool, MAX_NSYMB_PER_SLOT> dmrs_symb_pos;
%     dmrs_type dmrs_config_type;
%     unsigned nof_cdm_groups_without_data;
%     unsigned n_id;
%     float scaling;
%     re_pattern_list reserved;
%     unsigned pmi;
%     static_vector<uint8_t, MAX_PORTS> ports;
            testCaseString = testImpl.testCaseToString(cellarray2str(config), baseFilename, testID, 1);

            % add the test to the file header
            testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
        end
    end
 
%     methods (Test, TestTags = {'srs_phy_validation'})
%
%         function srsPHYvalidationCases(testCase, NCellID, PDSCHindex, Lmax)
%             % use a cw for each test
%             cw = zeros(864, 1);
%             for index = 1: 864
%                 cw(index) = testCase.cw{index, NCellID+1};
%             end;
%
%             % call the Matlab PHY function
%             [matModulatedSymbols, matSymbolIndices] = srsPDSCHmodulator(cw, NCellID, PDSCHindex, Lmax);
%
%             % call the SRS PHY function
%             % TBD: [srsModulatedSymbols, srsSymbolIndices] = srsPDSCHmodulatorPHYtest(cw, NCellID, PDSCHindex, Lmax);
%
%             % compare the results
%             % TBD: testCase.verifyEqual(matModulatedSymbols, srsModulatedSymbols);
%             % TBD: testCase.verifyEqual(matSymbolIndices, srsSymbolIndices);
%         end
%     end


end
