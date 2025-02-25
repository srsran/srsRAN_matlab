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
%   See also matlab.unittest and nrOFDMModulate.

%   Copyright 2021-2025 Software Radio Systems Limited
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
        numerology = {0, 1, 2, 3}

        %Size of the DFT (256, 512, 1024, 2048, 4096). Only standard values.
        DFTsize = {256, 512, 1024, 2048, 4096}

        %Cyclic prefix type ('normal', 'extended').
        CyclicPrefix = {'normal', 'extended'}
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

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, DFTsize, CyclicPrefix)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   DFTsize and CyclicPrefix. NSlot, port index, scale and center carrier 
        %   frequency are randomly generated.

            import srsLib.phy.helpers.srsRandomGridEntry
            import srsTest.helpers.approxbf16
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.writeComplexFloatFile

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Use a unique port index and scale for each test.
            portIdx = randi([0, 15]);
            scale = 2 * rand - 1;
            nSlot = randi([0 pow2(numerology)-1]);

            % Select a random carrier frequency from 0 to 3 GHz to avoid
            % any multiple of the sampling rate. Granularity 100 kHz.
            CarrierFrequency = round(rand() * 3e4) * 1e5;

            % Current fixed parameter values.
            nStartGrid = 0;
            nFrame = 0;

            % Calculate the number of RBs to be used.
            nSizeGrid = floor(192 * (DFTsize / 4096));

            % Skip those invalid configuration cases.
            isCPTypeOK = ((numerology == 2) || strcmp(CyclicPrefix, 'normal'));
            isNSizeGridOK = nSizeGrid > 0;

            if isCPTypeOK && isNSizeGridOK
                % Configure the carrier according to the test parameters.
                subcarrierSpacing = 15 * (2 .^ numerology);
                carrier = nrCarrierConfig( ...
                    SubcarrierSpacing=subcarrierSpacing, ...
                    NStartGrid=nStartGrid, ...
                    NSizeGrid=nSizeGrid, ...
                    NSlot=nSlot, ...
                    NFrame=nFrame, ...
                    CyclicPrefix=CyclicPrefix ...
                    );

                % Generate the DFT input data and related indices.
                [inputData, inputIndices] = srsRandomGridEntry(carrier, portIdx);

                % Write the complex symbol and associated indices into a binary file.
                testCase.saveDataFile('_test_input', testID, ...
                    @writeResourceGridEntryFile, inputData, inputIndices);

                % Call the OFDM modulator MATLAB functions.
                timeDomainData = nrOFDMModulate(carrier, reshape(approxbf16(inputData), [nSizeGrid * 12, carrier.SymbolsPerSlot]), ...
                    'Windowing', 0, 'CarrierFrequency', CarrierFrequency);

                % Apply the requested scale and homogenize the output values with those of srsran.
                srsRANscaleFactor = DFTsize;
                timeDomainData = timeDomainData * scale * srsRANscaleFactor;

                % Write the time-domain data into a binary file.
                testCase.saveDataFile('_test_output', testID, ...
                    @writeComplexFloatFile, timeDomainData);

                % Generate the test case entry.
                testCaseString = testCase.testCaseToString(testID, {{numerology, nSizeGrid, ...
                    DFTsize, ['cyclic_prefix::', upper(CyclicPrefix)], scale, CarrierFrequency}, ...
                    portIdx, nSlot}, true, '_test_input', '_test_output');

                % Add the test to the file header.
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsOFDMModulatorUnittest
