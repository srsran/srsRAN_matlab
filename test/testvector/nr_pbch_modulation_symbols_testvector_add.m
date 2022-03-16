% NR_PBCH_MODULATION_SYMBOLS_TESTVECTOR_ADD:
%   Function adding a new testvector to the set created as part of the PBCH modulation symbols unit test.
%   The associated 'pbch_modulator_test_data.h' file will be also generated.
%
%   Call details:
%     NR_PBCH_MODULATION_SYMBOLS_TESTVECTOR_ADD(NCELLID,CW,SSBINDEX,SSBLMAX,TESTID) generates a new
%       testvector, using the values indicated by the input paramters
%         * double NCELLID   - PHY-layer cell ID
%         * double array CW - BCH codeword
%         * double SSB_INDEX - index of the SSB
%         * double SSB_LMAX  - parameter defining the maximum number of SSBs within a SSB set
%         * double TESTID    - unique test indentifier
%       Besides the input parameters, a random codeword will also be generated for each test
%       using a predefined random seed value.

function output_string = nr_pbch_modulation_symbols_testvector_add(NCellID,cw,SSB_index,SSB_Lmax,testID,output_path)
    % all output files will have a common name basis
    base_filename = 'pbch_modulator_test_';

    % current fixed parameter values
    nof_ports = 1;
    ssb_first_subcarrier = 0;
    ssb_first_symbol = 0;
    ssb_amplitude = 1;
    ssb_ports = zeros(nof_ports,1);
    ssb_ports_str = convert_array_to_string(ssb_ports);

    % write the BCH codeword to a binary file
    cw_filename = [base_filename 'input' num2str(testID) '.dat'];
    full_cw_filename = [output_path '/' cw_filename];
    write_uint8_file(full_cw_filename,cw);

    % call the PBCH symbol modulation Matlab functions
    [modulated_symbols,symbol_indices] = nr_pbch_modulation_symbols_generate(cw,NCellID,SSB_index,SSB_Lmax);

    % write each complex symbol into a binary file, and the associated indices to another
    symbols_filename = [base_filename 'output' num2str(testID) '.dat'];
    full_symbols_filename = [output_path '/' symbols_filename];
    write_resource_grid_entry_file(full_symbols_filename,modulated_symbols,symbol_indices);

    % generate the configuration substring
    config_string = sprintf('{%d, %d, %d, %d, %.1f, {%s}}', NCellID, SSB_index, ssb_first_subcarrier, ssb_first_symbol, ssb_amplitude, ssb_ports_str);

    % generate the test case entry
    output_string = sprintf('  {%s,{"%s"},{"%s"}},\n', config_string, cw_filename, symbols_filename);
end
