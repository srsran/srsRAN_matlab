% NR_PBCH_MODULATION_SYMBOLS_SRS_PHY_TEST:
%   Function testing the PBCH symbol modulation functions implemented by the SRS PHY.
%
%   Call details:
%     (i) TEST_RESULT = NR_PBCH_MODULATION_SYMBOLS_SRS_PHY_TEST
%       Tests the following configuration variations
%         * carrier
%             - NCellID: [0,..,1007]
%         * SSB
%             - index: [0,..,7]
%             - L_max: [4,8,64]
%         * PBCH
%             - cw: randomly generated for each test
%       and returns
%         * struct array TEST_RESULT with the following fields per test
%             - int32 TEST_IX - number of tests executed
%             - int32 OK_TEST - number of passed tests
%             - int32 KO_TEST - number of failed tests
%
%     (ii) TEST_RESULT = NR_DMRS_PDCCH_SRS_PHY_TEST(SPECIFIC_CONFIG)
%       Tests the specific configuration requrested by the user through the input parameters
%         * struct SPECIFIC_CONFIG - specifies a test configuration using the following parameters
%             - double NCELLID - PHY-layer cell ID
%             - double SSB_INDEX - index of the SSB
%             - double SSB_LMAX - parameter defining the maximum number of SSBs within a SSB set
%             - double array CW - BCH codeword
%       and returns
%         * struct TEST_RESULT with the following fields
%             - int32 TEST_IX - number of tests executed
%             - int32 OK_TEST - number of passed tests
%             - int32 KO_TEST - number of failed tests
%
%  Output log format:
%     A log file specifying the number of executed tests, jointly with a count of those passed/failed
%     and the elapsed execution time, is generated. The log file will be found under 'phy_test_outputs'
%     in the current execution folder. For each failed test, this file will also log its configuration
%     parameters and computed mse.

