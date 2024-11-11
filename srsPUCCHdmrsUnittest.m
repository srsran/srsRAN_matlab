%srsPUCCHdmrsUnittest Unit tests for PUCCH DMRS estimator functions.
%   This class implements unit tests for the PUCCH DMRS estimator functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pucch_estimator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsPUCCHdmrsUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUCCHdmrsUnittest Properties (TestParameter):
%
%   numerology           - Defines the subcarrier spacing (0, 1).
%   format               - PUCCH format (1, 2, 3, 4).
%   intraSlotFreqHopping - Intra-slot frequency hopping (false - enabled, true - enabled)
%
%   srsPUCCHdmrsUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUCCHdmrsUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest, nrPUCCHDMRS.

%   Copyright 2021-2024 Software Radio Systems Limited
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

classdef srsPUCCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pucch_estimator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pucch_estimator' tests will be erased).
        outputPath = {['testPUCCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %PUCCH format indexes.
        format = {1, 2, 3, 4}

        %Intra-slot frequency hopping usage (inter-slot hopping is not tested).
        intraSlotFreqHopping = {false, true}

        %Two test vectors with randomized parameters (e.g. cell ID, slot number etc.)
        %are generated for each set of unittest parameters.
        testCaseTrial = {1, 2}

    end % of properties (TestParameter)

    properties(Hidden)
        randomizeTestvector
    end % of properties(Hidden)

    properties(Constant, Hidden)
        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)

        %Minimum and maximum symbol length allowed for each of five PUCCH formats.
        formatLengthSymbols = [1 2; 4 14; 1 2; 4 14; 4 14]

        %Possible length in number of PRBs for Format 3.
        prbLengthFormat3 = [1:6, 8:10, 12, 15, 16]

        %PUCCH format string following srsran repo API.
        srsFormatName = 'pucch_format::FORMAT_';

        %Number of symbols per slot considering normal cyclic prefix.
        numSlotSymbols = 14;
    end % of properties(Constant, Hidden)

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
            fprintf(fileID, '#include <variant>\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'using estimator_config = std::variant<\n');
            fprintf(fileID, 'dmrs_pucch_estimator::format1_configuration,\n');
            fprintf(fileID, 'dmrs_pucch_estimator::format2_configuration,\n');
            fprintf(fileID, 'dmrs_pucch_estimator::format3_configuration,\n');
            fprintf(fileID, 'dmrs_pucch_estimator::format4_configuration\n');
            fprintf(fileID, '>;\n\n');

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'estimator_config config;\n');
            fprintf(fileID, ...
                'file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '};\n');
        end

        function initializeClassImpl(obj)
            obj.randomizeTestvector = randperm(1008);
        end
    end % of methods (Access = protected)

    methods (Access = private)
        function PRBSet = generateRandomPRBallocation(testCase, gridSize, format)
        %generateRandomPRBallocation Generates a PRB set starting from a random PRB index
        %   in the grid with a random valid length in number of PRBs.
        %
        %   Parameters:
        %   gridSize - size of the resource grid.
        %   format   - PUCCH format.
            startPRB = randi([0, gridSize - 1]);
            switch format
                case {1, 4}
                    nofPRBs = 1;
                    setPRBsAsRange = false;
                case 2
                    nofPRBs = randi([1, 16]);
                    setPRBsAsRange = true;
                case 3
                    randId  = randi([1, length(testCase.prbLengthFormat3)]);
                    nofPRBs = testCase.prbLengthFormat3(randId);
                    setPRBsAsRange = true;
            end
            % Make sure the PRB allocation is not beyond the resource grid.
            if startPRB + nofPRBs > gridSize
                nofPRBs = gridSize - startPRB;
            end
            % For formats 1 and 4 it is just a scalar.
            PRBSet = startPRB;
            % For formats 2 and 3 it is a range.
            if setPRBsAsRange
                endPRB = startPRB + nofPRBs - 1;
                PRBSet = startPRB:endPRB;
            end
        end % of function generateRandomPRBallocation
    end % of methods (Access = private)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, format, intraSlotFreqHopping, testCaseTrial) %#ok<INUSD>
        %testvectorGenerationCases Generates a test vector for the given numerology, format and frequency hopping,
        %  while using a random NCellID, random NSlot and random symbol and PRB length.

            import srsLib.phy.upper.signal_processors.srsPUCCHdmrs
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.logical2str;

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            % Use a unique NCellID, NSlot for each test.
            randomizedCellID = testCase.randomizeTestvector(testID + 1);
            nCellID = testCase.NCellID{randomizedCellID};

            % Use a random slot number from the allowed range.
            if numerology == 0
                nSlot = randi([0, 9]);
            else
                nSlot = randi([0, 19]);
            end
            % Format name following srsran naming.
            formatString = ['dmrs_pucch_estimator::format', num2str(format), '_configuration'];

            % Fixed parameter values.
            nSizeGrid  = 52;
            nStartGrid = 0;
            nFrame     = 0;
            cyclicPrefix = 'normal';
            groupHopping = 'neither';
            frequencyHopping = 'neither';
            secondHopStartPRB = 0;

            % Fix nid and nid0 to physical CellID.
            nid  = nCellID;
            nid0 = nCellID;

            % Currently fixed to 1 port of random number from [0, 7].
            ports = randi([0, 7]);
            portsStr = cellarray2str({ports}, true);

            % Random initial cyclic shift.
            initialCyclicShift = randi([0, 11]);

            % Random start PRB index and length in number of PRBs.
            PRBSet  = generateRandomPRBallocation(testCase, nSizeGrid, format);
            nofPRBs = size(PRBSet, 2);

            % Random start symbol and length in symbols.
            symbolLength = randi([testCase.formatLengthSymbols(format + 1, 1), ...
                                  testCase.formatLengthSymbols(format + 1, 2)]);

            % Intra-slot frequency hopping requires at least 2 OFDM
            % symbols.
            if (intraSlotFreqHopping && symbolLength == 1)
                symbolLength = 2;
            end

            maxStartSymbol = testCase.numSlotSymbols - symbolLength - 1;
            if maxStartSymbol > 0
                startSymbolIndex = randi([0, maxStartSymbol]);
            else
                startSymbolIndex = 0;
            end

            symbolAllocation = [startSymbolIndex symbolLength];

            % Orthogonal Cover Code Index.
            OCCI = 0;
            if (format == 1)
                % When intraslot frequency hopping is disabled, the OCCI value must be less
                % than the floor of half of the number of OFDM symbols allocated for the PUCCH.
                if ~intraSlotFreqHopping
                    OCCI = randi([0, (floor(symbolLength / 2) - 1)]);
                else
                % When intraslot frequency hopping is enabled, the OCCI value must be less
                % than the floor of one-fourth of the number of OFDM symbols allocated for the PUCCH.
                    maxOCCindex = floor(symbolLength / 4) - 1;
                    if maxOCCindex == 0
                        OCCI = 0;
                    else
                        OCCI = randi([0, maxOCCindex]);
                    end
                end
            elseif (format == 4)
                spreadingFactor = randsample([2 4], 1);
                OCCI = randi([0 spreadingFactor-1]);
            end

            % Additional DM-RS.
            additionalDMRS = false;
            if (format == 3) || (format == 4)
                additionalDMRS = randsample([true false], 1);
            end

            % Randomly select secondHopStartPRB if intra-slot frequency
            % hopping is enabled.
            if intraSlotFreqHopping
                secondHopStartPRB = generateRandomSecondHopPRB(nSizeGrid, PRBSet);
                % Set respective MATLAB parameter.
                frequencyHopping   = 'intraSlot';
            end

            % Configure the carrier according to the test parameters.
            subcarrierSpacing = 15 * (2 .^ numerology);
            carrier = nrCarrierConfig( ...
                NCellID=nCellID, ...
                SubcarrierSpacing=subcarrierSpacing, ...
                NSizeGrid=nSizeGrid, ...
                NStartGrid=nStartGrid, ...
                NSlot=nSlot, ...
                NFrame=nFrame, ...
                CyclicPrefix=cyclicPrefix ...
                );

            % Configure the PUCCH according to the test parameters.
            pucch = createPUCCHConfig(format);
            pucch.SymbolAllocation = symbolAllocation;
            pucch.PRBSet = PRBSet;
            pucch.FrequencyHopping = frequencyHopping;
            pucch.SecondHopStartPRB = secondHopStartPRB;
            pucch.OCCI = OCCI;

            if ((format == 1) || (format == 3) || (format == 4))
                pucch.GroupHopping = groupHopping;
            end % of if ((format == 1) || (format == 3) || (format == 4))

            if (format == 1)
                pucch.InitialCyclicShift = initialCyclicShift;
            end % of if (format == 1)

            if (format == 3) || (format == 4)
                pucch.AdditionalDMRS = additionalDMRS;
            end % of if (format == 3) || (format == 4)

            if (format == 4)
                pucch.SpreadingFactor = spreadingFactor;
            end % of if (format == 4)

            % Call the PUCCH DM-RS symbol processor MATLAB functions.
            [DMRSsymbols, DMRSindices] = srsPUCCHdmrs(carrier, pucch);

            % Set the DM-RS port indexes.
            DMRSindices(:, 3) = ports;

            % Write the complex symbols along with their associated indices
            % into a binary file.
            testCase.saveDataFile('_test_output', testID, ...
                @writeResourceGridEntryFile, DMRSsymbols, DMRSindices);

            % Generate a 'slot_point' configuration string.
            slotPointConfig = cellarray2str({numerology, nSlot}, true);
            % Group hopping string following srsran naming.
            GroupHoppingStr = ['pucch_group_hopping::', upper(groupHopping)];
            % Write as true/false.

            if intraSlotFreqHopping
                secondHopStartPRBStr = cellarray2str({secondHopStartPRB}, true);
            else
                secondHopStartPRBStr = '{}';
            end

            commonConfig = {...
                slotPointConfig, ...                            % slot
                ['cyclic_prefix::', upper(cyclicPrefix)], ...   % cp
                GroupHoppingStr, ...                            % group_hopping
                startSymbolIndex, ...                           % start_symbol_index
                symbolLength, ...                               % nof_symbols
                PRBSet(1), ...                                  % starting_prb
                secondHopStartPRBStr, ...                       % second_hop_prb
                nid, ...                                        % n_id
                portsStr, ...                                   % ports
                };

            % Generate the test case entry.
            if format == 1
                config = {...
                    commonConfig, ...
                    initialCyclicShift, ... % initial_cyclic_shift
                    OCCI, ...               % time_domain_occ
                    };
            elseif format == 2
                config = {...
                    commonConfig, ...
                    nofPRBs, ... % nof_prb
                    nid0, ...    % n_id_0
                    };
            elseif format == 3
                config = {...
                    commonConfig, ...
                    nofPRBs, ...        % nof_prb
                    additionalDMRS, ... % additional_dmrs
                    };
            elseif format == 4
                config = {...
                    commonConfig, ...
                    additionalDMRS, ... % additional_dmrs
                    OCCI, ...           % occ_index
                    };
            end

            % Insert the name of the config type in the test case string.
            configStr = ['dmrs_pucch_estimator::format', ...
                char(string(format)), '_configuration', ...
                cellarray2str(config, true)];

            testCaseString = testCase.testCaseToString(testID, ...
                    {configStr}, false, '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHdmrsUnittest

function secondHopStartPRB = generateRandomSecondHopPRB(gridSize, PRBSet)
%generateRandomSecondHopPRB Randomly select a valid starting PRB
%   of a second hop in the grid.
%
%   Parameters:
%   gridSize - size of the resource grid.
%   PRBSet   - set of PRBs allocated for the first frequency hop.
    nofPRBs  = size(PRBSet, 2);
    gridPRBs = 0:(gridSize - 1);
    PRBcount = nofPRBs;
    if nofPRBs == 1
        % A fixup used for a single allocated PRB.
        PRBcount = PRBcount - 1;
    end
    totalPRBs = gridPRBs + PRBcount;
    validStartIndexes = (~ismember(totalPRBs, PRBSet)) & (totalPRBs < gridSize);

    % Exclude PRBset used by the first hop.
    validStartIndexes(PRBSet + 1) = 0;
    validSecondHopPRBs = gridPRBs(validStartIndexes);
    secondHopStartPRB  = validSecondHopPRBs(randi([1, size(validSecondHopPRBs, 2)]));
end % of function generateRandomSecondHopPRB

function pucch = createPUCCHConfig(format)
    switch format
        case 1
            pucch = nrPUCCH1Config;
        case 2
            pucch = nrPUCCH2Config;
        case 3
            pucch = nrPUCCH3Config;
        case 4
            pucch = nrPUCCH4Config;
        otherwise
            error('Unknown PUCCH format %d', format);
    end
end % of function createPUCCHConfig(format)
