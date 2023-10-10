%srsParseLogs Parses a PHY uplink channel log entry.
%   [CARRIER, PHYCH, EXTRA] = srsParseLogs asks the user to select a section of
%   the srsGNB logs corresponding to PHY uplink channel, parses the information
%   and returns the following objects:
%   CARRIER - an nrCarrierConfig object with the carrier configuration
%   PHYCH   - a PHY uplink channel configuration object (specifically, an
%             nrPUSCHConfig, an nrPUCCH1Config or an nrPUCCH2Config object)
%   EXTRA   - a struct with PUSCH additional information, namely redundancy
%             version, transport block size and target code rate (for PUCCH, the
%             struct is empty).
%
%   As an example of a log entry expected by the srsParseLogs function, the
%   following excerpt from a srsGNB log file refers to a PUSCH transmission
%   (similar ones can be found for PUCCH transmissions, too).
%   Important: The srsGNB log level must be set to "debug" to obtain detailed
%   information as shown below.
%
%   2023-06-07T20:54:24.497343 [UL-PHY1 ] [D] [   584.9] PUSCH: rnti=0x4601 h_id=0 prb=[4, 10) symb=[0, 14) mod=64QAM rv=0 tbs=544 crc=OK iter=2.0 snr=31.8dB t=135.0us
%     rnti=0x4601
%     h_id=0
%     bwp=[0, 273)
%     prb=[4, 10)
%     symb=[0, 14)
%     oack=0
%     ocsi1=0
%     ocsi2=0
%     alpha=0.0
%     betas=[0.0, 0.0, 0.0]
%     mod=64QAM
%     tcr=0.92578125
%     rv=0
%     bg=1
%     new_data=true
%     n_id=1
%     dmrs_mask=00100001000100
%     n_scr_id=1
%     n_scid=false
%     n_cdm_g_wd=2
%     dmrs_type=1
%     lbrm=3168bytes
%     slot=584.9
%     cp=normal
%     nof_layers=1
%     ports=0
%     crc=OK
%     iter=2.0
%     max_iter=2
%     min_iter=2
%     nof_cb=1
%     snr=31.8dB
%     epre=+22.2dB
%     rsrp=+22.2dB
%     t_align=0.1us

%   Copyright 2021-2023 Software Radio Systems Limited
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

