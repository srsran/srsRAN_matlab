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

function PRACHSymbols = srsPRACHdemodulator(carrier, prach, gridInfo, waveform, info)
    
    % Main PRACH demodulation parameters.
    prachDFTSize = gridInfo.Nfft;
    nofSymbols = length(info.PRACHSymbols) / prach.LRA;
    NRE = 12;
    K = carrier.SubcarrierSpacing / prach.SubcarrierSpacing;
    PRACHgridSize = carrier.NSizeGrid * K * NRE;
    halfPRACHgridSize = PRACHgridSize / 2;

    nAntennas = size(waveform, 2);

    carrierInfo = nrOFDMInfo(carrier);

    % Demodulate the PRACH symbol(s).
    PRACHSymbolTmp = complex(nan(prach.LRA, nAntennas));
    PRACHSymbols = complex(nan(prach.LRA * nofSymbols, nAntennas));
    symbolOffset = 0;
    for symbolIndex = 0:nofSymbols-1
        % Symbol-specific PRACH demodulation parameters.
        prachSymbolLength = gridInfo.SymbolLengths(symbolIndex+1);
        prachCPSize = gridInfo.CyclicPrefixLengths(symbolIndex+1);

        % Remove the CP.
        noCPprach = waveform(symbolOffset + prachCPSize + 1 : end , :);

        % DFT.
        freqPRACH = fft(noCPprach(1:prachDFTSize, :), prachDFTSize);
        
        % Upper and lower grid.
        lowerPRACHgrid = freqPRACH(end - halfPRACHgridSize + 1 : end, :);
        upperPRACHgrid = freqPRACH(1 : halfPRACHgridSize, :);
    
        % Initial subcarrier.
        kStart = info.PRACHIndices(prach.LRA * symbolIndex + 1) - PRACHgridSize * symbolIndex - 1;
    
        % If the sequence map starts at the lower half of the frequency band.
        if kStart < halfPRACHgridSize
            N = min(halfPRACHgridSize - kStart, prach.LRA);
            % Copy first N subcarriers of the sequence in the lower half grid.
            PRACHSymbolTmp(1:N, :) = lowerPRACHgrid(kStart + 1 : kStart + N, :);
            % Copy the remaining sequence values from the upper half grid.
            if N < prach.LRA
                PRACHSymbolTmp(N + 1 : end, :) = upperPRACHgrid(1 : prach.LRA-N, :);
            end
        else
            % Copy the sequence in the upper half grid.
            PRACHSymbolTmp = upperPRACHgrid(kStart - halfPRACHgridSize + 1 : kStart - halfPRACHgridSize + prach.LRA, :);
        end
    
        % Revert power scaling: MATLAB scales the transmitted power so that the
        % PSD is one when normalized wrt the carrier SCS (whereas we want a PSD
        % of LRA when nomralized wrt the PRACH SCS).
        scaling = sqrt(prach.LRA) / sqrt(prachDFTSize / carrierInfo.Nfft);
        PRACHSymbolTmp = PRACHSymbolTmp * scaling;

        % Advance the time signal pointer and update the output array.
        symbolOffset = symbolOffset + prachSymbolLength;
        PRACHSymbols(prach.LRA * symbolIndex + 1 : prach.LRA * (symbolIndex + 1), :) = PRACHSymbolTmp;
    end
end
