%srsPUSCHDecoder MATLAB interface to SRSRAN PUSCH decoder.
%   User-friendly interface to the SRSRAN PUSCH decoder class, which is wrapped
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
%   step               - Decodes one PUSCH codeword.
%   resetCRCS          - Resets the CRC state of a softbuffer.
%   release            - Allows reconfiguration.
%   reset              - Clears the content of the softbuffer pool.
%   isLocked           - Locked status (logical).
%   configureSegment   - Static helper method for filling the SEGCONFIG input of "step".
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
%      Nref            - limited buffer rate matching length (set to zero for
%                        unlimited buffer);
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
            sbpdesc = obj.createSoftBufferDptn;

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

        function resetImpl(obj)
        % Releases the softbuffer pool and creates a new one.
            if (obj.softbufferPoolID == 0)
                return;
            end

            obj.pusch_decoder_mex('release', obj.softbufferPoolID);
            setupImpl(obj);
        end

        function releaseImpl(obj)
        % Releases the softbuffer pool and sets softbufferPoolID to zero.
            if (obj.softbufferPoolID == 0)
                return;
            end

            obj.pusch_decoder_mex('release', obj.softbufferPoolID);
            obj.softbufferPoolID = 0;
        end % function releaseImpl(obj)

        function s = saveObjectImpl(obj)
        % Save all public properties.
        % Note: At the moment we have no access to the internal memory of the MEX block and
        % we can only save the configuration of the decoder, not its state.
            s = saveObjectImpl@matlab.System(obj);
        end

        function loadObjectImpl(obj, s, wasInUse)
        % Loads an srsPUSCHDecoder object from a file.
        % Note: Due to the limitations of the mex, we can only save the configuration of
        % the decoder, not its internal (MEX) state. Therefore, even if the object was
        % saved in the locked state, this function returns an object with an empty
        % softbuffer pool.
            loadObjectImpl@matlab.System(obj, s, wasInUse);

            if wasInUse
                setupImpl(obj);
            end
        end
    end % of methods (Access = protected)

    methods (Access = private)
        function softbufferDptn = createSoftBufferDptn(obj)
        %Creates a softbuffer configuration structure.
            softbufferDptn.max_codeblock_size = obj.maxCodeblockSize;
            softbufferDptn.max_softbuffers = obj.maxSoftbuffers;
            softbufferDptn.max_nof_codeblocks = obj.maxCodeblocks;
            % Not used (for now), but we need to set it to a value larger than 0.
            softbufferDptn.expire_timeout_slots = 10;
        end
    end % of methods (Access = private)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pusch_decoder_mex(varargin)
    end % of methods (Access = private)

    methods (Static)
        function segmentCfg = configureSegment(NumLayers, NumREs, TBSize, TargetCodeRate, Modulation, RV, Nref)
        %configureSegment Static helper method for filling the SEGCONFIG input of "step"
        %   SEGMENTCFG = configureSegment(NUMLAYERS, NUMRES, TBSIZE, TARGETCODERATE, MODULATION, RV, NREF)
        %   generates a segment configuration for NUMLAYERS transmission layers, NUMRES allocated REs per layer,
        %   transport block size TBSIZE, target code rate TARGETCODERATE, modulation MODULATION and redundancy
        %   version RV. NREF limits the rate-matcher buffer size (set to zero for unlimited buffer size).
            arguments
                NumLayers      (1, 1) double {mustBeInteger, mustBeInRange(NumLayers, 1, 4)} = 1
                NumREs         (1, 1) double {mustBeInteger, mustBePositive} = 12
                TBSize         (1, 1) double {mustBeInteger, mustBePositive} = 100
                TargetCodeRate (1, 1) double {mustBeInRange(TargetCodeRate, 0, 1, 'exclusive')} = 0.5
                Modulation     (1, :) char   {mustBeMember(Modulation, ...
                                                  {'pi/2-BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'})} = 'QPSK'
                RV             (1, 1) double {mustBeInteger, mustBeInRange(RV, 0, 3)} = 0
                Nref           (1, 1) double {mustBeInteger, mustBeNonnegative} = 0
            end

            segmentInfo = nrULSCHInfo(TBSize, TargetCodeRate);

            segmentCfg.nof_layers = NumLayers;
            segmentCfg.rv = RV;
            segmentCfg.Nref = Nref;
            segmentCfg.nof_ch_symbols = NumREs;
            segmentCfg.modulation = Modulation;
            segmentCfg.base_graph = segmentInfo.BGN;
            segmentCfg.tbs = TBSize;
            segmentCfg.nof_codeblocks = segmentInfo.C;
        end % of function segmentCfg = configureSegment(...)
    end % of methods (Static)
end % of classdef srsPUSCHDecoder < matlab.System
