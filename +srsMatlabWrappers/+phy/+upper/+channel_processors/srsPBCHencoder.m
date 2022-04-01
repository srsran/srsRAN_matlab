%SRSPBCHENCODER Physical broadcast channel encoding.
%   CW = SRSPBCHENCODER(PAYLOAD, NCELLID, SSBINDEX, LMAX, SFN, HRF, KSSB)
%   encodes the 24-bit BCH payload PAYLOAD and returns the codeword CW.
%
%   See also nrBCH.

function cw = srsPBCHencoder(payload, NCellID, SSBindex, Lmax, SFN, hrf, kSSB)

    % subcarrier offset described in TS 38.211 7.4.3.1
    if Lmax == 64
        idxOffset = SSBindex;
    else
        idxOffset = kSSB;
    end
    cw = nrBCH(payload, SFN, hrf, Lmax, idxOffset, NCellID);

end
