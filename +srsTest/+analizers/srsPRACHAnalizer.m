%srsPRACHAnalizer Analyzes a PRACH transmission from a PRACH resource grid.
%   srsPRACHAnalizer(PRACH, FILENAME, OFFSET) Analyzes a NR Preamble for 
%   Random Access Channel transmission. PRACH is an object of type 
%   nrPRACHConfig containing the paramaters necessary for the detection.
%   FILENAME indicates the file that contains the IQ samples and OFFSET is
%   the number of samples before the first symbol in the file.
function srsPRACHAnalizer(prach, filename, offset)
    import srsTest.helpers.readComplexFloatFile

    samples = readComplexFloatFile(filename, offset, prach.LRA);


    % Create carrier which is not relevant for the analysis.
    carrier = nrCarrierConfig;

    % Generate PRACH symbols.
    symbols = [];
    while(isempty(symbols))
        symbols = nrPRACH(carrier, prach);
        prach.NPRACHSlot = prach.NPRACHSlot + 1;
    end

    % Perform correlation in frequency domain.
    corrFreq = samples ./  (symbols);

    dftSize = 1920 / prach.SubcarrierSpacing;
    dftData = zeros(1, dftSize);
    dftData(1:ceil(prach.LRA / 2)+1) = corrFreq((end - ceil(prach.LRA / 2)):end);
    dftData((end-floor(prach.LRA / 2)):end) = corrFreq(1:ceil(prach.LRA / 2));
    corrTime = fftshift(ifft(dftData));

    AbsCorrTime = corrTime .* conj(corrTime);
    [~, MaxCorrTimeIndex] = max(AbsCorrTime);

    samplingRateMHz = dftSize * prach.SubcarrierSpacing * 1e-3;
    timeAxisMicros = (0:(dftSize -1)) / samplingRateMHz - dftSize / samplingRateMHz / 2;



    h = figure(1);

    subplot(1, 3, 1);
    plot(20 * log10(abs(samples)));
    title('Frequency domain sequence power');
    xlabel('PRACH Subcarrier index');
    ylabel('Relative power [dB]');
    grid on;

    subplot(1, 3, 2);
    plot(angle(corrFreq) * 180 / pi);
    xlabel('PRACH Subcarrier index');
    ylabel('Angle (deg)');
    title('Frequency domain correlation phase');
    grid on;

    subplot(1, 3, 3);
    hPlot = plot(timeAxisMicros, AbsCorrTime);
    title('Time domain correlation');
    xlabel('Time aligment from window [microseconds]');
    ylabel('Linear power');
    grid on;

    cursorMode = datacursormode(h);
    hDatatip = cursorMode.createDatatip(hPlot);
    pos = [timeAxisMicros(MaxCorrTimeIndex) AbsCorrTime(MaxCorrTimeIndex) 0];
    set(hDatatip, 'Position', pos)         
    updateDataCursors(cursorMode)

end