function test_result = nr_pbch_modulation_symbols_srs_phy_test(varargin)

    startTime = tic();

    % test control initialization
    test_result.test_ix = 0;
    test_result.ok_test = 0;
    test_result.ko_test = 0;

    % load the SRS gNB functions to be tested
    output_path = import_srsGNB;
    fileID = fopen([output_path '/nr_pbchmodulation_symbols_srs_phy_test.log'],'w');

    % see which kind of test has been requested by the user
    [test_specific_config,specific_config] = processInputs(varargin{:});

    %% test of a single user-forced configuration
    if test_specific_config
        % configure the carrier parameters
        NCellID = specific_config.NCellID;

        % configure the SSB parameters
        SSB_index = specific_config.SSB_index;
        SSB_Lmax = specific_config.SSB_Lmax;

        % configure the PBCH parameters
        cw = specific_config.cw;

        % PBCH symbol modulation (5G toolbox)
        [modulated_symbols,symbol_indices] = nr_pbch_modulation_symbols_generate(cw,NcellID,SSB_index,SSB_Lmax);

        // % get the PDCCH DMRS symbols
        // mat_grid = zeros(carrier.NSizeGrid * 12,carrier.SymbolsPerSlot);
        // mat_grid(pdcchDMRSIndices) = mat_symbols;
        //
        // % flatten the structures
        // carrier_flat = flatten_struct(carrier);
        // pdcch_flat = flatten_struct(pdcch);
        // pdcch_flat.CORESET = flatten_struct(CORESET);
        // pdcch_flat.SearchSpace = flatten_struct(pdcch.SearchSpace);
        //
        // % PBCH symbol modulation (SRS PHY functions)
        // [srs_symbols,srs_indices] = srsgnb_nr_pbch_symbol_modulation(carrier_flat, pdcch_flat);
        //
        // % get the PDCCH DMRS symbols
        // srs_symbols = srs_grid(pdcchDMRSIndices);
        //
        // % mse computation
        // mse = mean(abs(mat_symbols - srs_symbols));
        //
        // test_result.mse = mse;
        //
        // % test evaluation
        // if mse > abs(1e-6)
        //     close all;
        //
        //     figure(1);
        //     subplot(3,1,1);
        //     surf(abs(mat_grid));
        //     subplot(3,1,2);
        //     surf(abs(srs_grid));
        //     subplot(3,1,3);
        //     surf(abs(mat_grid - srs_grid));
        //
        //     figure(2); clf; grid on; hold on;
        //     plot(abs(mat_grid(:,1)), 'o');
        //     plot(abs(mat_grid(:,2)), 'x');
        //
        //     figure(2); clf;
        //     subplot(1,2,1); grid on; hold on;
        //     plot(real(mat_symbols), 'o');
        //     plot(real(srs_symbols), 'x');
        //
        //     subplot(1,2,2); grid on; hold on;
        //     plot(imag(mat_symbols), 'o');
        //     plot(imag(srs_symbols), 'x');
        //     legend('MAT', 'SRS');
        //
        //     fprintf(2, '\n[TEST KO] Error is too high - mse: %d\n', mse);
        //
        //     test_result.ko_test = test_result.ko_test + 1;
        //     test_result.test_ix = test_result.test_ix + 1;
        //     %log failed test configuration
        //     logResults(fileID,test_result.test_ix,carrier,CORESET,pdcch,mse);
        // else
        //     test_result.ok_test = test_result.ok_test + 1;
        //     test_result.test_ix = test_result.test_ix + 1;
        //
        //     fprintf('\n[TEST OK] Error is below threshold - mse: %d\n', mse);
        // end
    %% test all currently supported configuration variations
    else
        // search_space_types={'common'};
        // mapping_types={'interleaved','noninterleaved'};
        //
        // for BW = [25,52,106]
        //     for SCS = 15
        //         % configure the carrier
        //         carrier = nrCarrierConfig;
        //         carrier.SubcarrierSpacing = SCS;
        //         carrier.NSizeGrid = BW;
        //         carrier.NCellID = 1;
        //
        //         FrequencyResourcesN = floor(carrier.NSizeGrid / 6);
        //
        //         for SearchSpaceType = 1:length(search_space_types)
        //             for Duration = 1:3
        //                 for CCEREGmappingCCE = 1:length(mapping_types)
        //                     for AggregationLevel=[1,2,4,8,16]
        //                         for FrequencyResources = 1:(2^FrequencyResourcesN - 1)
        //                             % configure the coreset
        //                             CORESET = nrCORESETConfig();
        //                             CORESET.FrequencyResources = int2bit(FrequencyResources,FrequencyResourcesN).';
        //                             CORESET.InterleaverSize = 2;
        //                             CORESET.REGBundleSize = 6;
        //                             CORESET.CCEREGMapping = mapping_types{CCEREGmappingCCE};
        //                             CORESET.Duration=Duration;
        //
        //                             % do not try encoding a PDCCH if it does not fit
        //                             if sum(CORESET.FrequencyResources)*Duration < AggregationLevel || (strcmp(CORESET.CCEREGMapping,'interleaved') && mod(sum(CORESET.FrequencyResources)*Duration,CORESET.InterleaverSize*CORESET.REGBundleSize) > 0)
        //                                 continue;
        //                             end
        //
        //                             % configure the PDCCH
        //                             pdcch = nrPDCCHConfig('CORESET', CORESET);
        //                             pdcch.NStartBWP = 0;
        //                             pdcch.NSizeBWP = carrier.NSizeGrid;
        //                             pdcch.RNTI = 0;
        //                             pdcch.AggregationLevel = AggregationLevel;
        //                             pdcch.SearchSpace.SearchSpaceType = search_space_types{SearchSpaceType};
        //
        //                             for AllocatedCandidate=1:pdcch.SearchSpace.NumCandidates(floor(log2(AggregationLevel)) + 1)
        //                                 for NSlot = 0:9
        //                                     carrier.NSlot = NSlot;
        //                                     pdcch.AllocatedCandidate = AllocatedCandidate;
        //
        //                                     % PDCCH DRMS encoding (5G toolbox)
        //                                     [mat_symbols,pdcchDMRSIndices] = nr_dmrs_pdcch_generate(carrier,pdcch);
        //
        //                                     % get the PDCCH DMRS symbols
        //                                     mat_grid = zeros(carrier.NSizeGrid * 12,carrier.SymbolsPerSlot);
        //                                     mat_grid(pdcchDMRSIndices) = mat_symbols;
        //
        //                                     % flatten the structures
        //                                     carrier_flat = flatten_struct(carrier);
        //                                     pdcch_flat = flatten_struct(pdcch);
        //                                     pdcch_flat.CORESET = flatten_struct(CORESET);
        //                                     pdcch_flat.SearchSpace = flatten_struct(pdcch.SearchSpace);
        //
        //                                     % PDCCH DMRS encoding (SRS PHY functions)
        //                                     srs_grid = srsran_nr_dmrs_pdcch_encode(carrier_flat, pdcch_flat);
        //
        //                                     % get the PDCCH DMRS symbols
        //                                     srs_symbols = srs_grid(pdcchDMRSIndices);
        //
        //                                     % mse computation
        //                                     mse = mean(abs(mat_symbols - srs_symbols));
        //                                     test_result.mse = mse;
        //
        //                                     % test evaluation and log
        //                                     if mse > abs(1e-6)
        //                                         test_result.ko_test = test_result.ko_test + 1;
        //                                         %log failed test configuration
        //                                         logResults(fileID,test_result.test_ix,carrier,CORESET,pdcch,mse);
        //                                     else
        //                                         test_result.ok_test = test_result.ok_test + 1;
        //                                     end
        //                                     test_result.test_ix = test_result.test_ix + 1;
        //                                 end
        //                             end
        //                         end
        //                     end
        //                 end
        //             end
        //         end
        //     end
        // end

    end

    executionTime = toc(startTime);
    fprintf(fileID,'\nNumber of tested configurations: %d - %d OK, %d KO (total time %d s)\n', test_result.test_ix, test_result.ok_test, test_result.ko_test, executionTime);

    fclose(fileID);
