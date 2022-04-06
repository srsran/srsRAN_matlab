%srsGetTargetCodeRate Returns the target code rate for a given configuration.
%   [TARGETCODERATE, QM] = srsGetTargetCodeRate(MCSTABLE, MCS) returns the target code
%   rate TARGETCODERATE and modulation order QM given a specific modulation and coding
%   scheme index MCS (0-28) and associated table MCSTABLE ('qam64', 'qam256', 'qam64LowSE'),
%   as defined in TS 38.214 Section 5.1.3.1.

function [targetCodeRate, Qm] = srsGetTargetCodeRate(mcsTable, mcs)

    targetCodeRate = 0;
    Qm = 0;

    switch mcsTable
        case 'qam64'
            % TS 38.214, Table 5.1.3.1-1: MCS index table 1 for PDSCH
            switch mcs
                case 0
                    targetCodeRate = 120;
                    Qm = 2;
                case 1
                    targetCodeRate = 157;
                    Qm = 2;
                case 2
                    targetCodeRate = 193;
                    Qm = 2;
                case 3
                    targetCodeRate = 251;
                    Qm = 2;
                case 4
                    targetCodeRate = 306;
                    Qm = 2;
                case 5
                    targetCodeRate = 379;
                    Qm = 2;
                case 6
                    targetCodeRate = 449;
                    Qm = 2;
                case 7
                    targetCodeRate = 526;
                    Qm = 2;
                case 8
                    targetCodeRate = 602;
                    Qm = 2;
                case 9
                    targetCodeRate = 679;
                    Qm = 2;
                case 10
                    targetCodeRate = 340;
                    Qm = 4;
                case 11
                    targetCodeRate = 378;
                    Qm = 4;
                case 12
                    targetCodeRate = 434;
                    Qm = 4;
                case 13
                    targetCodeRate = 490;
                    Qm = 4;
                case 14
                    targetCodeRate = 553;
                    Qm = 4;
                case 15
                    targetCodeRate = 616;
                    Qm = 4;
                case 16
                    targetCodeRate = 658;
                    Qm = 4;
                case 17
                    targetCodeRate = 438;
                    Qm = 6;
                case 18
                    targetCodeRate = 466;
                    Qm = 6;
                case 19
                    targetCodeRate = 517;
                    Qm = 6;
                case 20
                    targetCodeRate = 567;
                    Qm = 6;
                case 21
                    targetCodeRate = 616;
                    Qm = 6;
                case 22
                    targetCodeRate = 666;
                    Qm = 6;
                case 23
                    targetCodeRate = 719;
                    Qm = 6;
                case 24
                    targetCodeRate = 772;
                    Qm = 6;
                case 25
                    targetCodeRate = 822;
                    Qm = 6;
                case 26
                    targetCodeRate = 873;
                    Qm = 6;
                case 27
                    targetCodeRate = 910;
                    Qm = 6;
                case 28
                    targetCodeRate = 948;
                    Qm = 6;
            end
        case 'qam256'
            % TS 38.214, Table 5.1.3.1-2: MCS index table 2 for PDSCH
            switch mcs
                case 0
                    targetCodeRate = 120;
                    Qm = 2;
                case 1
                    targetCodeRate = 193;
                    Qm = 2;
                case 2
                    targetCodeRate = 308;
                    Qm = 2;
                case 3
                    targetCodeRate = 449;
                    Qm = 2;
                case 4
                    targetCodeRate = 602;
                    Qm = 2;
                case 5
                    targetCodeRate = 378;
                    Qm = 4;
                case 6
                    targetCodeRate = 434;
                    Qm = 4;
                case 7
                    targetCodeRate = 490;
                    Qm = 4;
                case 8
                    targetCodeRate = 553;
                    Qm = 4;
                case 9
                    targetCodeRate = 616;
                    Qm = 4;
                case 10
                    targetCodeRate = 658;
                    Qm = 4;
                case 11
                    targetCodeRate = 466;
                    Qm = 6;
                case 12
                    targetCodeRate = 517;
                    Qm = 6;
                case 13
                    targetCodeRate = 567;
                    Qm = 6;
                case 14
                    targetCodeRate = 616;
                    Qm = 6;
                case 15
                    targetCodeRate = 666;
                    Qm = 6;
                case 16
                    targetCodeRate = 719;
                    Qm = 6;
                case 17
                    targetCodeRate = 772;
                    Qm = 6;
                case 18
                    targetCodeRate = 822;
                    Qm = 6;
                case 19
                    targetCodeRate = 873;
                    Qm = 6;
                case 20
                    targetCodeRate = 682.5;
                    Qm = 8;
                case 21
                    targetCodeRate = 711;
                    Qm = 8;
                case 22
                    targetCodeRate = 754;
                    Qm = 8;
                case 23
                    targetCodeRate = 797;
                    Qm = 8;
                case 24
                    targetCodeRate = 841;
                    Qm = 8;
                case 25
                    targetCodeRate = 885;
                    Qm = 8;
                case 26
                    targetCodeRate = 916.5;
                    Qm = 8;
                case 27
                    targetCodeRate = 948;
                    Qm = 8;
            end
        case 'qam64LowSE'
            % TS 38.214, Table 5.1.3.1-3: MCS index table 3 for PDSCH
            switch mcs
                case 0
                    targetCodeRate = 30;
                    Qm = 2;
                case 1
                    targetCodeRate = 40;
                    Qm = 2;
                case 2
                    targetCodeRate = 50;
                    Qm = 2;
                case 3
                    targetCodeRate = 64;
                    Qm = 2;
                case 4
                    targetCodeRate = 78;
                    Qm = 2;
                case 5
                    targetCodeRate = 99;
                    Qm = 2;
                case 6
                    targetCodeRate = 120;
                    Qm = 2;
                case 7
                    targetCodeRate = 157;
                    Qm = 2;
                case 8
                    targetCodeRate = 193;
                    Qm = 2;
                case 9
                    targetCodeRate = 251;
                    Qm = 2;
                case 10
                    targetCodeRate = 308;
                    Qm = 2;
                case 11
                    targetCodeRate = 379;
                    Qm = 2;
                case 12
                    targetCodeRate = 449;
                    Qm = 2;
                case 13
                    targetCodeRate = 526;
                    Qm = 2;
                case 14
                    targetCodeRate = 602;
                    Qm = 2;
                case 15
                    targetCodeRate = 340;
                    Qm = 4;
                case 16
                    targetCodeRate = 378;
                    Qm = 4;
                case 17
                    targetCodeRate = 434;
                    Qm = 4;
                case 18
                    targetCodeRate = 490;
                    Qm = 4;
                case 19
                    targetCodeRate = 553;
                    Qm = 4;
                case 20
                    targetCodeRate = 616;
                    Qm = 4;
                case 21
                    targetCodeRate = 438;
                    Qm = 6;
                case 22
                    targetCodeRate = 466;
                    Qm = 6;
                case 23
                    targetCodeRate = 517;
                    Qm = 6;
                case 24
                    targetCodeRate = 567;
                    Qm = 6;
                case 25
                    targetCodeRate = 616;
                    Qm = 6;
                case 26
                    targetCodeRate = 666;
                    Qm = 6;
                case 27
                    targetCodeRate = 719;
                    Qm = 6;
                case 28
                    targetCodeRate = 772;
                    Qm = 6;
            end
    end

end
