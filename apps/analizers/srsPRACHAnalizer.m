%srsPRACHAnalizer Analyzes a PRACH transmission from a PRACH resource grid.
%   srsPRACHAnalizer(PRACH, FILENAME, OFFSET) analyzes an NR Preamble for 
%   Random Access Channel transmission. PRACH is an object of type 
%   nrPRACHConfig containing the paramaters necessary for the detection.
%   FILENAME indicates the file that contains the IQ samples and OFFSET is
%   the number of samples before the first symbol in the file (this can be
%   found in the log).
%
%   Example:
%      prach = nrPRACHConfig;
%      prach.SequenceIndex = 1;
%      prach.PreambleIndex = 48;
%
%      srsPRACHAnalizer(prach, '~/Downloads/ul_symbol_handler', 626733);
function srsPRACHAnalizer(prach, filename, offset)
    import srsTest.helpers.readComplexFloatFile

    samples = readComplexFloatFile(filename, offset, prach.LRA);


    % Create carrier which is not relevant for the analysis.
    carrier = nrCarrierConfig;

    % Generate PRACH symbols.
    symbols = [];
    while isempty(symbols)
        symbols = nrPRACH(carrier, prach);
        prach.NPRACHSlot = prach.NPRACHSlot + 1;
    end

    % Perform correlation in frequency domain.
    corrFreq = samples ./ symbols;

    % Select a DFT size that matches the TA timing resolution.
    dftSize = 1920 / prach.SubcarrierSpacing;

    dftData = zeros(1, dftSize);
    dftData(1:prach.LRA) = corrFreq;
    corrTime = fftshift(ifft(dftData));

    AbsCorrTime = corrTime .* conj(corrTime);
    [~, MaxCorrTimeIndex] = max(AbsCorrTime);

    samplingRateMHz = dftSize * prach.SubcarrierSpacing * 1e-3;
    timeAxisMicros = (0:(dftSize -1)) / samplingRateMHz - dftSize / samplingRateMHz / 2;

    % Prepare figure.
    h = figure(1);

    % Plot PRACH frequency response magnitude.
    subplot(1, 3, 1);
    plot(20 * log10(abs(samples)));
    title('Frequency domain sequence power');
    xlabel('PRACH Subcarrier index');
    ylabel('Relative power [dB]');
    grid on;

    % Plot PRACH correlation frequency response phase.
    subplot(1, 3, 2);
    plot(angle(corrFreq) * 180 / pi);
    xlabel('PRACH Subcarrier index');
    ylabel('Angle (deg)');
    title('Frequency domain correlation phase');
    grid on;

    % Plot PRACH correlation in time.
    subplot(1, 3, 3);
    hPlot = plot(timeAxisMicros, AbsCorrTime);
    title('Time domain correlation');
    xlabel('Time aligment from window [microseconds]');
    ylabel('Linear power');
    grid on;

    % Set cursor at the PRACH maximum peak.
    cursorMode = datacursormode(h);
    hDatatip = cursorMode.createDatatip(hPlot);
    pos = [timeAxisMicros(MaxCorrTimeIndex) AbsCorrTime(MaxCorrTimeIndex) 0];
    set(hDatatip, 'Position', pos)         
    updateDataCursors(cursorMode)

end

