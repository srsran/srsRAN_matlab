%srsPUSCHDecoder MATLAB interface to SRSRAN PUSCH decoder.
%   User-friendly interface to the SRSRAN PUSCH decoder class, which is wrapped
%   by the MEX static method pusch_decoder_mex.
%
%   PUSCHDEC = srsPUSCHDecoder creates a PHY Uplink Shared Channel decoder
%   object, PUSCHDEC, with the default configuration.
%
%   PUSCHDEC = srsPUSCHDecoder(Name, Value) creates a PUSCH decoder object,
%   PUSCHDEC, with the specified property Name set to the specified Value.
%   You can specify additional name-value pair arguments in any order as
%   (Name1, Value1, Name2, Value2, ..., NameN, ValueN).
%
%   srsPUSCHDecoder Properties (Nontunable):
%
%   MaxCodeblockSize - Maximum size of the codeblocks stored in the pool (default 1000).
%   MaxSoftbuffers   - Maximum number of softbuffers managed by the pool (default 1).
%   MaxCodeblocks    - Maximum number of codeblocks managed by the pool
%                      (shared by all softbuffers, default 1).
%
%   srsPUSCHDecoder Properties (Access = private):
%
%   SoftbufferPoolID          - Identifier of the softbuffer pool.
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
%   object PUSCHDEC to decode the codeword LLRS and returns the decoded transport
%   block. LLRS is a column vector of int8 with (quantized) channel
%   log-likelihood ratios. The logical flag NEWDATA tells the decoder whether
%   the codeword corresponds to a new transport block (NEWDATA = true) or
%   whether it corresponds to a retransmission of a previous transport block.
%   Structure SEGCONFIG describes the transport block segmentation. The fields are
%      BGN                   - the LDPC base graph;
%      Modulation            - modulation identifier;
%      NumChSymbols          - the number of channel symbols corresponding to one codeword;
%      NumLayers             - the number of transmission layers;
%      RV                    - the redundancy version;
%      LimitedBufferSize     - limited buffer rate matching length (set to zero for
%                              unlimited buffer);
%      TransportBlockLength  - the transport block size.
%   Structure HARQBUFID identifies the HARQ buffer. The fields are
%      HARQProcessID  - the ID of the HARQ process;
%      RNTI           - the UE RNTI;
%      NumCodeblocks  - the number of codeblocks forming the codeword.
%   TBK is a vector of bytes of length equal to the transport block size.
%
%   TBK = step(..., FORMAT) allows specifing the format of the output transport
%   block: 'packed' bytes (default) or 'unpacked' bits.
%
%   [TBK, STATS] = step(...) also returns some statistics about the decoder. The
%   structure STATS has the following fields:
%      CRCOK               - equal to true if the CRC of the transport block is valid;
%      LDPCIterationsMax   - maximum number of LDPC iterations across all codeblocks
%                            of the transport block;
%      LDPCIterationsMean  - average number of LDPC iterations across all codeblocks
%                            of the transport block.

%   Copyright 2021-2025 Software Radio Systems Limited
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

