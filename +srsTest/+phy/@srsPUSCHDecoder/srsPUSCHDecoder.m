%srsPUSCHDecoder MATLAB interface to SRGNB PUSCH decoder.
%   User-friendly interface to the SRSGNB PUSCH decoder class, which is wrapped
%   by the MEX static method pusch_decoder_mex.
%
%   PUSCHDEC = srsPUSCHDecoder(SBPDESC) creates a PHY Uplink Shared Channel decoder
%   object with a softbuffer pool defined by structure SBPDESC (whose fields are
%   dumped into property <a href="matlab:help srsTest.phy.srsPUSCHDecoder/softbufferPoolDescription">softbufferPoolDescription</a>).
%
%   srsPUSCHDecoder Properties (SetAccess = immutable):
%
%   softbufferPoolDescription - Description of the softbuffer pool.
%   softbufferPoolID          - Identifier of the softbuffer pool.
%
%   srsPUSCHDecoder Methods:
%
%   step            - Decodes one PUSCH codeword.
%   reset_crcs      - Resets the CRC state of a softbuffer.
classdef srsPUSCHDecoder < handle
    properties (SetAccess = immutable)
        %Describes a softbuffer pool.
        %   softbufferPoolDescription is a one-dimensional structure with fields:
        %      max_codeblock_size   - maximum size of the codeblocks stored in the pool;
        %      max_softbuffers      - maximum number of softbuffers managed by the pool;
        %      max_nof_codeblocks   - maximum number of codeblocks in each softbuffer; and
        %      expire_timeout_slots - softbuffer expiration time as a number of slots.
        softbufferPoolDescription (1, 1) struct
        %Unique identifier of the softbuffer pool used by the current PUSCH decoder.
        softbufferPoolID (1, 1) uint64
    end
    properties(Constant)
        mh = mexhost
    end
    methods
        function obj = srsPUSCHDecoder(sbpdesc)
            obj.softbufferPoolDescription = sbpdesc;
            obj.softbufferPoolID = feval(obj.mh, 'srsTest.phy.srsPUSCHDecoder.pusch_decoder_mex', ...
                'new', sbpdesc);
            % obj.softbufferPoolID = obj.pusch_decoder_mex('new', sbpdesc);
        end % constructor

        function [transportBlock, stats] = step(obj, llrs, newData, segConfig, harqBufID)
        %Decodes one PUSCH codeword.
        %   step(PUSCHDEC, LLRS, NEWDATA, SEGCONFIG, HARQBUFID) uses PUSCH decoder object
        %   PUSCHDEC to decode the codeword LLRS. LLRS is a column vector of int8 with
        %   (quantized) channel log-likelihood ratios. The logical flag NEWDATA tells the
        %   decoder whether the codeword corresponds to a new transport block (NEWDATA = true)
        %   or whether it corresponds to a retransmission of a previous transport block.
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

            % [transportBlock, stats] = obj.pusch_decoder_mex('step', obj.softbufferPoolID, ...
            %    llrs, newData, segConfig, harqBufID);
            [transportBlock, stats] = feval(obj.mh, 'srsTest.phy.srsPUSCHDecoder.pusch_decoder_mex', ...
                'step', obj.softbufferPoolID, llrs, newData, segConfig, harqBufID);
        end % function transportBlock = step

        function reset_crcs(obj, harqBufID)
        %Resets the CRC state of a softbuffer.
        %   RESET_CRCS(PUSCHDEC, HARQBUFID) tells the PUSCH decoder object PUSCHDEC to
        %   reset all the CRC indicators associated to the HARQ process corresponding
        %   to the buffer identified by HARQBUFID, a structure with fields
        %      harq_ack_id    - the ID of the HARQ process;
        %      rnti           - the UE RNTI;
        %      nof_codeblocks - the number of codeblocks forming the codeword.

            % obj.pusch_decoder_mex('reset_crcs', obj.softbufferPoolID, harqBufID);
            feval(obj.mh, 'srsTest.phy.srsPUSCHDecoder.pusch_decoder_mex', ...
                'reset_crcs', obj.softbufferPoolID, harqBufID);
        end % of function transportBlock = step
    end % of methods

    methods (Access = private, Static)
        varargout = pusch_decoder_mex(varargin)
    end % of methods (Access = private)
end % of classdef srsPUSCHDecoder < handle
