%srsPRACHdemodulator Demodulate a 5G NR PRACH waveform.
%   PRACHSYMBOLS = srsPRACHdemodulator(CARRIER, PRACH, GRIDSET,WAVEFORM,INFO)
%   returns a set of frequency-domain symbols PRACHSYMBOLS comprising the 5G
%   5G NR physical random access channel (PRACH) given input CARRIER and 
%   PRACH parameters, PRACH waveform WAVEFORM and two structure arrays 
%   GRIDINFO and INFO.
%
%   GRIDINFO is a structure array containing information corresponding to the
%   PRACH OFDM modulation. If the PRACH is configured for FR2 or the PRACH 
%   slot for the current configuration spans more than one subframe, some
%   of the OFDM-related information may be different between PRACH slots. 
%   In this case, the info structure is an array of the same length as the
%   number of PRACH slots in the waveform.
%
%   INFO is a structure containing the following fields:
%
%   PRACHSymbols        - PRACH symbols.
%   PRACHIndices        - PRACH indices.
%
%   CARRIER is a Carrier-specific configuration object, as described in
%   <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a> with these properties:
%
%   SubcarrierSpacing   - Subcarrier spacing in kHz.
%   NSizeGrid           - Number of resource blocks.
%
%   PRACH is a PRACH-specific configuration object, as described in
%   <a href="matlab:help('nrPRACHConfig')">nrPRACHConfig</a> with these properties:
%
%   SubcarrierSpacing   - PRACH subcarrier spacing in kHz.
%   LRA                 - Length of Zadoff-Chu preamble sequence.
%
%   See also nrPRACHConfig, nrPRACH, nrPRACHIndices, nrCarrierConfig, srsPRACHgenerator.

function PRACHSymbols = srsPRACHdemodulator(carrier, prach, gridInfo, waveform, info)
    
    % Main PRACH demodulation parameters.
    prachDFTSize = gridInfo.Nfft;
    nofSymbols = length(gridInfo.SymbolLengths);
    NRE = 12;
    K = carrier.SubcarrierSpacing / prach.SubcarrierSpacing;
    PRACHgridSize = carrier.NSizeGrid * K * NRE;
    halfPRACHgridSize = PRACHgridSize / 2;

    % Demodulate the PRACH symbol(s).
    PRACHSymbol = zeros(prach.LRA, 1);
    PRACHSymbols = zeros(prach.LRA * nofSymbols, 1);
    symbolOffset = 0;
    for symbolIndex = 0:nofSymbols-1
        % Symbol-specific PRACH demodulation parameters.
        prachSymbolLength = gridInfo.SymbolLengths(symbolIndex+1);
        prachCPSize = gridInfo.CyclicPrefixLengths(symbolIndex+1);

        % Remove the CP.
        noCPprach = waveform(symbolOffset + prachCPSize + 1 : end);

        % DFT.
        freqPRACH = fft(noCPprach(1:prachDFTSize), prachDFTSize); 
        
        % Upper and lower grid.
        lowerPRACHgrid = freqPRACH(end - halfPRACHgridSize + 1 : end);
        upperPRACHgrid = freqPRACH(1 : halfPRACHgridSize);
    
        % Initial subcarrier.
        kStart = info.PRACHIndices(prach.LRA * symbolIndex + 1) - PRACHgridSize * symbolIndex - 1;
    
        % If the sequence map starts at the lower half of the frequency band.
        if kStart < halfPRACHgridSize
            N = min(halfPRACHgridSize - kStart, prach.LRA);
            % Copy first N subcarriers of the sequence in the lower half grid.
            PRACHSymbol(1 : N) = lowerPRACHgrid(kStart + 1 : kStart + N);
            % Copy the remaining sequence values from the upper half grid.
            if N < prach.LRA
                PRACHSymbol(N + 1 : end) = upperPRACHgrid(1 : prach.LRA-N);
            end
        else
            % Copy the sequence in the upper half grid.
            PRACHSymbol = upperPRACHgrid(kStart - halfPRACHgridSize + 1 : kStart - halfPRACHgridSize + prach.LRA);
        end
    
        % Scale according to the expected Matlab-generated results.
        scaling = sqrt(mean(abs(info.PRACHSymbols(1 : prach.LRA)).^2)) / sqrt(mean(abs(PRACHSymbol).^2));
        PRACHSymbol = PRACHSymbol.' * scaling;

        % Advance the time signal pointer and update the output array.
        symbolOffset = symbolOffset + prachSymbolLength;
        PRACHSymbols(prach.LRA * symbolIndex + 1 : prach.LRA * (symbolIndex + 1)) = PRACHSymbol;
    end
end