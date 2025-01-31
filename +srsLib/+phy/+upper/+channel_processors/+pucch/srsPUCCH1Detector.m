%srsPUCCH1Detector PUCCH Format 1 processor.
%   Detects a PUCCH transmission (or multiple, multiplexed ones).
%
%   Syntax
%     results = srsPUCCH1Detector(carrier, pucch, rxGrid, ouci)
%        detects the transmission specified by the pucch configuration object,
%        assuming ouci bits were transmitted.
%     results = srsPUCCH1Detector(carrier, pucch, rxGrid, multiplexList)
%        detects multiplexed PUCCH transmissions. With this syntax, input pucch
%        specifies the time-frequency allocation, while multiplexList specifies
%        all initial cyclic shifts and orthogonal cover code indices that are
%        multiplexed on the same time-frequency resources, as well as the number
%        of bits.
%     [results, epre, noiseVar] = srsPUCCH1Detector(___) also returns the
%        estimated EPRE and noise variance across the PUCCH allocated REs.
%
%   Input arguments
%     carrier        - nrCarrierConfig object with the carrier configuration parameters.
%                      This function only uses the properties 'NSizeGrid', 'NCellID',
%                      'CyclicPrefix', 'NSlot', and 'NStartGrid'
%     pucch          - nrPUCCH1Config object with the PUCCH Format 1 configuration
%                      parameters
%     rxGrid         - resource grid with complex-valued samples. Dimensions are
%                      number of subcarries, number of OFDM symbols in a slot and
%                      number of receive antenna ports
%     ouci           - Number of uncoded UCI bits
%     multiplexList  - List of multiplexed PUCCH transmissions as a structure array
%                      with fields 'InitialCyclicShift', 'OCCI', and 'NumBits'
%                      (number of UCI bits)
%
%   The output is a structure array (one entry per processed PUCCH) with fields
%      'InitialCyclicShift' - initial cyclic shift
%      'OCCI'               - orthogonal cover code index
%      'isValid'            - true if the corresponding PUCCH transmission has been detected
%      'DetectionMetric'    - value of the detection metric (normalized with respect to the
%                             threshold value)
%      'Bits'               - detected UCI bits
%      'Symbol'             - the received constellation symbol
%      'RSRP'               - reference signal received power
%
% Note: Group hopping is not currently supported.
% Note: Conversely to nrPUCCHDecode, ouci or field NumBits must be set to zero
%       (not one) to decode PUCCH transmissions with SR. In this case, the output
%       field Bits will be empty and a successful detection will only be indicated
%       by field isValid set to true.
%
% See also nrPUCCH1Config, nrCarrierConfig, nrPUCCHDecode.

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

