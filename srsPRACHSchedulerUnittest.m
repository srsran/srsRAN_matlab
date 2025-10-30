%srsPRACHSchedulerUnittest Unit tests for the PRACH scheduler.
%   This class implements unit tests for the PRACH scheduler functions 
%   using the matlab.unittest framework. The simplest use consists in
%   creating an object with 
%       testCase = srsPRACHSchedulerUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPRACHSchedulerUnittest Properties (Constant):
%
%   srsBlock                  - The tested block (i.e., 'prach_scheduler').
%   srsBlockType              - The type of the tested block, including layer
%                               (i.e., 'scheduler/common_scheduling').
%   MaxNumSFN                 - Maximum System Frame Number (SFN) period found
%                               in the PRACH configuration TS38.211
%                               Tables 6.3.3.2-2, 6.3.3.2-3 and 6.3.3.2-4.
%   PossibleNumFreqOccasions  - List of possible frequency-domain
%                               occasions.
%   NSizeGrid                 - Carrier bandwidth in resource blocks. Large
%                               enough for fitting the maximum number of
%                               frequency occasions.
%
%   srsPRACHSchedulerUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPRACHSchedulerUnittest Properties (TestParameter):
%
%   DuplexMode          - Duplexing mode FDD, TDD, or TDD-FR2.
%   ConfigurationIndex  - PRACH configuration index.
%
%   srsPRACHSchedulerUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the
%                               provided parameters.
%
%   srsPRACHSchedulerUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test
%                                     header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable 
%                                     declarations) to the test header 
%                                     file.
%
%   See also matlab.unittest.

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

