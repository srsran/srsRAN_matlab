%TESTVECTOR:
%   Abstract class for testvector generation implementations.
%
%   This class implements a common functionality used by testvector generation implementations,
%   namely saving test data to a file and conversion of test case
%   parameters to a string
%
classdef testvector
    methods (Access = protected)
        function testCaseString = testCaseToString(obj, configFormat, testVectName, testID, varargin)
            configStr = sprintf(configFormat, varargin{:});
            inFilename = [testVectName 'input' num2str(testID) '.dat'];
            outFilename = [testVectName 'output' num2str(testID) '.dat'];
  
            % generate the test case entry
            testCaseString = sprintf('  {%s,{"%s"},{"%s"}},\n', configStr, inFilename, outFilename);
        end

        % varargin is supposed to store list of arguments for saveFunction
        function saveDataFile(obj, baseFileName, direction, testID, outputPath, saveFunction, varargin)
            filename = [baseFileName direction num2str(testID) '.dat'];
            fullFilename = [outputPath '/' filename];
            feval(saveFunction, fullFilename, varargin{:});
        end
    end

    methods (Access = public)
        function packResults(obj, headerFilename, baseFileName, outputPath)
            % apply clang-format on generated .h file
            system(sprintf('clang-format -i -style=file %s', headerFilename));

            % gzip generated testvectors
            current_pwd = pwd();
            system(sprintf('cd %s && find . -regex ".*.dat" | xargs tar -czf %s_data.tar.gz && cd %s', ...
                            outputPath, baseFileName, current_pwd));
            system(sprintf('rm -rf %s/*.dat', outputPath));
        end
    end

    methods (Abstract)
        addTestCase(testID, varargin)
    end
end