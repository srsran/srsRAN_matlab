%TESTVECTOR Test vector generation.
%   Common functionalitis shared by all test vector generation
%   implementations.
%
%   TESTVECTOR Methods:
%
%   addTestToHeaderFile  - Adds a new test entry to a upper
%         PHY channel processor unit header file.
%   closeHeaderFile  - Adds the closing content to a header
%        file for the upper PHY channel processor units.
%   createHeaderFile  - Creates a header file for the upper
%        PHY channel processor units.
%   createOutputFolder  - Creates the folder where the testvectors will be stored.
%
%   packResults  - Packs all generated testvectors in a single '.tar.gz' file.
%
%   saveDataFile  - Saves the test data to a file.
%
%   testCaseToString  - Converts the test case parameters to a string.

classdef TestVector
    properties
        objUnderTestPath = 'phy/upper/channel_processors';
        objUnderTestClass = 'phy';
        phyObjUnderTestClass = 'channel_processors'
    end

    methods (Access = private)
        function addTestDefinitionToHeaderFile(obj, fileID, unitUnderTest, callingFunc)
            fprintf(fileID, '#ifndef SRSGNB_UNITTESTS_%s_%s_TEST_DATA_H\n', obj.objUnderTestPath, upper(unitUnderTest));
            fprintf(fileID, '#define SRSGNB_UNITTESTS_%s_%s_TEST_DATA_H\n', obj.objUnderTestPath, upper(unitUnderTest));
            fprintf(fileID, '\n');
            fprintf(fileID, '// This file was generated using the following MATLAB scripts:\n');
            fprintf(fileID, '//   + "%s.m"\n', callingFunc);
            fprintf(fileID, '\n');
        end

        function createPhyClassHeaderFile(obj, unitUnderTest, outputPath, callingFunc)
            % create a new header file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'w');

            % add unit test definition
            addTestDefinitionToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest, callingFunc);

            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/complex.h"\n');
            if strcmp(obj.phyObjUnderTestClass, 'signal_processors')
                fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/to_array.h"\n');
            end
            fprintf(testvectorHeaderFileID, '#include "srsgnb/phy/upper/%s/%s.h"\n', lower(obj.phyObjUnderTestClass), unitUnderTest);
            fprintf(testvectorHeaderFileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(testvectorHeaderFileID, '#include <array>\n');
            if strcmp(obj.phyObjUnderTestClass, 'channel_processors') || strcmp(obj.phyObjUnderTestClass, 'signal_processors')
                fprintf(testvectorHeaderFileID, '#include "../../resource_grid_test_doubles.h"\n');
            end
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'namespace srsgnb {\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'struct test_case_t {\n');

            switch lower(obj.phyObjUnderTestClass)
              case {'channel_processors', 'signal_processors'}
                  fprintf(testvectorHeaderFileID, '  %s::config_t                                config;\n', unitUnderTest);
                  if strcmp(obj.phyObjUnderTestClass, 'channel_processors')
                      fprintf(testvectorHeaderFileID, '  file_vector<uint8_t>                                    data;\n');
                  end
                  fprintf(testvectorHeaderFileID, '  file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
              case 'channel_modulation'
                  fprintf(testvectorHeaderFileID, '  std::size_t nsymbols;\n');
                  fprintf(testvectorHeaderFileID, '  modulation_scheme scheme;\n');
                  fprintf(testvectorHeaderFileID, '  file_vector<uint8_t> data;\n');
                  fprintf(testvectorHeaderFileID, '  file_vector<cf_t> symbols;\n');
            end
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'static const std::vector<test_case_t> %s_test_data = {\n', unitUnderTest);
            fprintf(testvectorHeaderFileID, '// clang-format off\n');
            fclose(testvectorHeaderFileID);
        end
    end

    methods
        function obj = TestVector(objPath)
            obj.objUnderTestPath = objPath;
            obj.objUnderTestPath(obj.objUnderTestPath == '/') = '_';
            obj.objUnderTestPath = upper(obj.objUnderTestPath);

            % define the class of phy object under test
            ind = strfind(objPath, '/');
            obj.objUnderTestClass = objPath(1 : ind(1) - 1);
            phyObjectClass = objPath(ind(end) + 1 : end);
            obj.phyObjUnderTestClass = phyObjectClass;
        end

        function addTestToHeaderFile(obj, testEntryString, unitUnderTest, outputPath)
%addTestToHeaderFile(OBJ, TESTENTRYSTRING, UNITUNDERTEST, OUTPUTPATH)
%   adds a new test entry to a upper PHY channel processor unit header file.
%
%   Input parameters:
%      TESTENTRYSTRING - Test entry to be added to the header file (string).
%      UNITUNDERTEST   - Name of the current channel processor unit under test (string).
%      OUTPUTPATH      - Path where the channel processor header file should be created (string).

            % add a new test case entry to the header file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '%s', testEntryString);
            fclose(testvectorHeaderFileID);
        end

        function createHeaderFile(obj, unitUnderTest, outputPath, callingFunc)
%createHeaderFile(OBJ, UNITUNDERTEST, OUTPUTPATH, CALLINGFUNC)
%   creates a header file for the upper PHY channel processor units.
%
%   Input parameters:
%      UNITUNDERTEST - Name of the current channel processor unit under test (string).
%      OUTPUTPATH    - Path where the channel processor header file should be created (string).
%      CALLINGFUNC   - Name of the calling function (string).

            if ~strcmp(obj.objUnderTestClass, 'phy')
              error('testvectors generation is currently supported for "phy" objects only');
            end
            createPhyClassHeaderFile(obj, unitUnderTest, outputPath, callingFunc);
        end

        function closeHeaderFile(obj, unitUnderTest, outputPath)
%closeHeaderFile(OBJ, UNITUNDERTEST, OUTPUTPATH) adds the
%   closing content to a header file for the upper PHY channel processor units.
%
%   Input parameters:
%      UNITUNDERTEST - Name of the current channel processor unit under test (string).
%      OUTPUTPATH    - Path where the channel processor header file should be created.

            % write the closing header file contents
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '// clang-format on\n');
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '} // srsgnb\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID,'#endif // SRSGNB_UNITTESTS_%s_%s_TEST_DATA_H\n', obj.objUnderTestPath, upper(unitUnderTest));
            fclose(testvectorHeaderFileID);
        end

        function createOutputFolder(obj, baseFileName, outputPath)
