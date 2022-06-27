%srsPRACHgenerator Generate a 5G NR PRACH waveform.
%   [WAVEFORM,GRIDSET,INFO] = srsPRACHgenerator(CARRIER, PRACH)
%   generates a 5G NR physical random access channel (PRACH) waveform
%   WAVEFORM given input CARRIER and PRACH parameters. The function also
%   returns two structure arrays, GRIDSET and INFO.
%   GRIDSET is a structure array containing the following fields for each
%   carrier in WAVECONFIG.Carriers:
%   ResourceGrid            - PRACH resource grid
%   Info                    - Structure with information corresponding to
%                             the PRACH OFDM modulation. If the PRACH is
%                             configured for FR2 or the PRACH slot for the
%                             current configuration spans more than one
%                             subframe, some of the OFDM-related
%                             information may be different between PRACH
%                             slots. In this case, the info structure is an
%                             array of the same length as the number of
%                             PRACH slots in the waveform.
%   INFO is a structure containing the following field:
%   WaveformResources - Structure containing the following field:
%       PRACH - Structure containing the following field:
%           Resources - Structure array containing the following fields:
%               NPRACHSlot       - PRACH slot numbers of each allocated
%                                  PRACH preamble
%               PRACHSymbols     - PRACH symbols corresponding to each
%                                  allocated PRACH slot
%               PRACHSymbolsInfo - Additional information associated with
%                                  PRACH symbols
%               PRACHIndices     - PRACH indices corresponding to each
%                                  allocated PRACH slot
%               PRACHIndicesInfo - Additional information associated with
%                                  PRACH indices
%
%   CARRIER is a Carrier-specific configuration object, as described in
%              <a href="matlab:help('nrCarrierConfig')">nrCarrierConfig</a> with these properties:
%   SubcarrierSpacing   - Subcarrier spacing in kHz
%   CyclicPrefix        - Cyclic prefix
%   NSizeGrid           - Number of resource blocks
%
%   PRACH is a PRACH-specific configuration object, as described in
%              <a href="matlab:help('nrPRACHConfig')">nrPRACHConfig</a> with these properties:
%   FrequencyRange      - Frequency range (used in combination with
%                         DuplexMode to select a configuration table
%                         from TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4)
%   DuplexMode          - Duplex mode (used in combination with
%                         FrequencyRange to select a configuration table
%                         from TS 38.211 Table 6.3.3.2-2 to 6.3.3.2-4)
%   ConfigurationIndex  - Configuration index, as defined in TS 38.211
%                         Tables 6.3.3.2-2 to 6.3.3.2-4
%   SubcarrierSpacing   - PRACH subcarrier spacing in kHz
%   SequenceIndex       - Logical root sequence index
%   PreambleIndex       - Scalar preamble index within cell
%   RestrictedSet       - Type of restricted set
%   ZeroCorrelationZone - Cyclic shift configuration index
%   RBOffset            - Starting resource block (RB) index of the
%                         initial uplink bandwidth part (BWP) relative
%                         to carrier resource grid
%   FrequencyStart      - Frequency offset of lowest PRACH transmission
%                         occasion in frequency domain with respect to
%                         PRB 0 of the initial uplink BWP
%   FrequencyIndex      - Index of the PRACH transmission occasions in
%                         frequency domain
%   TimeIndex           - Index of the PRACH transmission occasions in
%                         time domain
%   ActivePRACHSlot     - Active PRACH slot number within a subframe or
%                         a 60 kHz slot
%   NPRACHSlot          - PRACH slot number
%
%   Example:
%   % Generate a 10ms PRACH waveform for the default values for
%   % nrPRACHConfig and nrCarrierConfig. Display the PRACH-related OFDM
%   % information.
%
%   carrier = nrCarrierConfig;
%   prach = nrPRACHConfig;
%   [waveform,gridset] = srsPRACHgenerator(carrier, prach);
%   disp(gridset.Info)
%
%
%   See also nrPRACHOFDMModulate, nrPRACHOFDMInfo, nrPRACHConfig,
%   nrPRACHGrid, nrPRACH, nrPRACHIndices, nrCarrierConfig.

function [waveform,gridset,winfo] = srsPRACHgenerator(carrier, prach)
% Initialize outputs and internal resources
gridset = [];
datastore = [];
resourceGrid = [];

% Generate an empty PRACH resource grid
prachGrid = nrPRACHGrid(carrier, prach);

% Create the PRACH symbols
prachSymbols = [];
while(isempty(prachSymbols))
    [prachSymbols, prachInfoSym] = nrPRACH(carrier, prach);
    prach.NPRACHSlot = prach.NPRACHSlot + 1;
end
prach.NPRACHSlot = prach.NPRACHSlot - 1;

% Create the PRACH indices and retrieve PRACH information
[prachIndices, prachInfoInd] = nrPRACHIndices(carrier, prach);

% Map the PRACH symbols into the grid
prachGrid(prachIndices) = prachSymbols;

% Capture resource info for this PRACH instance
resource.NPRACHSlot = prach.NPRACHSlot;
resource.PRACHSymbols = prachSymbols;
resource.PRACHSymbolsInfo = prachInfoSym;
resource.PRACHIndices = prachIndices;
resource.PRACHIndicesInfo = prachInfoInd;
datastore.Resource = resource;


% Generate the PRACH waveform for this slot and append it to the
% existing waveform
[waveform, prachOFDMInfo] = nrPRACHOFDMModulate(carrier, prach, prachGrid, 'Windowing', []);

% Capture the OFDM modulation info
gridset.Info = prachOFDMInfo;

% Update the resource grid
resourceGrid = [resourceGrid prachGrid]; %#ok<AGROW>

% Capture all resources info for this PRACH configuration
waveinfo.PRACH = datastore;

% Capture the resource grid
gridset.ResourceGrid = resourceGrid;

winfo.WaveformResources = waveinfo;
end