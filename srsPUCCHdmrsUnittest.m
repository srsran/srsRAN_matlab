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
%   srsPDCCHdmrsUnittest Properties (TestParameter):
%
%   NCellID          - PHY-layer cell ID (0...1007).
%   numerology       - Defines the subcarrier spacing (0, 1).
%   format           - PUCCH format (1, 2, 3, 4).
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
%   See also matlab.unittest.

classdef srsPUCCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pucch_processor'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pucch_processor' tests will be erased).
        outputPath = {['testPUCCHdmrs', datestr(now, 30)]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %PUCCH format indexes
        format = {1, 2, 3, 4};

    end % of properties (TestParameter)

    properties(Constant, Hidden)
        randomizeTestvector = randperm(1008)

        %PHY-layer cell ID (0...1007).
        NCellID = num2cell(0:1007)
        
        %Min and max symbol length allowed for each of five PUCCH formats
        formatLengthSymbols = [1 2; 4 14; 1 2; 4 14; 4 14]
        
        %Possible length in number of PRBs for format 3
        prbLengthFormat3 = [1 2 3 4 5 6 8 9 10 12 15 16]
        
        srsFormatName = 'pucch_format::FORMAT_';
        
        numSlotSymbols = 14;
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(obj, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.
            addTestIncludesToHeaderFilePHYsigproc(obj, fileID);
        end

        function addTestDefinitionToHeaderFile(obj, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            addTestDefinitionToHeaderFilePHYsigproc(obj, fileID);
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, format)
        %testvectorGenerationCases Generates a test vector for the given numerology and format,
        %  while using a random NCellID, random NSlot and random symbol and PRB length.

            import srsMatlabWrappers.phy.helpers.srsConfigureCarrier
            import srsMatlabWrappers.phy.helpers.srsConfigurePUCCH
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.cellarray2str

            % generate a unique test ID by looking at the number of files generated so far
            testID = testCase.generateTestID;

            % use a unique NCellID, NSlot and rnti for each test
            randomizedCellID = testCase.randomizeTestvector(testID + 1);
            NCellIDLoc = testCase.NCellID{randomizedCellID};

            % use a random slot number from the allowed range
            if numerology == 0
                NSlotLoc = randi([0, 9]);
            else
                NSlotLoc = randi([0, 19]);
            end
            % format name following srsgnb naming
            formatString = [testCase.srsFormatName, num2str(format)];

            % fixed parameter values
            NSizeGrid  = 52;
            NStartGrid = 0;
            NFrame     = 0;
            CyclicPrefix = 'normal';
            GroupHopping = 'neither';
            FrequencyHopping = 'neither';
            SecondHopStartPRB = 0;

            % fix nid and nid0 to physical CellID
            nid  = NCellIDLoc;
            nid0 = NCellIDLoc;

            % currently fixed to 1 port of random number from [0, 7]
            PDCCHports = randi([0, 7]);
            PDCCHportsStr = cellarray2str({PDCCHports}, true);
            
            % random initial cyclic shift
            InitialCyclicShift = randi([0 11]);
            
            % random start PRB index and length in number of PRBs
            startPRB = randi([0 NSizeGrid - 1]);
            switch format
                case {1 4}
                    nofPRBs = 1;
                    setPRBsAsRange = false;
                case 2
                    nofPRBs = randi([1 16]);
                    setPRBsAsRange = true;
                case 3
                    randId  = randi([1 length(testCase.prbLengthFormat3)]);
                    nofPRBs = testCase.prbLengthFormat3(randId);
                    setPRBsAsRange = true;
            end
            if startPRB + nofPRBs > NSizeGrid
                nofPRBs = NSizeGrid - startPRB;
            end
            % for formats 1 and 4 it is just a scalar
            PRBSet = startPRB;
            % for formats 2 and 3 it is a range
            if setPRBsAsRange
                endPRB = startPRB + nofPRBs;
                PRBSet = startPRB : endPRB;
            end

            if format == 1  %For now only Format 1 is supported
                % random start symbol and length in symbols
                symbolLength = randi([testCase.formatLengthSymbols(format + 1, 1) ...
                                      testCase.formatLengthSymbols(format + 1, 2)]);
                maxStartSymbol = testCase.numSlotSymbols - symbolLength - 1;
                if maxStartSymbol > 0
                    startSymbolIndex = randi([0 maxStartSymbol]);
                else
                    startSymbolIndex = 0;
                end

                % check slot boundaries
%                 if (startSymbolIndex + symbolLength) > testCase.numSlotSymbols
%                     symbolLength = testCase.numSlotSymbols - startSymbolIndex;
%                     % In formats 1, 3 and 4 symbol length can't be less
%                     % than 4 symbols
%                     if format ~= 2 && symbolLength < 4
%                         symbolLength
%                     end
%                 end
                SymbolAllocation = [startSymbolIndex symbolLength];

                % Orhtogonal cover code index
                % When intraslot frequency hopping is disabled, the OCCI value must be less 
                % than the floor of half of the number of OFDM symbols allocated for the PUCCH)
                OCCI = randi([0 floor(symbolLength / 2) - 1]);

                % configure the carrier according to the test parameters
                SubcarrierSpacing = 15 * (2 .^ numerology);
                carrier = srsConfigureCarrier(NCellIDLoc, SubcarrierSpacing, NSizeGrid, ...
                    NStartGrid, NSlotLoc, NFrame, CyclicPrefix);

                % configure the PUCCH according to the test parameters
                pucch = srsConfigurePUCCH(format, SymbolAllocation, PRBSet,...
                    FrequencyHopping, GroupHopping, SecondHopStartPRB, ...
                    InitialCyclicShift, OCCI);

                % call the PDCCH DMRS symbol processor MATLAB functions
                DMRSsymbols = nrPUCCHDMRS(carrier, pucch);
                DMRSindices = nrPUCCHDMRSIndices(carrier, pucch, 'IndexStyle', 'subscript', 'IndexBase', '0based');

                % write each complex symbol into a binary file, and the associated indices to another
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, DMRSsymbols, DMRSindices);

                % generate a 'slot_point' configuration string
                slotPointConfig = cellarray2str({numerology, NSlotLoc}, true);
                % group hopping string following srsgnb naming
                GroupHoppingStr = ['pucch_group_hopping::', upper(GroupHopping)];

                % generate the test case entry
                testCaseString = testCase.testCaseToString(testID, ...
                    {formatString, slotPointConfig, GroupHoppingStr, startSymbolIndex,...
                     symbolLength, startPRB, 'false', 0, nofPRBs, InitialCyclicShift, OCCI, ...
                     'false', nid, nid0, PDCCHportsStr}, false, '_test_output');

                % add the test to the file header
                testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
            end % of if
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUCCHdmrsUnittest