%srsBlockUnittest Test vector generation (Abstract class).
%   Common functionalities shared by all SRS unit tests. Derives from
%   'matlab.unittest.TestCase'.
%
%   srsBlockUnittest Properties (Abstract, Constant):
%
%   srsBlock      - Name of the tested block (e.g., 'pbch_modulator').
%   srsBlockType  - Type of the tested block (e.g., 'channel_processors').
%   srsBlockLayer - Layer of the tested block (e.g., 'phy/upper').
%
%   srsBlockUnittest Properties (Abstract, ClassSetupParameter):
%
%   outputPath  - Path to results folder (all contents will be erased).
%
%   srsBlockUnittest Methods (TestClassSetup):
%
%   initializeClass  - Test class setup.
%
%   srsBlockUnittest Methods (Abstract, Access = protected):
%
%   addTestIncludesToHeaderFile  - Adds include directives to the test header file.
%   addTestDetailsToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                  to the test header file.
%
%   srsBlockUnittest Methods:
%
%   closeHeaderFile  - Adds the closing content to the test header file.
%
%   srsBlockUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFilePHYchmod    - Adds include directives to the
%         header file for a block of type "channel_modulators".
%   addTestIncludesToHeaderFilePHYchproc   - Adds include directives to the
%         header file for a block of type "channel_processors".
%   addTestIncludesToHeaderFilePHYsigproc  - Adds include directives to the
%         header file for a block of type "signal_processors".
%   addTestDetailsToHeaderFilePHYchmod    - Adds test details to the
%         header file for a block of type "channel_modulators".
%   addTestDetailsToHeaderFilePHYchproc   - Adds test details to the
%         header file for a block of type "channel_processors".
%   addTestDetailsToHeaderFilePHYsigproc  - Adds test details to the
%         header file for a block of type "signal_processors".
%
%   srsBlockUnittest Methods (Access = private):
%
%   addTestDefinitionToHeaderFile  - Adds opening guards to a test header file.
%   createClassHeaderFile          - Creates the header file describing the test vectors.
%   teardown                       - Closes the header file and copies it, as
%                                    well as the binary data files, to the output folder.
%
%   srsBlockUnittest Methods (Static, Access = protected):
%
%   addTestToHeaderFile  - Adds a new test entry to a upper PHY channel processor
%                          unit header file.
%   createOutputFolder   - Creates the folder where the test vectors will be
%                          stored (deleting the previous test vectors, if any).
%   packResults          - Packs all generated test vectors in a single '.tar.gz' file.
%   saveDataFile         - Saves the test data to a file.
%
%   See also matlab.unittest.TestCase

classdef srsBlockUnittest < matlab.unittest.TestCase

    properties (Abstract, Constant)
        %Name of the tested block (e.g., 'pbch_modulator'). Abstract property.
        srsBlock      (1, :) char

        %Type of the tested block (e.g., 'channel_processors'). Abstract property.
        srsBlockType  (1, :) char

        %Layer of the tested block (e.g., 'phy/upper'). Abstract property.
        srsBlockLayer (1, :) char
    end % of properties (Abstract, Constant)

    properties (Abstract, ClassSetupParameter)
        %Path to results folder (old tests for the current block will be erased). Abstract property.
        outputPath (1, 1) cell {mustBeText(outputPath)}
    end % of properties (Abstract, ClassSetupParameter)

    properties (Hidden)
        %Path of the tested block relative to the SRSGNB include root folder,
        %in guard format (e.g., all capitals and with underscores).
        pathInRepo    (1, :) char

        %Tempoary working directory.
        tmpOutputPath (1, :) char {mustBeFolder(tmpOutputPath)} = '.'
    end % of properties (Hidden)

    methods (TestClassSetup)
        function initializeClass(obj, outputPath)
        %initializeClass Test class setup
        %   Creates the temporary working folder, defines its teardown, and creates the
        %   header file for the test vectors.
            tmp = obj.srsBlockLayer;
            tmp(tmp == filesep) = '_';
            obj.pathInRepo = upper([tmp, '_', obj.srsBlockType, '_', obj.srsBlock]);

            import matlab.unittest.fixtures.TemporaryFolderFixture;

            tmp = obj.applyFixture(TemporaryFolderFixture);
            obj.tmpOutputPath = tmp.Folder;

            obj.createClassHeaderFile(obj.srsBlock, obj.tmpOutputPath, class(obj));
            obj.addTeardown(@obj.teardown, outputPath);
        end
    end % of methods (TestClassSetup)

    methods (Abstract, Access = protected)
        %Adds include directives to the test header file. Abstract method.
        addTestIncludesToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest)

        %Adds details (e.g., type/variable declarations) to the test header file.
        %Abstract method.
        addTestDetailsToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest)
    end % of methods (Abstract, Access = protected)

    methods
        function closeHeaderFile(obj, unitUnderTest, outputPath)
        %closeHeaderFile(OBJ, UNITUNDERTEST, OUTPUTPATH) Adds the closing content to the
        %   test header file.
        %
        %   Input parameters:
        %      UNITUNDERTEST - Name of the unit under test (string).
        %      OUTPUTPATH    - Path where the header file will be created.

            % write the closing header file contents
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'a+');
            fprintf(testvectorHeaderFileID, '// clang-format on\n');
            fprintf(testvectorHeaderFileID, '};\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, '} // srsgnb\n');
            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID,'#endif // SRSGNB_UNITTESTS_%s_TEST_DATA_H\n', obj.pathInRepo);
            fclose(testvectorHeaderFileID);
        end
    end % of methods

    methods (Access = protected)
        function addTestIncludesToHeaderFilePHYsigproc(obj, testvectorHeaderFileID, unitUnderTest)
        %addTestIncludesToHeaderFilePHYsigproc(OBJ, TESTVECTORHEADERFILEID, UNITUNDERTEST)
        %   Adds include directives to the header file pointed by TESTVECTORHEADERFILEID,
        %   which describes the UNITUNDERTEST test vectors. UNITUNDERTEST is of type
        %   "signal_processors".

            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/complex.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/to_array.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/phy/upper/%s/%s.h"\n', ...
                lower(obj.srsBlockType), unitUnderTest);
            fprintf(testvectorHeaderFileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(testvectorHeaderFileID, '#include <array>\n');
            fprintf(testvectorHeaderFileID, '#include "../../resource_grid_test_doubles.h"\n');
        end

        function addTestIncludesToHeaderFilePHYchproc(obj, testvectorHeaderFileID, unitUnderTest)
        %addTestIncludesToHeaderFilePHYchproc(OBJ, TESTVECTORHEADERFILEID, UNITUNDERTEST)
        %   Adds include directives to the header file pointed by TESTVECTORHEADERFILEID,
        %   which describes the UNITUNDERTEST test vectors. UNITUNDERTEST is of type
        %   "channel_processors".

            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/complex.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/phy/upper/%s/%s.h"\n', ...
                lower(obj.srsBlockType), unitUnderTest);
            fprintf(testvectorHeaderFileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(testvectorHeaderFileID, '#include <array>\n');
            fprintf(testvectorHeaderFileID, '#include "../../resource_grid_test_doubles.h"\n');
        end

        function addTestIncludesToHeaderFilePHYchmod(obj, testvectorHeaderFileID, unitUnderTest)
        %addTestIncludesToHeaderFilePHYchmod(OBJ, TESTVECTORHEADERFILEID, UNITUNDERTEST)
        %   Adds include directives to the header file pointed by TESTVECTORHEADERFILEID,
        %   which describes the UNITUNDERTEST test vectors. UNITUNDERTEST is of type
        %   "channel_modulators".

            fprintf(testvectorHeaderFileID, '#include "srsgnb/adt/complex.h"\n');
            fprintf(testvectorHeaderFileID, '#include "srsgnb/phy/upper/%s/%s.h"\n', ...
                lower(obj.srsBlockType), unitUnderTest);
            fprintf(testvectorHeaderFileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(testvectorHeaderFileID, '#include <array>\n');
        end

        function addTestDetailsToHeaderFilePHYsigproc(~, testvectorHeaderFileID, unitUnderTest)
        %addTestDetailsToHeaderFilePHYsigproc(OBJ, TESTVECTORHEADERFILEID, UNITUNDERTEST)
        %   Adds test details (e.g., type/variable declarations) to the header file
        %   pointed by TESTVECTORHEADERFILEID, which describes the UNITUNDERTEST test
        %   vectors. UNITUNDERTEST is of type "signal_processors".

            fprintf(testvectorHeaderFileID, 'struct test_case_t {\n');
            fprintf(testvectorHeaderFileID, '%s::config_t config;\n', unitUnderTest);
            fprintf(testvectorHeaderFileID, ...
                'file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(testvectorHeaderFileID, '};\n');
        end

        function addTestDetailsToHeaderFilePHYchproc(~, testvectorHeaderFileID, unitUnderTest)
        %addTestDetailsToHeaderFilePHYchproc(OBJ, TESTVECTORHEADERFILEID, UNITUNDERTEST)
        %   Adds test details (e.g., type/variable declarations) to the header file
        %   pointed by TESTVECTORHEADERFILEID, which describes the UNITUNDERTEST test
        %   vectors. UNITUNDERTEST is of type "channel_processors".

            fprintf(testvectorHeaderFileID, 'struct test_case_t {\n');
            fprintf(testvectorHeaderFileID, '%s::config_t config;\n', unitUnderTest);
            fprintf(testvectorHeaderFileID, 'file_vector<uint8_t> data;\n');
            fprintf(testvectorHeaderFileID, ...
                'file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(testvectorHeaderFileID, '};\n');
        end

        function addTestDetailsToHeaderFilePHYchmod(~, testvectorHeaderFileID, ~)
        %addTestDetailsToHeaderFilePHYchmod(OBJ, TESTVECTORHEADERFILEID, UNITUNDERTEST)
        %   Adds test details (e.g., type/variable declarations) to the header file
        %   pointed by TESTVECTORHEADERFILEID, which describes the UNITUNDERTEST test
        %   vectors. UNITUNDERTEST is of type "channel_modulators".

            fprintf(testvectorHeaderFileID, 'struct test_case_t {\n');

            fprintf(testvectorHeaderFileID, 'std::size_t          nsymbols;\n');
            fprintf(testvectorHeaderFileID, 'modulation_scheme    scheme;\n');
            fprintf(testvectorHeaderFileID, 'file_vector<uint8_t> data;\n');
            fprintf(testvectorHeaderFileID, 'file_vector<cf_t>    symbols;\n');
            fprintf(testvectorHeaderFileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Access = private)
        function addTestDefinitionToHeaderFile(obj, fileID, callingFunc)
        %addTestDefinitionToHeaderFile Adds opening guards to a test header file.

            fprintf(fileID, '#ifndef SRSGNB_UNITTESTS_%s_TEST_DATA_H\n', obj.pathInRepo);
            fprintf(fileID, '#define SRSGNB_UNITTESTS_%s_TEST_DATA_H\n', obj.pathInRepo);
            fprintf(fileID, '\n');
            fprintf(fileID, '// This file was generated using the following MATLAB scripts:\n');
            fprintf(fileID, '//   + "%s.m"\n', callingFunc);
            fprintf(fileID, '\n');
        end

        function createClassHeaderFile(obj, unitUnderTest, outputPath, callingFunc)
        %createClassHeaderFile Creates the header file describing the test vectors.

            % create a new header file
            headerFilename = sprintf('%s/%s_test_data.h', outputPath, unitUnderTest);
            testvectorHeaderFileID = fopen(headerFilename, 'w');

            % add unit test definition
            addTestDefinitionToHeaderFile(obj, testvectorHeaderFileID, callingFunc);

            addTestIncludesToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest);

            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, 'namespace srsgnb {\n');
            fprintf(testvectorHeaderFileID, '\n');

            addTestDetailsToHeaderFile(obj, testvectorHeaderFileID, unitUnderTest);

            fprintf(testvectorHeaderFileID, '\n');
            fprintf(testvectorHeaderFileID, ...
                'static const std::vector<test_case_t> %s_test_data = {\n', unitUnderTest);
            fprintf(testvectorHeaderFileID, '// clang-format off\n');
            fclose(testvectorHeaderFileID);
        end

        function teardown(obj, outputPath)
        %teardown Closes the header file and copies it, as well as the binary data files,
        %   to the output folder.

            obj.closeHeaderFile(obj.srsBlock, obj.tmpOutputPath);

            tmp = dir([obj.tmpOutputPath, filesep, '*.dat']);
            if ~isempty(tmp)
                obj.packResults(obj.srsBlock, obj.tmpOutputPath);
                obj.createOutputFolder(obj.srsBlock, outputPath);
                cmd = sprintf('cp %s/%s_test_data.{h,tar.gz} %s', obj.tmpOutputPath, ...
                    obj.srsBlock, outputPath);
                system(cmd);
            end
        end
    end % of methods (Access = private)

    methods (Static, Access = protected)
        function addTestToHeaderFile(testEntryString, unitUnderTest, outputPath)
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

        function createOutputFolder(baseFileName, outputPath)
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
                if ~isempty(filenames)
                    system(sprintf('rm -rf %s/%s*.dat', outputPath, baseFileName));
                end
                % create the output directory
            else
                mkdir(sprintf('%s', outputPath))
            end
        end

        function packResults(baseFileName, outputPath)
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
        function saveDataFile(baseFileName, direction, testID, outputPath, saveFunction, varargin)
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

        function testCaseString = testCaseToString(testVectName, testID, inAndOut, testCaseParams, isStruct)
        %testCaseToString(OBJ, TESTVECTNAME, TESTID, INANDOUT, TESTCASEPARAMS, ISSTRUCT) converts the
        %   test case parameters to a string.
        %
        %   Input parameters:
        %      TESTVECTNAME   - Defines the base name of the testvector files (string).
        %      TESTID         - Unique identifier for the test case (integer).
        %      INANDOUT       - Defines if the test will generate input and output files (boolean).
        %      TESTCASEPARAMS - Cell array of test parameters.
        %      ISSTRUCT       - If TRUE, surrounds the output string with curly brackets.
            import srsTest.helpers.cellarray2str;
            configStr = cellarray2str(testCaseParams, isStruct);
            inFilename = [testVectName '_test_input' num2str(testID) '.dat'];
            outFilename = [testVectName '_test_output' num2str(testID) '.dat'];

            % generate the test case entry (checking first if we generate both input and output data)
            if inAndOut
                testCaseString = sprintf('  {%s,{"%s"},{"%s"}},\n', configStr, inFilename, outFilename);
            else
                testCaseString = sprintf('  {%s,{"%s"}},\n', configStr, outFilename);
            end
        end
    end % of methods (Static, Access = protected)
end
