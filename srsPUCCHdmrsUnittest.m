%srsPUCCHdmrsUnittest Unit tests for PUCCH DMRS processor functions.
%   This class implements unit tests for the PUCCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUCCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUCCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pucch_processor').
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
%   format               - PUCCH format (1, 2).
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

classdef srsPUCCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pucch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pucch_processor' tests will be erased).
        outputPath = {['testPUCCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %PUCCH format indexes (for now only formats 1 and 2 are supported).
        format = {1, 2}

        %Intra-slot frequency hopping usage (inter-slot hopping is not tested).
        intraSlotFreqHopping = {false, true}

        %Two test vectors with randomized parameters (e.g. cell ID, slot number etc.) 
        %are generated for each set of unittest parameters
        testCaseTrial = {1, 2}

    end % of properties (TestParameter)

    properties(Constant, Hidden)
        randomizeTestvector = randperm(1008)

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
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '%s::config_t config;\n', obj.srsBlock);
            fprintf(fileID, ...
                'file_vector<resource_grid_reader_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '};\n');
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

            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsConfigurePUCCH
            import srsLib.phy.upper.signal_processors.srsPUCCHdmrs
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str
            import srsTest.helpers.logical2str;

            % Generate a unique test ID by looking at the number of files
            % generated so far.
            testID = testCase.generateTestID;

            % Use a unique NCellIDLoc, NSlotLoc for each test.
            randomizedCellID = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedCellID};

            % Use a random slot number from the allowed range.
            if numerology == 0
                NSlotLoc = randi([0, 9]);
            else
                NSlotLoc = randi([0, 19]);
            end
            % Format name following srsran naming.
            formatString = [testCase.srsFormatName, num2str(format)];

            % Fixed parameter values.
            NSizeGrid  = 52;
            NStartGrid = 0;
            NFrame     = 0;
            CyclicPrefix = 'normal';
            GroupHopping = 'neither';
            FrequencyHopping = 'neither';
            SecondHopStartPRB = 0;

            % Fix nid and nid0 to physical CellID.
            nid  = NCellIDLoc;
            nid0 = NCellIDLoc;

            % Currently fixed to 1 port of random number from [0, 7].
            ports = randi([0, 7]);
            portsStr = cellarray2str({ports}, true);

            % Random initial cyclic shift.
            InitialCyclicShift = randi([0, 11]);
            
            % Random start PRB index and length in number of PRBs.
            PRBSet  = generateRandomPRBallocation(testCase, NSizeGrid, format);
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

            SymbolAllocation = [startSymbolIndex symbolLength];

            % Orhtogonal Cover Code Index.
            OCCI = 0;
            if (format == 1) || (format == 4)
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
            end

            % Randomly select SecondHopStartPRB if intra-slot frequency
            % hopping is enabled.
            if intraSlotFreqHopping
                SecondHopStartPRB = generateRandomSecondHopPRB(NSizeGrid, PRBSet);
                % Set respective MATLAB parameter.
                FrequencyHopping   = 'intraSlot';
            end

            % Configure the carrier according to the test parameters.
            SubcarrierSpacing = 15 * (2 .^ numerology);
            carrier = srsConfigureCarrier(NCellIDLoc, SubcarrierSpacing, NSizeGrid, ...
                NStartGrid, NSlotLoc, NFrame, CyclicPrefix);

            % Configure the PUCCH according to the test parameters.
            pucch = srsConfigurePUCCH(format, SymbolAllocation, PRBSet,...
                FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
                InitialCyclicShift, OCCI);

            % Call the PUCCH DM-RS symbol processor MATLAB functions.
            [DMRSsymbols, DMRSindices] = srsPUCCHdmrs(carrier, pucch);

            % Set the DM-RS port indexes.
            DMRSindices(:, 3) = ports;
            
            % Write the complex symbols along with their associated indices
            % into a binary file.
            testCase.saveDataFile('_test_output', testID, ...
                @writeResourceGridEntryFile, DMRSsymbols, DMRSindices);

            % Generate a 'slot_point' configuration string.
            slotPointConfig = cellarray2str({numerology, NSlotLoc}, true);
            % Group hopping string following srsran naming.
            GroupHoppingStr = ['pucch_group_hopping::', upper(GroupHopping)];
            % Write as true/false.
            intraSlotFreqHoppingStr = logical2str(intraSlotFreqHopping);

            % Generate the test case entry.
            testCaseString = testCase.testCaseToString(testID, ...
                {formatString, slotPointConfig, ['cyclic_prefix::', upper(CyclicPrefix)], ...
                GroupHoppingStr, startSymbolIndex, symbolLength, PRBSet(1), ...
                intraSlotFreqHoppingStr, SecondHopStartPRB, nofPRBs, InitialCyclicShift, ...
                 OCCI, 'false', nid, nid0, portsStr}, true, '_test_output');

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHdmrsUnittest

function SecondHopStartPRB = generateRandomSecondHopPRB(gridSize, PRBSet)
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
    SecondHopStartPRB  = validSecondHopPRBs(randi([1, size(validSecondHopPRBs, 2)]));
end % of function generateRandomSecondHopPRB