function [carrier, phych, extra] = srsParseLogs

    fprintf(['\nCopy the relevant section of the logs to the system clipboard ', ...
        '(typically select and Ctrl+C), then switch back to MATLAB and press any key.\n']);

    pause;

    logs = clipboard('paste');

    fprintf('Parsing the following log section:\n\n%s\n\n', logs);

    isOK = input('Do you want to continue? [Y]/N ', 's');
    if isempty(isOK)
        isOK = 'Y';
    end
    if ~ismember(isOK, {'y', 'Y'})
        fprintf('Parsing aborted.\n');
        return;
    end

    allLines = splitlines(logs);
    nLines = length(allLines);

    carrier = srsLib.phy.helpers.srsConfigureCarrier();

    % The subcarrier spacing must be provided manually.
    scs = input('Subcarrier spacing in kHz: ');
    if ismember(scs, [15, 30, 60])
        carrier.SubcarrierSpacing = scs;
    else
        error('Invalid subcarrier spacing %d kHz', scs);
    end

    % The grid size must be provided manually.
    gridSize = input('Grid size as a number of RBs: ');
    carrier.NSizeGrid = gridSize;
    carrier.NStartGrid = 0;

    % Check whether this is a PUSCH or PUCCH log entry.
    chPattern = ("PUSCH"|"PUCCH");
    chType = extract(allLines{1}, chPattern);

    isPUSH = true;
    if strcmp(chType{1}, 'PUSCH')
        phych = srsLib.phy.helpers.srsConfigurePUSCH();
    elseif strcmp(chType{1}, 'PUCCH')
        isPUSH = false;
        % If a PUCCH entry, we need the PUCCH format.
        fPattern = "format=" + digitsPattern;
        fType = extract(allLines{1}, fPattern);
        format = str2double(fType{1}(end));
        if ismember(format, [1, 2])
            phych = srsLib.phy.helpers.srsConfigurePUCCH(format);
        else
            error('PUCCH Format %d is not supported.', format);
        end
    else
        error('Invalid channel type: can only parse PUSCH and PUCCH logs.');
    end

    % Now parse all lines and get the values we need.
    for iLine = 2:nLines
        parameter = split(strtrim(allLines{iLine}), '=');
        switch parameter{1}
            case 'rnti'
                rnti = sscanf(parameter{2}, '%x');
                if (isPUSH || (format == 2))
                    phych.RNTI = rnti;
                end
            case 'bwp'
                bwp = sscanf(parameter{2}, '[%d, %d)');
                phych.NSizeBWP = bwp(2) - bwp(1);
                phych.NStartBWP = bwp(1);
            case 'cp'
                cp = parameter{2};
                carrier.CyclicPrefix = cp;
            case 'mod'
                modulation = parameter{2};
                phych.Modulation = modulation;
            case 'tcr'
                tcr = sscanf(parameter{2}, '%f');
            case 'rv'
                rv = sscanf(parameter{2}, '%d');
            case 'n_id'
                nid = sscanf(parameter{2}, '%d');
                if (~isPUSH && (format == 1))
                    phych.HoppingID = nid;
                else
                    phych.NID = nid;
                end
            case 'n_id0'
                nid0 = sscanf(parameter{2}, '%d');
                phych.NID0 = nid0;
            case 'nof_layers'
                nLayers = sscanf(parameter{2}, '%d');
                phych.NumLayers = nLayers;
            case 'dmrs_mask'
                dmrspos = strfind(parameter{2}, '1');
                phych.DMRS.CustomSymbolSet = dmrspos - 1;
            case 'dmrs_type'
                dmrsType = sscanf(parameter{2}, '%d');
                phych.DMRS.DMRSConfigurationType = dmrsType;
            case 'n_scr_id'
                scramblingID = sscanf(parameter{2}, '%d');
                phych.DMRS.NIDNSCID = scramblingID;
            case 'n_scid'
                nscid = parameter{2};
                if strcmp(nscid, 'false')
                    phych.DMRS.NSCID = 0;
                else
                    phych.DMRS.NSCID = 1;
                end
            case 'n_cdm_g_wd'
                nCDMgroups = sscanf(parameter{2}, '%d');
                phych.DMRS.NumCDMGroupsWithoutData = nCDMgroups;
            case 'prb'
                prb = sscanf(parameter{2}, '[%d, %d)');
                phych.PRBSet = prb(1):(prb(2)-1);
            case 'dc_position'
                dcPosition = sscanf(parameter{2}, '%d');
            case 'prb1'
                % This applies to PUCCH Format 1 only.
                prb = sscanf(parameter{2}, '%d');
                phych.PRBSet = prb;
            case 'prb2'
                if ~strcmp(parameter{2}, 'na')
                    prb2 = sscanf(parameter{2}, '%d');
                    phych.SecondHopStartPRB = prb2;
                    phych.FrequencyHopping = 'intraSlot';
                end
            case 'symb'
                symb = sscanf(parameter{2}, '[%d, %d)');
                phych.SymbolAllocation = [symb(1), symb(2) - symb(1)];
            case 'slot'
                slot = sscanf(parameter{2}, '%d.%d');
                carrier.NFrame = slot(1);
                carrier.NSlot = slot(2);
            case 'cs'
                cs = sscanf(parameter{2}, '%d');
                phych.InitialCyclicShift = cs;
            case 'occ'
                occ = sscanf(parameter{2}, '%d');
                phych.OCCI = occ;
            otherwise
        end
    end

    if isPUSH
        % If a PUSCH entry, read the TBS (recall that srsGNB logs it in bytes,
        % MATLAB uses bits) and populate the extra struct.
        tStart = strfind(allLines{1}, 'tbs');
        tbs = sscanf(allLines{1}(tStart:end), 'tbs=%d');

        extra = struct('RV', rv, 'TargetCodeRate', tcr, 'TransportBlockLength', tbs * 8, ...
            'dcPosition', dcPosition);
    else
        extra = struct([]);
    end
end
