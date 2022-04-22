%srsOFDMmodulatorUnittest Unit tests for OFDM modulator functions.
%   This class implements unit tests for the OFDM modulator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsOFDMmodulatorUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsOFDMmodulatorUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'ofdm_modulator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/lower/modulation').
%
%   srsOFDMmodulatorUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsOFDMmodulatorUnittest Properties (TestParameter):
%
%   numerology   - Defines the subcarrier spacing (0, 1).
%   DFTsize      - Size of the DFT (128, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096).
%   CyclicPrefix - Cyclic prefix type ('normal', 'extended').
%   NSlot        - Slot index (0, ..., 15).
%
%   srsOFDMmodulatorUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates test vectors according to the provided
%                               parameters.
%
%   srsOFDMmodulatorUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%  See also matlab.unittest.
classdef srsOFDMmodulatorUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'ofdm_modulator'

        %Type of the tested block.
        srsBlockType = 'phy/lower/modulation'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'ofdm_modulator' tests will be erased).
        outputPath = {['testOFDMmodulator', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1, 2, 3, 4).
        numerology = {0, 1, 2}%, 3, 4}

        %Size of the DFT (256, 512, 1024, 2048, 4096). Only standard values.
        DFTsize = {256, 512, 1024, 2048, 4096}

        %Cyclic prefix type ('normal', 'extended').
        CyclicPrefix = {'normal', 'extended'}

        %Slot index (0, ..., 15).
        NSlot = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYchmod(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            %addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
            % for very specific header types, we'll skip the generic 'srsBlockUnittest' function
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

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, DFTsize, CyclicPrefix)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   DFTsize and CyclicPrefix. NSlot, port index and scale are randomly generated.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsRandomGridEntry
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeComplexFloatFile

            % generate a unique test ID
            testID = testCase.generateTestID;

            % use a unique port index and scale for each test
            portIdx = randi([0, 15]);
            payload = randi([0 1], 24, 1);
            scale = (-1-1).*rand(1, 1) + 1;
            if numerology == 3
              NSlotLoc = 5;
            else
              NSlotLoc = randi([0 pow2(numerology)-1]);
            end

            % current fixed parameter values
            NStartGrid = 0;
            NFrame = 0;
            CarrierFrequency = 2400000000;

            % calculate the number of RBs to be used
            NSizeGrid = floor(192 * (DFTsize / 4096));

            % skip those invalid configuration cases
            isCPTypeOK = numerology == 2 || strcmp(CyclicPrefix, 'normal');
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

                timeDomainData = nrOFDMModulate(carrier, reshape(inputData, [NSizeGrid * 12, carrier.SymbolsPerSlot]), ...
                    'Windowing', 0, 'CarrierFrequency', CarrierFrequency);

                % apply the requested scale and homogenize the output values with those of srsgnb
                srsGNBscaleFactor = DFTsize;
                timeDomainData = timeDomainData * scale * srsGNBscaleFactor;

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
end % of classdef srsOFDMmodulatorUnittest