function [results, epre, noiseVar] = srsPUCCH1Detector(carrier, pucch, rxGrid, lastInput)
    arguments
        carrier       (1, 1) nrCarrierConfig
        pucch         (1, 1) nrPUCCH1Config
        rxGrid    (:, 14, :) double {srsTest.helpers.mustBeResourceGrid}
        lastInput
    end

    if isnumeric(lastInput)
        % If the last input is numeric, it is understood as the payload size, which should not be larger than 2.
        argIndex = 4;
        validateattributes(lastInput, 'double', {'scalar', 'integer', 'nonnegative', '<=', 2}, mfilename, 'ouci', argIndex);
        multiplexList = struct( ...
            'InitialCyclicShift', pucch.InitialCyclicShift, ...
            'OCCI', pucch.OCCI, ...
            'NumBits', lastInput ...
            );
    elseif isstruct(lastInput)
        % If the last input is a struct array, then it is understood as a list of multiplexed PUCCHs.
        mustBeMultiplexList(lastInput);
        multiplexList = lastInput;
    else
        eidType = 'srsPUCCH1Detector:wrongInput';
        msgType = 'The last input should be either a scalar integer or a structure array.';
        error(eidType, msgType);
    end

    nSubcarriers = size(rxGrid, 1);
    assert(mod(nSubcarriers, 12) == 0, 'The resource grid does not have an integer number of PRBs.');
    nPRBs = nSubcarriers / 12;

    assert(nPRBs == carrier.NSizeGrid, 'The resource grid size does not match the carrier configuration.');

    assert(strcmp(pucch.GroupHopping, 'neither'), 'Group hopping not supported.');

    assert(~strcmp(pucch.FrequencyHopping, 'interSlot'), ...
        'Inter-slot frequency hopping not supported.');
    assert(pucch.PRBSet < nPRBs, 'PUCCH F1 PRB set outside the resource grid.');

    ishopping = strcmp(pucch.FrequencyHopping, 'intraSlot');
    if ishopping
        assert(pucch.SecondHopStartPRB < nPRBs, 'PUCCH F1 PRB set outside the resource grid.');

        maxOCCI = floor(pucch.SymbolAllocation(2) / 4);
    else
        maxOCCI = floor(pucch.SymbolAllocation(2) / 2);
    end

    % Check the OCCIs in the multiplexed list agree with the resource allocation.
    assert(all([multiplexList.OCCI] < maxOCCI), ...
        'With the current configuration, the OCC index must be less than %d.', maxOCCI);

    if isempty(pucch.HoppingID)
        nID = carrier.NCellID;
    else
        nID = pucch.HoppingID;
    end

    % Compute PUCCH cycling shift information - the last two inputs are the initial
    % cyclic shift (set to zero since we look for the "base" alpha) and the sequence
    % cyclic shift (always zero for PUCCH F1).
    info = nrPUCCHHoppingInfo(carrier.CyclicPrefix, mod(carrier.NSlot, carrier.SlotsPerFrame), nID, pucch.GroupHopping, 0, 0);

    % For each hop, each port provides two contributions, one from the DM-RS symbols and one from the data ones.
    nContributions = size(rxGrid, 3) * 2;
    [hopData, epre, epreSamples, noiseVar, noiseSamples1] = processHop(pucch.PRBSet, info, carrier, pucch, rxGrid, multiplexList);
    noiseSamples2 = 0;
    if isequal(pucch.FrequencyHopping, 'intraSlot')
        [hopData2, epre2, epreSamples2, noiseVar2, noiseSamples2] = processHop(pucch.SecondHopStartPRB, info, carrier, pucch, rxGrid, multiplexList);
        nContributions = nContributions * 2;
        epre = epre + epre2;
        epreSamples = epreSamples + epreSamples2;
        noiseVar = noiseVar + noiseVar2;
    end
    epre = epre / epreSamples;
    noiseVar = noiseVar / (noiseSamples1 + noiseSamples2);

    switch nContributions
        case 2
            % One port no frequency hppping.
            threshold = 0.9;
        case 4
            % One port and frequency hopping or two ports and no frequency hopping.
            threshold = 3;
        case 8
            % Two ports and frequency hopping or four ports and no frequency hopping.
            threshold = 4.45;
        case 16
            % Four ports and frequency hopping.
            threshold = 6.95;
        otherwise
            error('srsPUCCH1Detector:WrongCongiguration', ...
                'The configuration results in %d degrees of freedom, which is not supported.', nContributions);
    end

    nPucch = numel(multiplexList);
    results(nPucch) = struct( ...
        'InitialCyclicShift', nan, ...
        'OCCI', nan, ...
        'isValid', false, ...
        'DetectionMetric', nan, ...
        'Bits', [], ...
        'Symbol', complex(nan, nan), ...
        'RSRP', nan ...
        );

    for iPucch = 1:nPucch
        ics = multiplexList(iPucch).InitialCyclicShift;
        occi = multiplexList(iPucch).OCCI;
        nBits = max(1, multiplexList(iPucch).NumBits);
        resKey = "ICS" + ics + "OCCI" + occi;
        metricNumeratorMain = hopData(resKey).NumeratorContrMain;
        metricNumeratorCrossTmp = hopData(resKey).NumeratorContrCross;
        rsrp = mean(abs(hopData(resKey).EstimatedChannel).^2);

        if isequal(pucch.FrequencyHopping, 'intraSlot')
            assert(hopData2(resKey).ICS == hopData(resKey).ICS, 'The initial cyclic shifts of the two hops do not match.');
            assert(hopData2(resKey).OCCI == hopData(resKey).OCCI, 'The OCCIs of the two hops do not match.');
            metricNumeratorMain = metricNumeratorMain + hopData2(resKey).NumeratorContrMain;
            metricNumeratorCrossTmp = metricNumeratorCrossTmp + hopData2(resKey).NumeratorContrCross;
            rsrpTmp = mean(abs(hopData2(resKey).EstimatedChannel).^2);

            rsrp = (rsrp * noiseSamples1 + rsrpTmp * noiseSamples2) / (noiseSamples1 + noiseSamples2);
        end

        [metricNumeratorCross, rxSymbol, uciBits] = detectsymbol(metricNumeratorCrossTmp, nBits);
        % Detection.
        detectionMetric = (metricNumeratorMain + 2 * metricNumeratorCross) / noiseVar;
        isDetected = (detectionMetric > threshold);

        % When detecting an SR PUCCH (NumBits == 0), the only valid result is uciBits == 0.
        if (multiplexList(iPucch).NumBits == 0)
            isDetected = isDetected && (uciBits == 0);
            uciBits = [];
        end

        results(iPucch).InitialCyclicShift = ics;
        results(iPucch).OCCI = occi;
        results(iPucch).isValid = isDetected;
        results(iPucch).DetectionMetric = detectionMetric / threshold;
        results(iPucch).Bits = uciBits;
        results(iPucch).Symbol = rxSymbol;
        results(iPucch).RSRP = rsrp;
    end % of for nPucch = 1:nPucch
end % of function srsPUCCH1Detector()

% Checks that the list of multiplexed PUCCH transmissions is valid.
function mustBeMultiplexList(a)
    arguments
        a (:, 1) struct
    end

    % Check that each element of the list is a struct with the proper fields.
    if ~isempty(setxor(fieldnames(a), {'InitialCyclicShift', 'OCCI', 'NumBits'}))
        eidType = 'mustBeMultiplexList:wrongFormat';
        msgType = ['All multiplexList entries should be structures with fields ''InitialCyclicShift'', ', ...
            '''OCCI'' and ''NumBits''.'];
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the initial cyclic shifts are within bounds.
    isICSDefined = all(arrayfun(@(x) ~isempty(x.InitialCyclicShift), a));
    allShifts = [a.InitialCyclicShift];
    isICSInteger = isICSDefined && all(mod(allShifts, 1) == 0);
    isICSInRange = isICSInteger && all(allShifts >= 0) && all(allShifts <= 11);
    if  ~isICSInRange
        eidType = 'mustBeMultiplexList:wrongInitialCyclicShift';
        msgType = 'All initial cyclic shifts must be integers between 0 and 11 included.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the OCCIs are within bounds (unfortunately, we can only check that the OCCI
    % is at most 6, not the true upperbound that depends on the allocated grant).
    isOCCIDefined = all(arrayfun(@(x) ~isempty(x.OCCI), a));
    allOCCI = [a.OCCI];
    isOCCIInteger = isOCCIDefined && all(mod(allOCCI, 1) == 0);
    isOCCIInRange = isOCCIInteger && all(allOCCI >= 0) && all(allOCCI <= 6);
    if  ~isOCCIInRange
        eidType = 'mustBeMultiplexList:wrongOCCI';
        msgType = 'All OCCI must be integers between 0 and 6 included.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the payload size.
    isBitsDefined = all(arrayfun(@(x) ~isempty(x.NumBits), a));
    allBits = [a.NumBits];
    isBitsInteger = isBitsDefined && all(mod(allBits, 1) == 0);
    isBitsInRange = isBitsInteger && all(allBits >= 0) && all(allBits <= 2);
    if  ~isBitsInRange
        eidType = 'mustBeMultiplexList:wrongNumBits';
        msgType = 'All number of bits must be integers between 0 and 2 included.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Cannot mix SR and ACK PUCCHs.
    nSR = sum(allBits == 0);
    if ((nSR > 0) && (nSR < numel(allBits)))
        eidType = 'mustBeMultiplexList:mixedPUCCHTypes';
        msgType = 'Cannot mix PUCCH carrying HARQ-ACK bits and PUCCH carrying SR bits.';
        throwAsCaller(MException(eidType, msgType));
    end

    % Check the uniqueness of the entries.
    aHash = 12 * allShifts + allOCCI;
    if numel(unique(aHash)) ~= numel(a)
        eidType = 'mustBeMultiplexList:duplicatedEntry';
        msgType = 'Cyclic shift-OCCI pairs should not be repeated.';
        throwAsCaller(MException(eidType, msgType));
    end
end % of function mustBeMultiplexList(a)

% Computes the contributions to the detection metric (roughly speaking, received power and noise power) for the
% current hop.
function [hopData, epre, epreSamples, noiseVar, noiseSamples] = processHop(rblock, info, carrier, pucch, rxGrid, multiplexList)
    nSymbols = 14; % OFDM symbols per slot.
    nRE = 12;      % RE (subcarriers) per PRB.
    nShifts = 12;  % Total numnber of initioal cyclic shifts.

    % Create a boolean mask of the OFDM symbols carrying DM-RS in the entire slot.
    dmrsMask = false(nSymbols, 1);
    dmrsMask(pucch.SymbolAllocation(1) + (1:2:pucch.SymbolAllocation(2))) = true;

    % Create a boolean mask of the OFDM symbols allocated in the current hop.
    if strcmp(pucch.FrequencyHopping, 'neither')
        firstSymbol = pucch.SymbolAllocation(1) + 1;
        lastSymbol = firstSymbol + pucch.SymbolAllocation(2) - 1;
        iHop = 1;
        nSymbolsHop = pucch.SymbolAllocation(2);
        nSymbolsWdata = floor(nSymbolsHop / 2);
        nSymbolsWdmrs = ceil(nSymbolsHop / 2);
    else
        if (rblock == pucch.PRBSet)
            firstSymbol = pucch.SymbolAllocation(1) + 1;
            lastSymbol = firstSymbol + floor(pucch.SymbolAllocation(2) / 2) - 1;
            iHop = 1;

            nSymbolsHop = floor(pucch.SymbolAllocation(2) / 2);
            nSymbolsWdata = floor(pucch.SymbolAllocation(2) / 4);
            nSymbolsWdmrs = floor((pucch.SymbolAllocation(2) + 2) / 4);
        else
            firstSymbol = pucch.SymbolAllocation(1) + floor(pucch.SymbolAllocation(2) / 2) + 1;
            lastSymbol = pucch.SymbolAllocation(1) + pucch.SymbolAllocation(2);
            iHop = 2;

            nSymbolsHop = ceil(pucch.SymbolAllocation(2) / 2);
            nSymbolsWdata = floor((pucch.SymbolAllocation(2) + 2) / 4);
            nSymbolsWdmrs = nSymbolsHop - nSymbolsWdata;
        end
    end
    symbolMask = false(nSymbols, 1);
    symbolMask(firstSymbol:lastSymbol) = true;

    % Boolean masks for symbols with data and for symbols with DM-RS in the current hop.
    dataMask = symbolMask & ~dmrsMask;
    dmrsMask = symbolMask & dmrsMask;

    assert(sum(dataMask) == nSymbolsWdata, 'The number of symbols carrying data does not match the mask.');
    assert(sum(dmrsMask) == nSymbolsWdmrs, 'The number of symbols carrying DM-RS does not match the mask.');
    assert(nSymbolsWdmrs + nSymbolsWdata == nSymbolsHop, ...
        'The number of symbols carrying data and DM-RS does not add up to the hop symbols.');

    % Retrieve indices of the allocated subcarriers for the current hop.
    if isempty(pucch.NStartBWP)
        startBWP = carrier.NStartGrid;
    else
        startBWP = pucch.NStartBWP;
    end
    subcarriers = (1:nRE) + (startBWP + rblock) * nRE;

    % Retrieve data and DM-RS samples for the current hop.
    data = rxGrid(subcarriers, dataMask, :);
    dmrs = rxGrid(subcarriers, dmrsMask, :);

    epre = sum(abs(data).^2, 'all');
    epre = epre + sum(abs(dmrs).^2, 'all');
    epreSamples = numel(data) + numel(dmrs);

    u = info.U(iHop);
    v = info.V(iHop);

    % Match the received samples to the base pseudorandom sequence.
    dataLowpapr = nrLowPAPRS(u, v, info.Alpha(dataMask), nRE);
    dmrsLowpapr = nrLowPAPRS(u, v, info.Alpha(dmrsMask), nRE);

    dataLSE = data .* conj(dataLowpapr);
    dmrsLSE = dmrs .* conj(dmrsLowpapr);

    % Taking the FFT is the same as matching the ICS-depending part of the pseudorandom sequence.
    dataFFT = fft(dataLSE);
    dmrsFFT = fft(dmrsLSE);

    maxOCCI = nSymbolsWdata - 1;
    hopData = dictionary;
    nPorts = size(rxGrid, 3);

    dmrsReconstructed = complex(zeros(size(dmrsLSE)));
    for occi = 0:maxOCCI
        % Retrieve the ICSs that are used in combination with the current OCCI.
        occupiedShifts = [multiplexList([multiplexList.OCCI] == occi).InitialCyclicShift]';

        if isempty(occupiedShifts)
            continue;
        end

        % Retrieve the time-domain orthogonal cover codes used for data and for DM-RS.
        dataW = getW(occi, nSymbolsWdata);
        dmrsW = getW(occi, nSymbolsWdmrs);

        % Combine the copies from all OFDM symbols.
        dataSingle = squeeze(pagemtimes(dataFFT, dataW)) / sqrt(nSymbolsWdata);
        dmrsSingle = squeeze(pagemtimes(dmrsFFT, dmrsW)) / sqrt(nSymbolsWdmrs);

        estimatedChannel = dmrsSingle / (sqrt(nSymbolsWdmrs) * nShifts);

        % Discard ICSs if their combined contribution from all ports is 10+ dB
        % below the max one.
        combinedPower = sum(abs(estimatedChannel).^2, 2);
        chMask = (combinedPower > max(combinedPower) / 10);

        % Reconstruct the noiseless received signal.
        reconstructedTmp = reshape(ifft(estimatedChannel .* chMask) * nShifts, nShifts, 1, nPorts);
        dmrsReconstructed = dmrsReconstructed + pagemtimes(reconstructedTmp, dmrsW');

        for thisShift = occupiedShifts(:)'
            iShift = thisShift + 1;
            % The main contribution to the numerator of the detection metric is the average received power, including both data and DM-RS.
            numeratorContrMain = sum(abs([dataSingle(iShift, :) dmrsSingle(iShift, :)]).^2) / nShifts / (nSymbolsWdmrs + nSymbolsWdata);
            % The cross contribution is given by accumulating all the inner-products between data and DM-RS signals.
            numeratorContrCross = sum(dmrsSingle(iShift, :) .* conj(dataSingle(iShift, :))) / nShifts / (nSymbolsWdmrs + nSymbolsWdata);

            resKey = "ICS" + thisShift + "OCCI" + occi;
            hopData(resKey) = struct( ...
                'ICS', thisShift, ...
                'OCCI', occi, ...
                'NumeratorContrMain', numeratorContrMain, ...
                'NumeratorContrCross', numeratorContrCross, ...
                'EstimatedChannel', estimatedChannel(iShift, :) ...
                );
        end
    end % of for occi = 0:maxOCCI

    % Now estimate the noise comparing received and reconstructed signals.
    noiseVar = sum(abs(dmrsLSE - dmrsReconstructed).^2, 'all');
    noiseSamples = numel(dmrsLSE);
end % of function processHop(carrier, pucch, ouci, rxGrid, multiplexList)

% Returns the time-domain orthogonal cover code for the given OCCI and number of OFDM symbols.
function w = getW(occi, n)
    if (n ~= 4)
        phy = mod((0:n-1)' * occi, n);
    else
        % The case "n == 4" must be dealt with differently.
        matrixPhy = [0 0 0 0; 0 2 0 2; 0 0 2 2; 0 2 2 0]';
        phy = matrixPhy(:, occi+1);
    end
    w = exp(-2j * pi * phy / n);
end % of function w = getW(occi, n)

% Returns the most likely transmitted symbol, that is the symbol that maximizes the real part of
% the cross term of the detection metric (output metricNumeratorCross).
% Note that the detection of the symbol has to be confirmed by computing the global metric and
% checking it is above the detection threshold.
function [metricNumeratorCross, rxSymbol, uciBits] = detectsymbol(metricNumeratorCrossTmp, nBits)
    if nBits == 1
        rxSymbol = (1 + 1j) / sqrt(2);
        metricNumeratorCross = real(metricNumeratorCrossTmp * rxSymbol);
        if metricNumeratorCross > 0
            uciBits = 0;
        else
            uciBits = 1;
            rxSymbol = -rxSymbol;
            metricNumeratorCross = -metricNumeratorCross;
        end
        return
    end

    % If 2 bits.
    d1 = (1 + 1j) / sqrt(2);
    c1 = real(metricNumeratorCrossTmp * d1);
    bits1 = [0; 0];
    d2 = (1 - 1j) / sqrt(2);
    c2 = real(metricNumeratorCrossTmp * d2);
    bits2 = [0; 1];

    % First check whether the most likely symbol is in quadrants 1-3 (repeated bits) or
    % in quadrants 2-4 (different bits), by looking at the magnitude of the resulting
    % cross product.
    if abs(c1) > abs(c2)
        metricNumeratorCross = c1;
        rxSymbol = d1;
        uciBits = bits1;
    else
        metricNumeratorCross = c2;
        rxSymbol = d2;
        uciBits = bits2;
    end

    % Now pick the sign.
    if metricNumeratorCross < 0
        metricNumeratorCross = -metricNumeratorCross;
        rxSymbol = -rxSymbol;
        uciBits = 1 - uciBits;
    end
end % of function [metricNumeratorCross, rxSymbol, uciBits] = detectsymbol(metricNumeratorCrossTmp, nBits);
