% indices2REPattern Generates a Resource Element pattern.
% REPATTERN = indices2REPattern(INDICES) generates a Resource Element (RE)
% Pattern REPATTERN from a set of RE indices INDICES.
%
% INDICES is a three-dimensional array comprising a list of zero-based
% Resource Element (RE) locations, where the first column is the subcarrier
% index, the second column is the OFDM symbol index, and the third one is 
% the antenna port index.
%
% REPATTERN is a cell array that describes a RE pattern, with the following
% elements:
%
% RBStart    - First Resource Block (RB) in the pattern.
% RBEnd      - Last RB in the pattern.
% RBStride   - Distance between RB in the pattern.
% REMask     - 12-element logical column vector where each element
%              represents a RE within a RB. 
% symbolMask - 14-element logical column vector where each element
%              represents an OFDM symbol within a 5G NR slot.
%
% See also srsIndexes0BasedSubscrit.

function REPattern = indices2REPattern(indices)

% Number of RE in a Resource Block.
NRE = 12;

% RE mask.
REMask = false(NRE, 1);

% RB mask.
RBMask = false(275, 1);

% Subcarrier indices of all RE.
SubcIndices = indices(:, 1);

% Determine RE index within the RB.
ReIndexPRB = mod(SubcIndices, NRE);

% Determine the RB where the RE is located.
PRBIndex = (SubcIndices - ReIndexPRB) / NRE;

% Set RB and RE masks.
REMask(ReIndexPRB + 1) = true;
RBMask(PRBIndex + 1) = true;

% Symbol mask.
symbolMask = false(14, 1);

% Symbol Indices of all RE.
symbolIndex = indices(:, 2);

% Set symbol mask.
symbolMask(symbolIndex + 1) = true;

% Create RB index set.
RBIndices = 0 : 274;
RBIndices = RBIndices(RBMask);

% RB Start and end.
RBStart = min(RBIndices);
RBEnd = max(RBIndices) + 1;

RBStride = 1;

% If there is more than 1 RB, compute the RB stride.
if (length(RBIndices) > 1)
    % Compute distance between RBs.
    RBJumps = circshift(RBIndices, -1) - RBIndices;
    
    % Discard last jump, since it wraps around due to the cyclic shift.
    RBJumps = RBJumps(1:length(RBJumps) - 1);
    
    % Check that the RB are uniformly spaced.
    if (~all(RBJumps == RBJumps(1)))
        error('Distance between RBs is not uniform. Cannot determine RB stride.');
    end

    RBStride = RBJumps(1);
end

REPattern = {RBStart, RBEnd, RBStride, REMask, symbolMask};
