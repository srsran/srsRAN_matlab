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

function output_string = nr_pbch_modulation_symbols_testvector_add(NCellID,cw,SSB_index,SSB_Lmax,testID)
    % all output files will have a common name basis
    base_filename = 'pbch_modulator_test_';

    % current fixed parameter values
    nof_ports = 1;
    ssb_first_subcarrier = 0;
    ssb_first_symbol = 0;
    ssb_amplitude = 1;
    ssb_ports = zeros(nof_ports,1);
    ssb_ports_str = '';
    for port=ssb_ports
        ssb_ports_str = [ssb_ports_str, sprintf('%d,', port)];
    end
    ssb_ports_str = ssb_ports_str(1:end-1);
    antenna_port_ix = 0;

    % write the BCH codeword to a binary file
    cw_filename = [base_filename 'data' num2str(testID) '.bin'];
    fileID_cw = fopen(cw_filename,'w');
    for bit=1:length(cw)
        fwrite(fileID_cw,cw(bit),'uint8');
    end
    fclose(fileID_cw);

    % call the PBCH symbol modulation Matlab functions
    [modulated_symbols,symbol_indices] = nr_pbch_modulation_symbols_generate(cw,NCellID,SSB_index,SSB_Lmax);

    % write each complex symbol into a binary file, and the associated indices to another
    symbols_filename = [base_filename 'symbols' num2str(testID) '.bin'];
    fileID_symb = fopen(symbols_filename,'w');
    symbol_indices_filename = [base_filename 'symb_ind' num2str(testID) '.bin'];
    fileID_symb_ix = fopen(symbol_indices_filename,'w');
    symbols_length = length(modulated_symbols);
    % we'll write the number of symbols in the first line of the indices file
    fwrite(fileID_symb_ix,symbols_length,'int');
    for idx=1:symbols_length
        fwrite(fileID_symb,real(modulated_symbols(idx)),'float');
        fwrite(fileID_symb,imag(modulated_symbols(idx)),'float');
        fwrite(fileID_symb_ix,antenna_port_ix,'int');
        fwrite(fileID_symb_ix,symbol_indices(idx,2),'int');
        fwrite(fileID_symb_ix,symbol_indices(idx,1),'int');
    end
    fclose(fileID_symb);
    fclose(fileID_symb_ix);

    output_string = sprintf('  {{%d, %d, %d, %d, %.1f, {%s}}, {"%s"}, {"%s"}, {"%s"}},\n', NCellID, SSB_index, ssb_first_subcarrier, ssb_first_symbol, ssb_amplitude, ssb_ports_str, cw_filename, symbols_filename, symbol_indices_filename);
end
