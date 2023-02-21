%srsOFDMModulatorUnittest Unit tests for OFDM modulator functions.
%   This class implements unit tests for the OFDM modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsOFDMModulatorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsOFDMModulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ofdm_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/lower/modulation').
%
%   srsOFDMModulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsOFDMModulatorUnittest Properties (TestParameter):
%
%   numerology   - Defines the subcarrier spacing (0, 1).
%   DFTsize      - Size of the DFT (128, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096).
%   CyclicPrefix - Cyclic prefix type ('normal', 'extended').
%   NSlot        - Slot index (0...15).
%
%   srsOFDMModulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates test vectors according to the provided
%                               parameters.
%
%   srsOFDMModulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest and nrOFDMModulate.
classdef srsOFDMModulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ofdm_modulator'

        %Type of the tested block.
        srsBlockType = 'phy/lower/modulation'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ofdm_modulator' tests will be erased).
        outputPath = {['testOFDMmodulator', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1, 2, 3, 4).
        numerology = {0, 1, 2}

        %Size of the DFT (256, 512, 1024, 2048, 4096). Only standard values.
        DFTsize = {256, 512, 1024, 2048, 4096}

        %Cyclic prefix type ('normal', 'extended').
        CyclicPrefix = {'normal', 'extended'}

        %Slot index (0...15).
        NSlot = num2cell(0:15)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchmod(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations)
        %   to the test header file.

            fprintf(fileID, 'struct ofdm_modulator_test_configuration {\n');
            fprintf(fileID, 'ofdm_modulator_configuration config;\n');
            fprintf(fileID, 'uint8_t port_idx;\n');
            fprintf(fileID, 'uint8_t slot_idx;\n');
            fprintf(fileID, '};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'ofdm_modulator_test_configuration test_config;\n');
            fprintf(fileID, ...
                'file_vector<resource_grid_writer_spy::expected_entry_t> data;\n');
            fprintf(fileID, 'file_vector<cf_t> modulated;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)


    methods (TestClassSetup)
        function classSetup(testCase)
            orig = rng;
            testCase.addTeardown(@rng,orig)
            rng('default');
        end
    end

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, DFTsize, CyclicPrefix)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   DFTsize and CyclicPrefix. NSlot, port index, scale and center carrier 
        %   frequency are randomly generated.
        
            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsRandomGridEntry
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeComplexFloatFile

            % generate a unique test ID
            testID = testCase.generateTestID;

            % use a unique port index and scale for each test
            portIdx = randi([0, 15]);
            scale = 2 * rand - 1;
            NSlotLoc = randi([0 pow2(numerology)-1]);

            % Select a random carrier frequency from 0 to 3 GHz to avoid
            % any multiple of the sampling rate. Granularity 100 kHz.
            CarrierFrequency = round(rand() * 3e4) * 1e5;

            % current fixed parameter values
            NStartGrid = 0;
            NFrame = 0;

            % calculate the number of RBs to be used
            NSizeGrid = floor(192 * (DFTsize / 4096));

            % skip those invalid configuration cases
            isCPTypeOK = ((numerology == 2) || strcmp(CyclicPrefix, 'normal'));
            isNSizeGridOK = NSizeGrid > 0;

            if isCPTypeOK && isNSizeGridOK
                % configure the carrier according to the test parameters
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(SubcarrierSpacing, NStartGrid, NSizeGrid, ...
                    NSlotLoc, NFrame, CyclicPrefix);

                % generate the DFT input data and related indices
                [inputData, inputIndices] = srsRandomGridEntry(carrier, portIdx);

                % write the complex symbol and associated indices into a binary file
                testCase.saveDataFile('_test_input', testID, ...
                    @writeResourceGridEntryFile, inputData, inputIndices);

                % call the OFDM modulator MATLAB functions
                timeDomainData = nrOFDMModulate(carrier, reshape(inputData, [NSizeGrid * 12, carrier.SymbolsPerSlot]), ...
                    'Windowing', 0, 'CarrierFrequency', CarrierFrequency);

                % apply the requested scale and homogenize the output values with those of srsran
                srsRANscaleFactor = DFTsize;
                timeDomainData = timeDomainData * scale * srsRANscaleFactor;

                % write the time-domain data into a binary file
                testCase.saveDataFile('_test_output', testID, ...
                    @writeComplexFloatFile, timeDomainData);

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, {{numerology, NSizeGrid, ...
                    DFTsize, ['cyclic_prefix::', upper(CyclicPrefix)], scale, CarrierFrequency}, ...
                    portIdx, NSlotLoc}, true, '_test_input', '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsOFDMModulatorUnittest
