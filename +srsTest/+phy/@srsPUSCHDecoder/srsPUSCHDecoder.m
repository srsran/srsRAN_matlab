%srsPUSCHDecoder MATLAB interface to SRGNB PUSCH decoder.
%   User-friendly interface to the SRSGNB PUSCH decoder class, which is wrapped
%   by the MEX static method pusch_decoder_mex.
%
%   PUSCHDEC = srsPUSCHDecoder(SBPDESC) creates a PHY Uplink Shared Channel decoder
%   object with a softbuffer pool defined by structure SBPDESC (whose fields are
%   dumped into property <a href="matlab:help srsTest.phy.srsPUSCHDecoder/softbufferPoolDescription">softbufferPoolDescription</a>).
%
%   srsPUSCHDecoder Properties (Nontunable):
%
%   maxCodeblockSize - Maximum size of the codeblocks stored in the pool.
%   maxSoftbuffers   - Maximum number of softbuffers managed by the pool.
%   maxCodeblocks    - Maximum number of codeblocks managed by the pool
%                      (shared by all softbuffers).
%
%   srsPUSCHDecoder Properties (Access = private):
%
%   softbufferPoolID          - Identifier of the softbuffer pool.
%
%   srsPUSCHDecoder Methods:
%
%   step      - Decodes one PUSCH codeword.
%   resetCRCS - Resets the CRC state of a softbuffer.
%   release   - Allows reconfiguration.
%   isLocked  - Locked status (logical).
%
%   Step method syntax
%
%   TBK = step(PUSCHDEC, LLRS, NEWDATA, SEGCONFIG, HARQBUFID) uses PUSCH decoder
%   object PUSCHDEC to decode the codeword LLRS and returns the transport block
%   TBK in packed format. LLRS is a column vector of int8 with (quantized) channel
%   log-likelihood ratios. The logical flag NEWDATA tells the decoder whether
%   the codeword corresponds to a new transport block (NEWDATA = true) or
%   whether it corresponds to a retransmission of a previous transport block.
%   Structure SEGCONFIG describes the transport block segmentation. The fields are
%      base_graph      - the LDPC base graph;
%      modulation      - modulation identifier;
%      nof_ch_symbols  - the number of channel symbols corresponding to one codeword;
%      nof_layers      - the number of transmission layers;
%      rv              - the redundancy version;
%      Nref            - limited buffer rate matching length (set to zero for unlimited buffer);
%      tbs             - the transport block size.
%   Structure HARQBUFID identifies the HARQ buffer. The fields are
%      harq_ack_id    - the ID of the HARQ process;
%      rnti           - the UE RNTI;
%      nof_codeblocks - the number of codeblocks forming the codeword.
classdef srsPUSCHDecoder < matlab.System
    properties (Nontunable)
        %Maximum size of the codeblocks stored in the pool.
        maxCodeblockSize (1, 1) double {mustBePositive, mustBeInteger} = 1000
        %Maximum number of softbuffers managed by the pool.
        maxSoftbuffers   (1, 1) double {mustBePositive, mustBeInteger} = 1
        %Maximum number of codeblocks managed by the pool (shared by all softbuffers).
        maxCodeblocks    (1, 1) double {mustBePositive, mustBeInteger} = 1
    end % properties (Nontunable)

    properties (Access = private)
        %Unique identifier of the softbuffer pool used by the current PUSCH decoder.
        softbufferPoolID (1, 1) uint64 = 0
    end % properties (Access = private)

    methods
        function obj = srsPUSCHDecoder(varargin)
        %Constructor: sets nontunable properties.
            setProperties(obj, nargin, varargin{:});
        end % constructor

        function resetCRCS(obj, harqBufID)
        %Resets the CRC state of a softbuffer.
        %   resetCRCS(PUSCHDEC, HARQBUFID) tells the PUSCH decoder object PUSCHDEC to
        %   reset all the CRC indicators associated to the HARQ process corresponding
        %   to the buffer identified by HARQBUFID, a structure with fields
        %      harq_ack_id    - the ID of the HARQ process;
        %      rnti           - the UE RNTI;
        %      nof_codeblocks - the number of codeblocks forming the codeword.

            arguments
                obj       (1, 1) srsTest.phy.srsPUSCHDecoder
                harqBufID (1, 1) struct
            end

            if ~isLocked(obj)
                return;
            end

            fcnName = [class(obj) '/resetCRCS'];

            validateattributes(harqBufID.harq_ack_id, {'double'}, {'scalar', 'integer', 'nonnegative'},...
                fcnName, 'HARQ_ACK_ID');
            validateattributes(harqBufID.rnti, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'RNTI');
            validateattributes(harqBufID.nof_codeblocks, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_CODEBLOCKS');

            obj.pusch_decoder_mex('reset_crcs', obj.softbufferPoolID, harqBufID);
        end % of function transportBlock = step
    end % of methods

    methods (Access = protected)
        function setupImpl(obj)
        %Creates a softbuffer pool with the given characteristics and stores its ID.
            sbpdesc.max_codeblock_size = obj.maxCodeblockSize;
            sbpdesc.max_softbuffers = obj.maxSoftbuffers;
            sbpdesc.max_nof_codeblocks = obj.maxCodeblocks;
            % Not used (for now), but we need to set it to a value larger than 0.
            sbpdesc.expire_timeout_slots = 10;

            id = obj.pusch_decoder_mex('new', sbpdesc);

            obj.softbufferPoolID = id;
        end % of setupImpl

        function [transportBlock, stats] = stepImpl(obj, llrs, newData, segConfig, harqBufID)
            arguments
                obj       (1, 1) srsTest.phy.srsPUSCHDecoder
                llrs      (:, 1) int8
                newData   (1, 1) logical
                segConfig (1, 1) struct
                harqBufID (1, 1) struct
            end

            fcnName = [class(obj) '/step'];

            validateattributes(segConfig.nof_layers, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_LAYERS');
            validateattributes(segConfig.rv, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                fcnName, 'RV');
            validateattributes(segConfig.Nref, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                fcnName, 'NREF');
            validateattributes(segConfig.nof_ch_symbols, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_CH_SYMBOLS');
            modList = {'pi/2-BPSK', 'BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};
            validatestring(segConfig.modulation, modList, fcnName, 'MODULATION');

            validateattributes(harqBufID.harq_ack_id, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                fcnName, 'HARQ_ACK_ID');
            validateattributes(harqBufID.rnti, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'RNTI');
            validateattributes(harqBufID.nof_codeblocks, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_CODEBLOCKS');

            bpsList = [1, 1, 2, 4, 6, 8];
            ind = strcmpi(modList, segConfig.modulation);
            tmp = bpsList(ind);
            bps = tmp(1);

            nLLRS = segConfig.nof_ch_symbols * segConfig.nof_layers * bps;

            validateattributes(llrs, {'int8'}, {'numel', nLLRS}, fcnName, 'LLRS');

            [transportBlock, stats] = obj.pusch_decoder_mex('step', obj.softbufferPoolID, ...
               llrs, newData, segConfig, harqBufID);
        end % function step(...)

        function releaseImpl(obj)
        % Releases the softbuffer pool and sets softbufferPoolID to zero.

            obj.pusch_decoder_mex('release', obj.softbufferPoolID);
            obj.softbufferPoolID = 0;
        end % function releaseImpl(obj)
    end % of methods (Access = protected)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pusch_decoder_mex(varargin)
    end % of methods (Access = private)
end % of classdef srsPUSCHDecoder < handle