classdef srsPUSCHDecoder < matlab.System
    properties (Nontunable)
        %Maximum size of the codeblocks stored in the pool.
        MaxCodeblockSize (1, 1) double {mustBePositive, mustBeInteger} = 1000
        %Maximum number of softbuffers managed by the pool.
        MaxSoftbuffers   (1, 1) double {mustBePositive, mustBeInteger} = 1
        %Maximum number of codeblocks managed by the pool (shared by all softbuffers).
        MaxCodeblocks    (1, 1) double {mustBePositive, mustBeInteger} = 1
    end % properties (Nontunable)

    properties (Access = private)
        %Unique identifier of the softbuffer pool used by the current PUSCH decoder.
        SoftbufferPoolID (1, 1) uint64 = 0
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
        %      HARQProcessID  - the ID of the HARQ process;
        %      RNTI           - the UE RNTI;
        %      NumCodeblocks  - the number of codeblocks forming the codeword.

            arguments
                obj       (1, 1) srsMEX.phy.srsPUSCHDecoder
                harqBufID (1, 1) struct
            end

            if ~isLocked(obj)
                return;
            end

            fcnName = [class(obj) '/resetCRCS'];

            validateattributes(harqBufID.HARQProcessID, {'double'}, {'scalar', 'integer', 'nonnegative'},...
                fcnName, 'HARQProcessID');
            validateattributes(harqBufID.RNTI, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'RNTI');
            validateattributes(harqBufID.NumCodeblocks, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NumCodeblocks');

            obj.pusch_decoder_mex('reset_crcs', obj.SoftbufferPoolID, harqBufID);
        end % of function resetCRCS

        function configure(obj, carrier, pusch, TargetCodeRate, NHARQProcesses, XOverhead)
            arguments
                obj            (1, 1) srsMEX.phy.srsPUSCHDecoder
                carrier        (1, 1) nrCarrierConfig
                pusch          (1, 1) nrPUSCHConfig
                TargetCodeRate (1, 1) double {mustBeInRange(TargetCodeRate, 0, 1, 'exclusive')} = 0.5
                NHARQProcesses (1, 1) double {mustBePositive, mustBeInteger} = 1
                XOverhead      (1, 1) double {mustBeNonnegative, mustBeInteger} = 0
            end

            [~, puschIndicesInfo] = nrPUSCHIndices(carrier, pusch);
            MRB = numel(pusch.PRBSet);
            trBlkSize = nrTBS(pusch.Modulation, pusch.NumLayers, MRB, puschIndicesInfo.NREPerPRB, TargetCodeRate, XOverhead);

            segmentInfo = nrULSCHInfo(trBlkSize, TargetCodeRate);

            obj.MaxCodeblocks = segmentInfo.C * NHARQProcesses;
            obj.MaxCodeblockSize = segmentInfo.N;
            obj.MaxSoftbuffers = NHARQProcesses;
        end % of function configure(obj, carrier, pusch, TargetCodeRate, NHARQProcesses, XOverhead)
    end % of methods

    methods (Access = protected)
        function setupImpl(obj)
        %Creates a softbuffer pool with the given characteristics and stores its ID.
            sbpdesc = obj.createSoftBufferDptn;

            id = obj.pusch_decoder_mex('new', sbpdesc);

            obj.SoftbufferPoolID = id;
        end % of setupImpl

        function [transportBlock, stats] = stepImpl(obj, llrs, newData, segConfig, harqBufID, dataType)
            arguments
                obj       (1, 1) srsMEX.phy.srsPUSCHDecoder
                llrs      (:, 1) int8
                newData   (1, 1) logical
                segConfig (1, 1) struct
                harqBufID (1, 1) struct
                dataType  (1, :) char {mustBeMember(dataType, {'packed', 'unpacked'})} = 'packed'
            end

            fcnName = [class(obj) '/step'];

            validateattributes(segConfig.NumLayers, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_LAYERS');
            validateattributes(segConfig.RV, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                fcnName, 'RV');
            validateattributes(segConfig.LimitedBufferSize, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                fcnName, 'NREF');
            validateattributes(segConfig.NumChSymbols, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_CH_SYMBOLS');
            modList = {'pi/2-BPSK', 'BPSK', 'QPSK', '16QAM', '64QAM', '256QAM'};
            validatestring(segConfig.Modulation, modList, fcnName, 'MODULATION');

            validateattributes(harqBufID.HARQProcessID, {'double'}, {'scalar', 'integer', 'nonnegative'}, ...
                fcnName, 'HARQ_ACK_ID');
            validateattributes(harqBufID.RNTI, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'RNTI');
            validateattributes(harqBufID.NumCodeblocks, {'double'}, {'scalar', 'integer', 'positive'}, ...
                fcnName, 'NOF_CODEBLOCKS');

            bpsList = [1, 1, 2, 4, 6, 8];
            ind = strcmpi(modList, segConfig.Modulation);
            tmp = bpsList(ind);
            bps = tmp(1);

            nLLRS = segConfig.NumChSymbols * segConfig.NumLayers * bps;

            validateattributes(llrs, {'int8'}, {'numel', nLLRS}, fcnName, 'LLRS');

            [transportBlock, stats] = obj.pusch_decoder_mex('step', obj.SoftbufferPoolID, ...
               llrs, newData, segConfig, harqBufID);

           if strcmp(dataType, 'unpacked')
               transportBlock = srsTest.helpers.bitUnpack(transportBlock);
           end
        end % function stepImpl(...)

        function resetImpl(obj)
        % Releases the softbuffer pool and creates a new one.
            if (obj.SoftbufferPoolID == 0)
                return;
            end

            obj.pusch_decoder_mex('release', obj.SoftbufferPoolID);
            setupImpl(obj);
        end

        function releaseImpl(obj)
        % Releases the softbuffer pool and sets SoftbufferPoolID to zero.
            if (obj.SoftbufferPoolID == 0)
                return;
            end

            obj.pusch_decoder_mex('release', obj.SoftbufferPoolID);
            obj.SoftbufferPoolID = 0;
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
            softbufferDptn.MaxCodeblockSize = obj.MaxCodeblockSize;
            softbufferDptn.MaxSoftbuffers = obj.MaxSoftbuffers;
            softbufferDptn.MaxCodeblocks = obj.MaxCodeblocks;
            % Not used (for now), but we need to set it to a value larger than 0.
            softbufferDptn.ExpireTimeoutSlots = 10;
        end
    end % of methods (Access = private)

    methods (Access = private, Static)
        %MEX function doing the actual work. See the Doxygen documentation.
        varargout = pusch_decoder_mex(varargin)
    end % of methods (Access = private, Static)

    methods (Static)
        function [segmentCfg, decoderCfg] = configureSegment(carrier, pusch, TargetCodeRate, NHARQProcesses, XOverhead)
        %configureSegment Static helper method for filling the SEGCONFIG input of "step"
        %   [SEGMENTCFG, DECODERCFG] = configureSegment(CARRIER, PUSCH, TARGETCODERATE, NHARQPROCESS, XOH)
        %   generates a segment configuration SEGMENTCFG and a decoder configuration DECODERCFG for
        %   a given target code rate TARGETCODERATE, a number of HARQ processes equal to NHARQPROCESS
        %   (default 1) and XOH bits of additional overhead (default 0). CARRIER and PUSCH are the nrCarrierConfig
        %   and nrPUSCHConfig objects, respectively, describing the tranmsission.
            arguments
                carrier        (1, 1) nrCarrierConfig
                pusch          (1, 1) nrPUSCHConfig
                TargetCodeRate (1, 1) double {mustBeInRange(TargetCodeRate, 0, 1, 'exclusive')}
                NHARQProcesses (1, 1) double {mustBePositive, mustBeInteger} = 1
                XOverhead      (1, 1) double {mustBeNonnegative, mustBeInteger} = 0
            end

            [~, puschIndicesInfo] = nrPUSCHIndices(carrier, pusch);
            MRB = numel(pusch.PRBSet);
            trBlkSize = nrTBS(pusch.Modulation, pusch.NumLayers, MRB, puschIndicesInfo.NREPerPRB, TargetCodeRate, XOverhead);
            segmentInfo = nrULSCHInfo(trBlkSize, TargetCodeRate);

            segmentCfg = struct();
            segmentCfg.NumLayers = pusch.NumLayers;
            segmentCfg.RV = 0;
            segmentCfg.LimitedBufferSize = 0;
            segmentCfg.NumChSymbols = puschIndicesInfo.Gd;
            segmentCfg.Modulation = pusch.Modulation;
            segmentCfg.BGN = segmentInfo.BGN;
            segmentCfg.TransportBlockLength = trBlkSize;
            segmentCfg.NumCodeblocks = segmentInfo.C;

            if (nargout == 2)
                decoderCfg = struct();
                decoderCfg.MaxCodeblocks = segmentInfo.C * NHARQProcesses;
                decoderCfg.MaxCodeblockSize = segmentInfo.N;
                decoderCfg.MaxSoftbuffers = NHARQProcesses;
            end
        end % of function configureSegment(...)
    end % of methods (Static)
end % of classdef srsPUSCHDecoder < matlab.System
