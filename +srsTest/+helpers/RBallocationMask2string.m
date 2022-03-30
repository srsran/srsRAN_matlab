%RBALLOCATIONMASK2STRING Generates a new RB allocation bitmask string.
%   OUTPUTSTRING = RBALLOCATIONMASK2STRING(VARARGIN)
%   generates an RB bitmask allocation string OUTPUTSTRING from either a vector
%   of indices SYMBOLINDICESVECTOR or from a start index PRBSTART and an end
%   index PRBEND.

function outputString = RBallocationMask2string(varargin)

    rbAllocation = zeros(52, 1); % maximum possible RB size
    switch length(varargin)
        case 1
            symbolIndicesVector = varargin{1};
            for index = 1:length(symbolIndicesVector)
                REidx = symbolIndicesVector(index, 1);
                rbIdx = fix(double(REidx) / 12);
                rbAllocation(rbIdx + 1) = 1;
            end
        case 2
            PRBstart = varargin{1};
            PRBend = varargin{2};
            for rbIdx = PRBstart:PRBend
                rbAllocation(rbIdx + 1) = 1;
            end
    end
    import srsTest.helpers.cellarray2str
    outputString = cellarray2str({rbAllocation}, false);

end
