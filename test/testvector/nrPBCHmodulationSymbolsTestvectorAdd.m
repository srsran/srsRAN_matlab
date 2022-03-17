%NRPBCHMODULATIONSYMBOLSTESTVECTORADD:
%  Function adding a new testvector to the set created as part of the PBCH modulation symbols unit test.
%  The associated 'pbch_modulator_test_data.h' file will be also generated.
%
%  Call details:
%    NRPBCHMODULATIONSYMBOLSTESTVECTORADD(NCELLID, CW, SSBINDEX, LMAX, TESTID) generates a new
%      testvector, using the values indicated by the input paramters
%        * double NCELLID  - PHY-layer cell ID
%        * double array CW - BCH codeword
%        * double SSBINDEX - index of the SSB
%        * double LMAX     - parameter defining the maximum number of SSBs within a SSB set
%        * double TESTID   - unique test indentifier
%      Besides the input parameters, a random codeword will also be generated for each test
%      using a predefined random seed value.

function outputString = nrPBCHmodulationSymbolsTestvectorAdd(NCellID, cw, SSBindex, Lmax, testID, outputPath)
    % all output files will have a common name basis
    baseFilename = 'pbch_modulator_test_';

    % current fixed parameter values
    numPorts = 1;
    SSBfirstSubcarrier = 0;
    SSBfirstSymbol = 0;
    SSBamplitude = 1;
    SSBports = zeros(numPorts, 1);
    SSBportsStr = convertArrayToString(SSBports);

    % write the BCH codeword to a binary file
    cwFilename = [baseFilename 'input' num2str(testID) '.dat'];
    cwFilenameFull = [outputPath '/' cwFilename];
    writeUint8File(cwFilenameFull, cw);

    % call the PBCH symbol modulation Matlab functions
    [modulatedSymbols, symbolIndices] = nrPBCHmodulationSymbolsGenerate(cw, NCellID, SSBindex, Lmax);

    % write each complex symbol into a binary file, and the associated indices to another
    symbolsFilename = [baseFilename 'output' num2str(testID) '.dat'];
    symbolsFilenameFull = [outputPath '/' symbolsFilename];
    writeResourceGridEntryFile(symbolsFilenameFull, modulatedSymbols, symbolIndices);

    % generate the configuration substring
    configString = sprintf('{%d, %d, %d, %d, %.1f, {%s}}', NCellID, SSBindex, SSBfirstSubcarrier, SSBfirstSymbol, SSBamplitude, SSBportsStr);

    % generate the test case entry
    outputString = sprintf('  {%s, {"%s"}, {"%s"}},\n', configString, cwFilename, symbolsFilename);
end
