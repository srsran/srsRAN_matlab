classdef srsPDSCHmodulatorUnittest < matlab.unittest.TestCase
%SRSPDSCHMODULATORUNITTEST Unit tests for PDSCH symbol modulator functions.
%   This class implements unit tests for the PDSCH symbol modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%      testCase = PDSCH_SYMBOL_MODULATOR_UTEST
%   and then running all the tests with
%      testResults = testCase.run
%
%   SRSPDSCHMODULATORUNITTEST Properties (TestParameter):
%
%   SymbolAllocation       - Array that indicates the start (0, ..., 13)
%                            and length (1, ..., 14) of the PDSCH 
%                            transmission.
%   Modulation             - Possible modulation schemes used for the PDSCH
%                            transmission (QPSK, 16QAM, 64QAM, 256QAM).
%   DMRSAdditionalPosition - Number of DMRS additional positions in
%                            time domain (0, ... 3).
%
%   SRSPDSCHMODULATORUNITTEST Methods (TestTags = {'testvector'}):
%
%   initialize                - Adds the required folders to the MATLAB 
%                               path and initializes the random seed.
%   testvectorGenerationCases - Generates test vectors for all possible
%                               combinations of SymbolAllocation, 
%                               Modulation and DMRSAdditionalPosition, 
%                               while using random NID, RNTI and codeword 
%                               for each test.
%
%   SRSPDSCHMODULATORUNITTEST Methods (TestTags = {'srsPHYvalidation'}):
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

    methods (Test, TestTags = {'testvector'})

       
        function testvectorGenerationCases(testCase, testImpl, outputPath, baseFilename, SymbolAllocation, Modulation, DMRSAdditionalPosition)
            % Generate a unique test ID
            filenameTemplate = sprintf('%s/%s_test_input*', outputPath, baseFilename);
            file = dir(filenameTemplate);
            filenames = {file.name};
            testID = length(filenames);

            % Generate default carrier configuration
            carrier = nrCarrierConfig;
            
            % Generate default PDSCH configuration
            pdsch = nrPDSCHConfig;
            
            % Set specific parameters
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
                        modOrder1 = 2;
                        modString1 = 'modulation_scheme::QPSK';
                    case '16QAM'
                        modOrder1 = 4;
                        modString1 = 'modulation_scheme::QAM16';
                    case '64QAM'
                        modOrder1 = 6;
                        modString1 = 'modulation_scheme::QAM64';
                    case '256QAM'
                        modOrder1 = 8;
                        modString1 = 'modulation_scheme::QAM256';
                end
                modOrder2 = modOrder1;
                modString2 = modString1;
            end

            
            % Calculate number of encoded bits
            nBits = length(nrPDSCHIndices(carrier, pdsch)) * modOrder1;
            
            % Generate codewords
            cws = randi([0,1], nBits, 1);
            
            % write the BCH cw to a binary file
            testImpl.saveDataFile(baseFilename, '_test_input', testID, outputPath, @writeUint8File, cws);

            % call the PDSCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = srsPDSCHmodulator(carrier, pdsch, cws);

            % write each complex symbol into a binary file, and the associated indices to another
            testImpl.saveDataFile(baseFilename, '_test_output', testID, outputPath, @writeResourceGridEntryFile, modulatedSymbols, symbolIndices);

            % Generate DMRS symbol mask
            [~, ~, dmrsSymbols] = nr5g.internal.pxsch.initializeResources(carrier, pdsch, carrier.NSizeGrid);
            dmrsSymbolMask = zeros(1, 14);
            dmrsSymbolMask (dmrsSymbols + 1) = 1;

            reserved_str = '{}';
            
            ports_str = '{0}';
            
            rb_allocation_str = ['rb_allocation({', array2str(pdsch.PRBSet), '}, vrb_to_prb_mapping_type::NON_INTERLEAVED)'];
            
            dmrs_type_str = sprintf('dmrs_type::TYPE%d', pdsch.DMRS.DMRSConfigurationType);

            config = [ {pdsch.RNTI}, {carrier.NSizeGrid}, {carrier.NStartGrid}, ...
                {modString1}, {modString1}, {rb_allocation_str}, {pdsch.SymbolAllocation(1)}, ...
                {pdsch.SymbolAllocation(2)}, {dmrsSymbolMask }, {dmrs_type_str}, {pdsch.DMRS.NumCDMGroupsWithoutData}, {pdsch.NID}, {1}, {reserved_str}, {0}, {ports_str}];

            testCaseString = testImpl.testCaseToString(baseFilename, testID, true, config, true);

            % add the test to the file header
            testImpl.addTestToHeaderFile(testCaseString, baseFilename, outputPath);
        end
    end
end
