%srsExpandMCS Returns the target code rate for a given configuration.
%   [TARGETCODERATE, QM] = srsExpandMCS(MCSTABLE, MCS) returns the target code
%   rate TARGETCODERATE and modulation order QM (according to the 3GPP convention:
%   i.e., the number of bits per symbol) given a specific modulation and coding
%   scheme index MCS (0-28) and associated table MCSTABLE ('qam64', 'qam256',
%   'qam64LowSE'), as defined in TS 38.214 Section 5.1.3.1.

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

function [targetCodeRate, Qm] = srsExpandMCS(mcs, mcsTable)

    % TS 38.214, Table 5.1.3.1-1: MCS index table 1 for PDSCH
    codeRateTables.qam64 = {{120, 2}, {157, 2}, {193, 2}, {251, 2}, ...
        {306, 2}, {379, 2}, {449, 2}, {526, 2}, {602, 2}, {679, 2}, ...
        {340, 4}, {378, 4}, {434, 4}, {490, 4}, {553, 4}, {616, 4}, ...
        {658, 4}, {438, 6}, {466, 6}, {517, 6}, {567, 6}, {616, 6}, ...
        {666, 6}, {719, 6}, {772, 6}, {822, 6}, {873, 6}, {910, 6}, ...
        {948, 6}};
    % TS 38.214, Table 5.1.3.1-2: MCS index table 2 for PDSCH
    codeRateTables.qam256 = {{120, 2}, {193, 2}, {308, 2}, {449, 2}, ...
        {602, 2}, {378, 4}, {434, 4}, {490, 4}, {553, 4}, {616, 4}, ...
        {658, 4}, {466, 6}, {517, 6}, {567, 6}, {616, 6}, {666, 6}, ...
        {719, 6}, {772, 6}, {822, 6}, {873, 6}, {682.5, 8}, {711, 8}, ...
        {754, 8}, {797, 8}, {841, 8}, {885, 8}, {916.5, 8}, {948, 8}};
    % TS 38.214, Table 5.1.3.1-3: MCS index table 3 for PDSCH
    codeRateTables.qam64LowSE = {{30, 2}, {40, 2}, {50, 2}, {64, 2}, ...
        {78, 2}, {99, 2}, {120, 2}, {157, 2}, {193, 2}, {251, 2}, ...
        {308, 2}, {379, 2}, {449, 2}, {526, 2}, {602, 2}, {340, 4}, ...
        {378, 4}, {434, 4}, {490, 4}, {553, 4}, {616, 4}, {438, 6}, ...
        {466, 6}, {517, 6}, {567, 6}, {616, 6}, {666, 6}, {719, 6}, ...
        {772, 6}};

    % get the return values from the code rate tables
    tableEntry = getfield(codeRateTables, mcsTable, {mcs + 1});
    targetCodeRate = tableEntry{1}{1};
    Qm = tableEntry{1}{2};

end