%createOutputFolder(OBJ, BASEFILENAME, OUTPUTPATH) creates the folder where
%   the test vectors will be stored (deleting the previous test vectors, if any).
%
%   Input parameters:
%      BASEFILENAME  - Defines the base name of the test vector files (string).
%      OUTPUTPATH    - Path where the test vector files should be created (string).

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
%packResults(OBJ, HEADERFILENAME, BASEFILENAME, OUTPUTPATH) packs all generated
%   test vectors in a single '.tar.gz' file.
%
%   Input parameters:
%      HEADERFILENAME  - Defines the name of the related header file (string).
%      BASEFILENAME    - Defines the base name of the testvector files (string).
%      OUTPUTPATH      - Path where the test vector files should be created (string).

            % apply clang-format on generated .h file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, baseFileName);
            system(sprintf('LD_LIBRARY_PATH=/usr/lib clang-format -i -style=file %s', headerFilename));

            % gzip generated testvectors
            current_pwd = pwd();
            system(sprintf('cd %s && find . -regex ".*.dat" | grep "%s" | xargs tar -czf %s_test_data.tar.gz && cd %s', ...
                            outputPath, baseFileName, baseFileName, current_pwd));
            system(sprintf('rm -rf %s/%s*.dat', outputPath, baseFileName));
        end

        % varargin is supposed to store list of arguments for saveFunction
        function saveDataFile(obj, baseFileName, direction, testID, outputPath, saveFunction, varargin)
%saveDataFile(OBJ, BASEFILENAME, DIRECTION, TESTID, OUTPUTPATH, SAVEFUNCTION, VARARGIN)
%   saves the test data to a file.
%
%   Input parameters:
%      BASEFILENAME - Defines the base name of the testvector files (string).
%      DIRECTION    - Defines if the file is an input or an output to/from the test (string).
%      TESTID       - Unique identifier for the test case (integer).
%      OUTPUTPATH   - Defines the path where the file should be created (string).
%      SAVEFUCNTION - Defines which specific file-write function should be called (string).
%      VARARGIN     - Specific set of input parameters to the unit under test (variable length and type).

            filename = [baseFileName direction num2str(testID) '.dat'];
            fullFilename = [outputPath '/' filename];
            saveFunction(fullFilename, varargin{:});
        end

        function testCaseString = testCaseToString(obj, testVectName, testID, inAndOut, testCaseParams)
%testCaseToString(OBJ, CONFIGFORMAT, TESTVECTNAME, TESTID, VARARGIN) converts the
%   test case parameters to a string.
%
%   Input parameters:
%      CONFIGFORMAT - Defines the format of the configuration paramter struct (string).
%      TESTVECTNAME - Defines the base name of the testvector files (string).
%      TESTID       - Unique identifier for the test case (integer).
%      INANDOUT     - Defines if the test will generate input and output files (boolean).
%      VARARGIN     - Specific set of input parameters to the unit under test (variable length and type).
            configStr = cellarray2str(testCaseParams);
            inFilename = [testVectName '_test_input' num2str(testID) '.dat'];
            outFilename = [testVectName '_test_output' num2str(testID) '.dat'];

            % generate the test case entry (checking first if we generate both input and output data)
            if inAndOut
                testCaseString = sprintf('  {%s,{"%s"},{"%s"}},\n', configStr, inFilename, outFilename);
            else
                testCaseString = sprintf('  {%s,{"%s"}},\n', configStr, outFilename);
            end
        end
    end
end
