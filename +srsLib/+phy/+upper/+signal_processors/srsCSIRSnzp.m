%srsCSIRSnzp Non-Zero-Power Channel-State Information Reference Signals.
%   [CSIRSSYMBOLS, SYMBOLINDICES] = srsCSIRSnzp(CARRIER, CSIRS, AMPLITUDE)
%   generates the NZP-CSI-RS sequence and stores it in CSIRSSYMBOLS. The
%   mapping indices are generated and stored in SYMBOLINDICES.
% 
%   See also nrCarrierConfig, nrCSIRSConfig, nrCSIRS and nrCSIRSIndices.

function [CSIRSsymbols, symbolIndices] = srsCSIRSnzp(carrier, csirs, amplitude)

    CSIRSsymbols = nrCSIRS(carrier, csirs);
    CSIRSsymbols = CSIRSsymbols * amplitude;
    symbolIndices = nrCSIRSIndices(carrier, csirs, 'IndexStyle', 'subscript', 'IndexBase', '0based');

