classdef srsPUSCHDecoder < handle
    properties (SetAccess = immutable)
        softbufferPoolDescription (1, 1) struct
        softbufferPointer (1, 1) uint64
    end
    properties(Constant)
        mh = mexhost
    end
    methods
        function obj = srsPUSCHDecoder(sbpdesc)
            obj.softbufferPoolDescription = sbpdesc;
            obj.softbufferPointer = feval(obj.mh, 'srsTest.phy.srsPUSCHDecoder.pusch_decoder_mex', ...
                'new', sbpdesc);
            % obj.softbufferPointer = obj.pusch_decoder_mex('new', sbpdesc);
        end % constructor

        function [transportBlock, stats] = step(obj, llrs, new_data, seg_cfg)
            % [transportBlock, stats] = obj.pusch_decoder_mex('step', obj.softbufferPointer, ...
            %    llrs, new_data, seg_cfg);
            [transportBlock, stats] = feval(obj.mh, 'srsTest.phy.srsPUSCHDecoder.pusch_decoder_mex', ...
                'step', obj.softbufferPointer, llrs, new_data, seg_cfg);
        end % function transportBlock = step

        function reset_crcs(obj)
            % obj.pusch_decoder_mex('reset_crcs', obj.softbufferPointer);
            feval(obj.mh, 'srsTest.phy.srsPUSCHDecoder.pusch_decoder_mex', ...
                'reset_crcs', obj.softbufferPointer);
        end % function transportBlock = step
    end

    methods (Access = private, Static)
        varargout = pusch_decoder_mex(varargin)
    end % methods (Access = private)
end % classdef srsPUSCHDecoder < handle