end

%% helper functions

function [test_specific_config,specific_config] = processInputs(varargin)
    p = inputParser;

    test_specific_config = false;
    specific_config = [];
    addOptional(p, 'specific_config', specific_config);

    parse(p,varargin);
    % we are not explicitly validating the structure format
    if ~isempty(p.Results.specific_config)
        specific_config.NCellID = p.Results.specific_config{1}.NCellID;
        specific_config.SSB_index = p.Results.specific_config{1}.SSB_index;
        specific_config.SSB_Lmax = p.Results.specific_config{1}.SSB_Lmax;
        specific_config.cw = p.Results.specific_config{1}.cw;
        test_specific_config = true;
    end
end

function flat_struct = flatten_struct(input_struct)
    field_names = fieldnames(input_struct);
    for field_name=field_names'
        flat_struct.(field_name{1}) = input_struct.(field_name{1});
    end
end

function logResults(fileID,test_ix,carrier,CORESET,pdcch,mse)
    fprintf(fileID, '============= test %d =============\n', test_ix);
    fprintf(fileID, 'carrier: bw = %d, scs = %d, PCI = %d, slot = %d\n', test_result.carrier.NSizeGrid, test_result.carrier.SubcarrierSpacing, test_result.carrier.NCellID, test_result.carrier.NSlot);
    fprintf(fileID, 'CORESET: freq res = %s, intlv size = %d, REG bnd size = %d, mapping type = %s, duration = %d\n', num2str(test_result.CORESET.FrequencyResources), test_result.CORESET.InterleaverSize, test_result.CORESET.REGBundleSize, test_result.CORESET.CCEREGMapping, test_result.CORESET.Duration);
    fprintf(fileID, 'pdcch: BWP start:size = %d:%d, RNTI = %d, agg lev = %d, ss type = %d, candidate= %d\n', test_result.pdcch.NStartBWP, test_result.pdcch.NSizeBWP, test_result.pdcch.RNTI, test_result.pdcch.AggregationLevel, test_result.pdcch.SearchSpace.SearchSpaceType, test_result.pdcch.AllocatedCandidate);
    fprintf(fileID, 'result: FAILED (mse = %d)\n', test_result.mse);
end