classdef srsPRACHSchedulerUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'prach_scheduler'

        %Type of the tested block.
        srsBlockType = 'scheduler/common_scheduling'

        %Maximum number of system frames.
        MaxNumSFN = 16

        %List of possible frequency-domain occasions.
        %   The number of frequency-domain occasions can be 1, 2, 4
        %   or 8. Currently, only one occasion is supported.
        PossibleNumFreqOccasions = 1

        %Carrier bandwidth in Resource Blocks (RB).
        %   It must be big enough for fitting the maximum number of
        %   frequency-domain occasions.
        NSizeGrid = 270
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'prach_scheduler' tests will be erased).
        outputPath = {['testPRACHScheduler', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Carrier duplexing mode, set to
        %   - FDD for paired spectrum with 15kHz subcarrier spacing, or
        %   - TDD for unpaired spectrum with 30kHz subcarrier spacing.
        %   - TDD-FR2 for unpaired spectrum in frequency range 2 with 120kHz subcarrier spacing.
        DuplexMode = {'FDD', 'TDD', 'TDD-FR2'}

        %PRACH configuration index.
        ConfigurationIndex = num2cell(2:255)
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.

            fprintf(fileID, [...
                '#include "srsran/ran/duplex_mode.h"\n'...
                '#include "srsran/ran/subcarrier_spacing.h"\n'...
                '#include "srsran/ran/resource_allocation/ofdm_symbol_range.h"\n'...
                '#include "srsran/ran/resource_allocation/rb_interval.h"\n'...
                '#include <set>\n'...
                '#include <vector>\n'...
                ]);
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.

            fprintf(fileID, [...
                'struct test_case_t {\n'...
                '  /// Duplex mode used (e.g., TDD, FDD).\n'...
                '  duplex_mode dplx_mode;\n'...
                '  /// PRACH configuration index, as defined in TS38.211 Section 6.3.3.2 Tables 6.3.3.2-{2..4}.\n'...
                '  uint8_t prach_config_index;\n'...
                '  /// Common subcarrier spacing.\n'...
                '  subcarrier_spacing pusch_scs;\n'...
                '  /// System slot indices in which PRACH is enabled.\n'...
                '  std::set<unsigned> active_slots;\n'...
                '  /// Number of slots in a PRACH period.\n'...
                '  unsigned nof_slots_period;\n'...
                '  /// Frequency-domain location of PRACH occasions.\n'...
                '  std::vector<crb_interval> crbs;\n'...
                '  /// Number of subframes that make up a PRACH occasion.\n'...
                '  unsigned nof_subframes;\n'...
                '  /// OFDM symbols enabled for PRACH within active slots.\n'...
                '  ofdm_symbol_range symbols;\n'...
                '};\n'...
                ]);
        end

    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, DuplexMode, ConfigurationIndex)
        %testvectorGenerationCases Generates a test vector for the given
        %   DuplexMode and ConfigurationIndex.
            import srsTest.helpers.cellarray2str

            % Set parameters that depend on the duplex mode.
            switch DuplexMode
                case 'FDD'
                    frequencyRange = 'FR1';
                    configTable = nrPRACHConfig.Tables.ConfigurationsFR1PairedSUL;
                    subcarrierSpacing = 15;
                case 'TDD'
                    frequencyRange = 'FR1';
                    configTable = nrPRACHConfig.Tables.ConfigurationsFR1Unpaired;
                    subcarrierSpacing  = 30;
                case 'TDD-FR2'
                    frequencyRange = 'FR2';
                    configTable = nrPRACHConfig.Tables.ConfigurationsFR2;
                    subcarrierSpacing  = 120;
                    DuplexMode = 'TDD';
                otherwise
                    error('Invalid duplex mode %s', DuplexMode);
            end

            % Set values of subcarrier spacing for this case.
            format = configTable.PreambleFormat(ConfigurationIndex + 1);
            if any(strcmpi(format, {'0', '1', '2'}))
                prachSubcarrierSpacing = 1.25;
            elseif strcmpi(format, '3')
                prachSubcarrierSpacing = 5;
            else
                % Short formats use the main subcarrier spacing.
                prachSubcarrierSpacing = subcarrierSpacing;
            end

            % Generate carrier configuration.
            carrier = nrCarrierConfig(...
                NSizeGrid=testCase.NSizeGrid, ...
                SubcarrierSpacing=subcarrierSpacing ...
                );

            % Generate PRACH configuration.
            prach = nrPRACHConfig(...
                FrequencyRange=frequencyRange, ...
                DuplexMode=DuplexMode, ...
                ConfigurationIndex=ConfigurationIndex, ...
                SubcarrierSpacing=prachSubcarrierSpacing ...
                );

            % Calculate number of frames and slots in a PRACH period. This 
            % is different than prach.PRACHSlotsPerPeriod.
            numFramesPeriod = configTable.x(ConfigurationIndex + 1);
            numSlotsPeriod = numFramesPeriod * carrier.SlotsPerFrame;

            % Reference subcarrier spacing is 15 kHz in FR1, 60 kHz in FR2.
            referenceSubcarrierSpacing = 15;
            if frequencyRange == 'FR2'
                referenceSubcarrierSpacing = 60;
            end

            % The PRACH format is long preamble if the sequence length is 839.
            isLongPreamble = prach.LRA == 839;

            % Starting OFDM symbol of the PRACH occasion. Long preambles
            % use the value from configuration table, whereas short
            % preambles use SymbolLocation from nrPRACHConfig. The starting
            % symbol for the short preamble needs to be taken after the
            % nrPRACHConfig object has been correctly populated.
            if isLongPreamble
                startingSymbol = configTable.StartingSymbol(ConfigurationIndex + 1);
            end

            % Ratio between reference subcarrier spacing and common
            % subcarrier spacing.
            refRatio = carrier.SubcarrierSpacing / referenceSubcarrierSpacing;

            % Active slots in reference numerology.
            if frequencyRange == 'FR1'
                nRefSlots = cell2mat(configTable.SubframeNumber(ConfigurationIndex + 1));
                nSlotsPerSubframe = configTable.PRACHSlotsPerSubframe(ConfigurationIndex + 1);
            else
                nRefSlots = cell2mat(configTable.SlotNumber(ConfigurationIndex + 1));
                nSlotsPerSubframe = configTable.PRACHSlotsPer60kHzSlot(ConfigurationIndex + 1);
            end

            % Active PRACH frames in a period.
            activeFrames = cell2mat(configTable.y(ConfigurationIndex + 1));

            % Active slots in common numerology.
            slots = zeros(1, length(nRefSlots) * length(activeFrames) * refRatio);

            % Iterate list of active frames, get the active slots in the
            % frame and convert them to common numerology.
            for i = 1:length(activeFrames)
                frame = activeFrames(i);
                % Slot offset due to PRACH frame.
                frameSlotOffset = frame * carrier.SlotsPerFrame;

                for j = 1:length(nRefSlots)
                    for k = 0:(refRatio - 1)
                        iSlot = (i - 1) * length(nRefSlots) * refRatio ...
                            + (j - 1) * refRatio + k + 1;
                        slots(iSlot) = nRefSlots(j) * refRatio + frameSlotOffset + k;
                    end
                end
            end

            % Mask used to set PRACH active slots.
            slotMask = zeros(1, numSlotsPeriod);

            % Iterate all possible slots in a period to built a mask with
            % all active slots.
            for nSlot = slots
                isOddSlot = (mod(nSlot, 2) == 1);

                % In long preamble and SCS = 30 kHz, we skip odd slots.
                if (refRatio > 1) && isLongPreamble && isOddSlot
                    continue
                end

                nPRACHSlot = nSlot;
                if isLongPreamble
                    nPRACHSlot = floor(nPRACHSlot / refRatio / prach.SubframesPerPRACHSlot);
                end
                
                prach.NPRACHSlot = nPRACHSlot;

                % In short preamble, determine if the PRACH slot falls in
                % the odd or the even slot when SCS = {30, 120} kHz.
                if ~isLongPreamble
                    if ((frequencyRange == "FR1") && (prach.SubcarrierSpacing == 15)) ...
                            || ((frequencyRange == "FR2") && (prach.SubcarrierSpacing == 60))
                        prach.ActivePRACHSlot = 0;
                    elseif (nSlotsPerSubframe == 1)
                        if ((frequencyRange == "FR1") && (prach.SubcarrierSpacing == 30)) ...
                            || ((frequencyRange == "FR2") && (prach.SubcarrierSpacing == 120))
                            prach.ActivePRACHSlot = 1;
                        end
                    else
                        prach.ActivePRACHSlot = mod(prach.NPRACHSlot, 2);
                    end
                else
                    prach.ActivePRACHSlot = 0;
                end

                % Try to generate PRACH.
                symb = nrPRACH(carrier, prach);

                % In long preamble and SCS = 30 kHz, the starting symbol
                % might fall into the next slot.
                slotOffset = 0;
                if isLongPreamble && (startingSymbol == 7)
                    slotOffset = (startingSymbol * refRatio) / 14;
                end

                % Flag slot as allocated.
                slotMask(nSlot + slotOffset + 1) = ~isempty(symb);

                % Set starting symbol for short preamble.
                if ~isLongPreamble
                    startingSymbol = prach.SymbolLocation;
                end
            end

            testCase.assertTrue(any(slotMask), ...
                sprintf('No slot found for %s %s and index %d.', ...
                frequencyRange, DuplexMode, ConfigurationIndex));
            
            activeSlots = find(slotMask) - 1;

            % Select the first active occasion. For the next step.
            prach.NPRACHSlot = activeSlots(1);

            % In case of long preambles, the index in slotMask takes into
            % account that the starting symbol might fall into a subsequent
            % slot. We need to remove that offset for PRACH generation.
            slotOffset = 0;
            if isLongPreamble && (startingSymbol == 7)
                slotOffset = (startingSymbol * refRatio) / 14;
            end

            prach.NPRACHSlot = prach.NPRACHSlot - slotOffset;
            
            if isLongPreamble
                prach.NPRACHSlot = floor(prach.NPRACHSlot / refRatio / prach.SubframesPerPRACHSlot);
                prach.ActivePRACHSlot = 0;

                % Select the OFDM symbol range of the PRACH occasion.
                numSubframes = prach.SubframesPerPRACHSlot;
                symbols = [startingSymbol, ...
                    startingSymbol + prach.PRACHDuration];
            else
                % Select the odd or even half of the "larger" slot.
                if ((frequencyRange == "FR1") && (prach.SubcarrierSpacing == 15)) ...
                        || ((frequencyRange == "FR2") && (prach.SubcarrierSpacing == 60))
                    prach.ActivePRACHSlot = 0;
                elseif nSlotsPerSubframe == 1
                    if ((frequencyRange == "FR1") && (prach.SubcarrierSpacing == 30)) ...
                        || ((frequencyRange == "FR2") && (prach.SubcarrierSpacing == 120))
                        prach.ActivePRACHSlot = 1;
                    end
                else
                    prach.ActivePRACHSlot = mod(prach.NPRACHSlot, 2);
                end

                % Select the PRACH starting symbol. Needs to be recomputed
                % to pick the value of the first active occasion.
                startingSymbol = prach.SymbolLocation;

                % For PRACH format C0, MATLAB's PRACH resource grid
                % contains 7 symbols.
                if (prach.Format == "C0")
                    startingSymbol = startingSymbol * 2;
                end

                % When the PRACH occasion occurs in the odd half of a
                % "large" slot, the starting symbol in nrPRACHConfig is
                % still referenced to the start of the preceding (even)
                % slot. Therefore, adjust the symbol index accordingly.
                if (prach.ActivePRACHSlot == 1) && (mod(prach.NPRACHSlot, 2) == 1)
                    startingSymbol = startingSymbol - 14;
                end

                % Select the OFDM symbol range of the PRACH occasion.
                numSubframes = 1;
                symbols = [startingSymbol, ...
                    startingSymbol + prach.PRACHDuration];
            end

            % Generate frequency domain occasions. The occasions are
            % aranged in pairs containing the start and stop common 
            % resource blocks.
            numFreqOccasions = testCase.PossibleNumFreqOccasions(...
                randi([1, length(testCase.PossibleNumFreqOccasions)]));
            crbRanges = zeros(2, numFreqOccasions);
            occasionPRBSize = (prach.LRA * prach.SubcarrierSpacing) / (carrier.SubcarrierSpacing * 12);
            for frequencyIndex = 0:numFreqOccasions-1
                prach.FrequencyIndex = frequencyIndex;
                prach.FrequencyStart = randi([0, ceil(testCase.NSizeGrid - occasionPRBSize - 1)]);
                [~, info] = nrPRACHIndices(carrier, prach);
                crbRanges(1, frequencyIndex + 1) = min(info.PRBSet);
                crbRanges(2, frequencyIndex + 1) = max(info.PRBSet);
            end
            crbRanges = num2cell(crbRanges,1);

            % Convert types to srsRAN.
            duplexModeStr = ['duplex_mode::' DuplexMode];
            subcarrierSpacingStr = ['subcarrier_spacing::kHz' ...
                num2str(subcarrierSpacing)];
            
            % Pack all the test case parameters in a cell.
            testCaseCell = { ...
                duplexModeStr, ...        % dplx_mode
                ConfigurationIndex, ...   % prach_config_index
                subcarrierSpacingStr, ... % pusch_scs
                {activeSlots}, ...        % active_sfn
                numSlotsPeriod, ...       % nof_slots_period
                crbRanges, ...            % crbs
                numSubframes, ...         % nof_subframes
                symbols                   % symbols
                };

            % Generate the test case entry line. Test identifier is
            % ignored as there are no test vector files.
            testCaseString = testCase.testCaseToString(0, testCaseCell, false);

            % Add the test to the file header.
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPRACHSchedulerUnittest

