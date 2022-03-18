%TESTVECTOR:
%   Class for testvector generation implementations.
%
%   This class implements a common functionality used by testvector generation implementations,
%
%  TESTVECTOR Methods:
%    The following methods are available:
%      * addTestToChannelProcessorsHeaderFile(obj, testEntryString, unitUnderTest, outputPath)
%        adds a new test entry to a upper PHY channel processor units header file, receives the
%        input parameters
%        * string TESTENTRYSTRING - test entry to be added to the header file
%        * string UNITUNDERTEST   - name of the current channel processor unit under test
%        * string OUTPUTPATH      - path where the channel processor header file should be created
%      * closeChannelProcessorsHeaderFile(obj, unitUnderTest, outputPath) adds the closing content
%        to a header file for the upper PHY channel processor units, receives the input parameters
%        * string UNITUNDERTEST - name of the current channel processor unit under test
%        * string OUTPUTPATH    - path where the channel processor header file should be created
%      * createChannelProcessorsHeaderFile(obj, unitUnderTest, outputPath, callingFunc) creates
%        a header file for the upper PHY channel processor units, receives the input parameters
%        * string UNITUNDERTEST - name of the current channel processor unit under test
%        * string OUTPUTPATH    - path where the channel processor header file should be created
%        * string CALLINGFUNC   - name of the calling function
%      * createOutputFolder(obj, baseFileName, outputPath) creates the folder where testvectors
%        will be stored (deleting the previous testvectors, if any), receives the input parameters
%        * string BASEFILENAME  - defines the base name of the testvector files
%        * string OUTPUTPATH    - path where the testvector files should be created
%      * packResults(obj, headerFilename, baseFileName, outputPath) packs all generated testvectors
%        in a single .tar.gz file, receives the input parameters
%        * string HEADERFILENAME  - defines the name of the related header file
%        * string BASEFILENAME    - defines the base name of the testvector files
%        * string OUTPUTPATH      - path where the testvector files should be created
%      * saveDataFile(obj, baseFileName, direction, testID, outputPath, saveFunction, varargin) saves
%        the test data to a file, receives the input parameters
%        * string BASEFILENAME - defines the base name of the testvector files
%        * string DIRECTION    - defines if the file is an input or an output to/from the test
%        * double TESTID       - unique identifier for the test case
%        * string OUTPUTPATH   - defines the path where the file should be created
%        * variable VARARGIN   - specific set of input parameters to the unit under test
%        * string SAVEFUCNTION - defines which specific file-write function should be called
%        * variable VARARGIN   - specific set of input parameters to the file-write function
%      * testCaseString(obj, configFormat, testVectName, testID, varargin) converts the test case
%        parameters to a string, receives the input parameters
%        * string CONFIGFORMAT - defines the format of the configuration paramter struct
%        * string TESTVECTNAME - defines the base name of the testvector files
%        * double TESTID       - unique identifier for the test case
%        * variable VARARGIN   - specific set of input parameters to the unit under test

classdef testvector
    methods
        function addTestToChannelProcessorsHeaderFile(obj, testEntryString, unitUnderTest, outputPath)
            % add a new test case entry to the header file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '%s', testEntryString);
            fclose(testvectorHeaderFileID);
        end

        function closeChannelProcessorsHeaderFile(obj, unitUnderTest, outputPath)
            % write the closing header file contents
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '} // srsgnb\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID,'#endif // SRSGNB_UNITTEST_PHY_CHANNEL_PROCESSORS_%s_TEST_DATA_H\n', upper(unitUnderTest));
            fclose(testvectorHeaderFileID);
        end

        function createChannelProcessorsHeaderFile(obj, unitUnderTest, outputPath, callingFunc)
            % create a new header file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'w');

            % add unit test definition
            fprintf(testvectorHeaderFileID, '#ifndef SRSGNB_UNITTESTS_PHY_CHANNEL_PROCESSORS_%s_TEST_DATA_H\n', upper(unitUnderTest));
            fprintf(testvectorHeaderFileID, '#define SRSGNB_UNITTESTS_PHY_CHANNEL_PROCESSORS_%s_TEST_DATA_H\n', upper(unitUnderTest));
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '// This file was generated using the following MATLAB scripts:\n');
            fprintf(testvectorHeaderFileID, '//   + "%s.m"\n', mfilename);
            fprintf(testvectorHeaderFileID, '//   + "%s.m"\n', callingFunc);
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '#include "../../resource_grid_test_doubles.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/complex.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/phy/upper/channel_processors/%s.h"\n', unitUnderTest);
            fprintf(testvectorHeaderFileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(testvectorHeaderFileID, '#include <array>\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'namespace srsgnb {\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'struct test_case_t {\n');
            fprintf(testvectorHeaderFileID, '  %s::config_t                                config;\n', unitUnderTest);
            fprintf(testvectorHeaderFileID, '  file_vector<uint8_t>                                    data;\n');
            fprintf(testvectorHeaderFileID, '  file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'static const std::vector<test_case_t> %s_test_data = {\n', unitUnderTest);
            fclose(testvectorHeaderFileID);
        end

        function createOutputFolder(obj, baseFileName, outputPath)
            % delete previous testvectors (if any)
            if isfolder(sprintf('%s', outputPath))
              filenameTemplate = sprintf('%s/%s*.dat', outputPath, baseFileName);
              file = dir (filenameTemplate);
              filenames = {file.name};
              if length(filenames) > 0
                system(sprintf('rm -rf %s/%s*.dat', outputPath, baseFileName));
              end
            % create the output directory
            else
                mkdir(sprintf('%s', outputPath))
            end
        end

        function packResults(obj, baseFileName, outputPath)
            % apply clang-format on generated .h file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, baseFileName);
            system(sprintf('clang-format -i -style=file %s', headerFilename));

            % gzip generated testvectors
            current_pwd = pwd();
            system(sprintf('cd %s && find . -regex ".*.dat" | grep "%s" | xargs tar -czf %s_test_data.tar.gz && cd %s', ...
                            outputPath, baseFileName, baseFileName, current_pwd));
            system(sprintf('rm -rf %s/%s*.dat', outputPath, baseFileName));
        end

        % varargin is supposed to store list of arguments for saveFunction
        function saveDataFile(obj, baseFileName, direction, testID, outputPath, saveFunction, varargin)
            filename = [baseFileName direction num2str(testID) '.dat'];
            fullFilename = [outputPath '/' filename];
            feval(saveFunction, fullFilename, varargin{:});
        end

        function testCaseString = testCaseToString(obj, configFormat, testVectName, testID, varargin)
            configStr = sprintf(configFormat, varargin{:});
            inFilename = [testVectName '_test_input' num2str(testID) '.dat'];
            outFilename = [testVectName '_test_output' num2str(testID) '.dat'];

            % generate the test case entry
            testCaseString = sprintf('  {%s,{"%s"},{"%s"}},\n', configStr, inFilename, outFilename);
        end
    end
end
