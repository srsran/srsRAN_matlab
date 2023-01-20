%srsPRACHdemodulator Demodulate a 5G NR PRACH waveform.
%   [WAVEFORM,GRIDSET,INFO] = srsPRACHgenerator(CARRIER, PRACH)
%   generates a 5G NR physical random access channel (PRACH) waveform
%   WAVEFORM given input CARRIER and PRACH parameters. The function also
%   returns two structure arrays, GRIDSET and INFO.
%
%   GRIDSET is a structure array containing the following fields:
%
%   ResourceGrid        - PRACH resource grid
%   Info                - Structure with information corresponding to the
%                         PRACH OFDM modulation. If the PRACH is configured 
%                         for FR2 or the PRACH slot for the current
%                         configuration spans more than one subframe, some
%                         of the OFDM-related information may be different
%                         between PRACH slots. In this case, the info
%                         structure is an array of the same length as the
%                         number of PRACH slots in the waveform.
%
%   INFO is a structure containing the following fields:
%
%   NPRACHSlot          - PRACH slot number of the allocated PRACH
%                         preamble. 
%   PRACHSymbols        - PRACH symbols.
%   PRACHSymbolsInfo    - Additional information associated with the 
%                         symbols.
%   PRACHIndices        - PRACH indices.
%   PRACHIndicesInfo    - Additional information associated with indices.
%
%   CARRIER is a Carrier-specific configuration object, as described in
%   <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a> with these properties:
%
%   SubcarrierSpacing   - Subcarrier spacing in kHz.
%   CyclicPrefix        - Cyclic prefix.
%   NSizeGrid           - Number of resource blocks.
%
%   PRACH is a PRACH-specific configuration object, as described in
%   <a href="matlab:help('nrPRACHConfig')">nrPRACHConfig</a> with these properties:
%
%   FrequencyRange      - Frequency range (used in combination with
%                         DuplexMode to select a configuration table
%                         from TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4)
%   DuplexMode          - Duplex mode (used in combination with
%                         FrequencyRange to select a configuration table
%                         from TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4).
%   ConfigurationIndex  - Configuration index, as defined in TS 38.211
%                         Tables 6.3.3.2-2 to 6.3.3.2-4.
%   SubcarrierSpacing   - PRACH subcarrier spacing in kHz.
%   SequenceIndex       - Logical root sequence index.
%   PreambleIndex       - Scalar preamble index within cell.
%   RestrictedSet       - Type of restricted set.
%   ZeroCorrelationZone - Cyclic shift configuration index.
%   RBOffset            - Starting resource block (RB) index of the initial 
%                         uplink bandwidth part (BWP) relative to carrier
%                         resource grid.
%   FrequencyStart      - Frequency offset of lowest PRACH transmission
%                         occasion in the frequency domain with respect to 
%                         PRB 0 of the initial uplink BWP.
%   FrequencyIndex      - Index of the PRACH transmission occasions in
%                         frequency domain.
%   TimeIndex           - Index of the PRACH transmission occasions in time
%                         domain. 
%   ActivePRACHSlot     - Active PRACH slot number within a subframe or a
%                         60 kHz slot. 
%   NPRACHSlot          - PRACH slot number.
%
%   Example:
%   % Generate a 10ms PRACH waveform for the default values for
%   % nrPRACHConfig and nrCarrierConfig. Display the PRACH-related OFDM
%   % information.
%
%   carrier = nrCarrierConfig;
%   prach = nrPRACHConfig;
%   [waveform, gridset, info] = srsPRACHgenerator(carrier, prach);
%   disp(gridset.Info)
%
%
%   See also nrPRACHOFDMModulate, nrPRACHOFDMInfo, nrPRACHConfig,
%   nrPRACHGrid, nrPRACH, nrPRACHIndices, nrCarrierConfig.

function PRACHSymbols = srsPRACHdemodulator(carrier, prach, gridset, waveform, info)
    
    % Main PRACH demodulation parameters.
    prachDFTSize = gridset.Info.Nfft;
    nofSymbols = length(gridset.Info.SymbolLengths);
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
        prachSymbolLength = gridset.Info.SymbolLengths(symbolIndex+1);
        prachCPSize = gridset.Info.CyclicPrefixLengths(symbolIndex+1);

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