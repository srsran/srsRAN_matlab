%srsBlockUnittest Unit test template for SRSGNB blocks (Abstract class).
%   Common functionalities shared by all SRS unit tests. Derives from
%   'matlab.unittest.TestCase'.
%
%   srsBlockUnittest Properties (Abstract, Constant):
%
%   srsBlock      - Name of the tested block (e.g., 'pbch_modulator').
%   srsBlockType  - Type of the tested block, including layer
%                   (e.g., 'phy/upper/channel_processors').
%
%   srsBlockUnittest Properties (Abstract, ClassSetupParameter):
%
%   outputPath  - Path to results folder (contents may be erased).
%
%   srsBlockUnittest Methods (TestClassSetup):
%
%   initializeClass  - Test class setup.
%
%   srsBlockUnittest Methods (Abstract, Access = protected):
%
%   addTestIncludesToHeaderFile    - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile  - Adds details (e.g., type/variable declarations)
%                                    to the test header file.
%
%   srsBlockUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFilePHYchmod     - Adds include directives to the
%         header file for a block of type "channel_modulators".
%   addTestIncludesToHeaderFilePHYchproc    - Adds include directives to the
%         header file for a block of type "channel_processors".
%   addTestIncludesToHeaderFilePHYsigproc   - Adds include directives to the
%         header file for a block of type "signal_processors".
%   addTestDefinitionToHeaderFilePHYchmod   - Adds test details to the
%         header file for a block of type "channel_modulators".
%   addTestDefinitionToHeaderFilePHYchproc  - Adds test details to the
%         header file for a block of type "channel_processors".
%   addTestDefinitionToHeaderFilePHYsigproc - Adds test details to the
%         header file for a block of type "signal_processors".
%
%   generateTestID     - Generates an identifier for the current test.
%   saveDataFile       - Records test data to a file.
%   testCaseToString   - Generates a test vector entry for the header file.
%
%   srsBlockUnittest Methods (Access = private):
%
%   createHeaderFile               - Creates the header file describing the test vectors.
%   closeHeaderFile                - Adds the closing content to the test header file
%                                    before closing it.
%   addOpendingToHeaderFile        - Adds opening guards to a test header file.
%   copyTestVectors                - Copies all the binary data files and the decription
%                                    header file to the output folder.
%   packResults                    - Packs all generated test vectors in a
%                                    single '.tar.gz' file.
%   createOutputFolder             - Creates the folder where the test vectors will be
%                                    stored (deleting the previous test vectors, if any).
%
%   srsBlockUnittest Methods (Static, Access = protected):
%
%   addTestToHeaderFile  - Adds a new test entry to a upper PHY channel processor
%                          unit header file.
%
%   See also matlab.unittest.TestCase

classdef srsBlockUnittest < matlab.unittest.TestCase

    properties (Abstract, Constant)
        %Name of the tested block (e.g., 'pbch_modulator'). Abstract property.
        srsBlock      (1, :) char

        %Type of the tested block, including layer (e.g., 'phy/upper/channel_processors').
        %Abstract property.
        srsBlockType  (1, :) char
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

        %Test header file identifier.
        headerFileID (1, 1) double {mustBeInteger(headerFileID)} = -1
    end % of properties (Hidden)

    methods (TestClassSetup)
        function initializeClass(obj, outputPath)
        %initializeClass Test class setup
        %   Creates the temporary working folder, defines its teardown, and creates the
        %   header file for the test vectors.
            tmp = obj.srsBlockType;
            tmp(tmp == filesep) = '_';
            obj.pathInRepo = upper([tmp, '_', obj.srsBlock]);

            import matlab.unittest.fixtures.TemporaryFolderFixture;

            tmp = obj.applyFixture(TemporaryFolderFixture);
            obj.tmpOutputPath = tmp.Folder;

            obj.headerFileID = obj.createHeaderFile;

            % Add teardown steps, in reverse order (it's a LIFO stack).
            obj.addTeardown(@obj.copyTestVectors, outputPath);

            obj.addTeardown(@obj.closeHeaderFile, obj.headerFileID);
        end
    end % of methods (TestClassSetup)

    methods (Abstract, Access = protected)
        %Adds include directives to the test header file. Abstract method.
        addTestIncludesToHeaderFile(obj, fileID)

        %Adds details (e.g., type/variable declarations) to the test header file.
        %Abstract method.
        addTestDefinitionToHeaderFile(obj, fileID)
    end % of methods (Abstract, Access = protected)

    methods (Access = protected)
        function addTestIncludesToHeaderFilePHYsigproc(obj, fileID)
        %addTestIncludesToHeaderFilePHYsigproc(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors. This
        %   method is meant for blocks of type "phy/upper/signal_processors".

            fprintf(fileID, '#include "srsgnb/adt/complex.h"\n');
            if ~strcmp(obj.srsBlock, 'dmrs_pdsch_processor')
                fprintf(fileID, '#include "srsgnb/adt/to_array.h"\n');
            end
            fprintf(fileID, '#include "srsgnb/%s/%s.h"\n', ...
                obj.srsBlockType, obj.srsBlock);
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            if ~strcmp(obj.srsBlock, 'dmrs_pdsch_processor')
                fprintf(fileID, '#include <array>\n');
            else
                fprintf(fileID, '#include <vector>\n');
            end
            fprintf(fileID, '#include "../../resource_grid_test_doubles.h"\n');
        end

        function addTestIncludesToHeaderFilePHYchproc(obj, fileID)
        %addTestIncludesToHeaderFilePHYsigproc(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors. This
        %   method is meant for blocks of type "phy/upper/channel_processors".

            if ~endsWith(obj.srsBlock, '_encoder')
                fprintf(fileID, '#include "srsgnb/adt/complex.h"\n');
            end
            fprintf(fileID, '#include "srsgnb/%s/%s.h"\n', ...
                obj.srsBlockType, obj.srsBlock);
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            if ~endsWith(obj.srsBlock, '_encoder')
                fprintf(fileID, '#include <array>\n');
                fprintf(fileID, '#include "../../resource_grid_test_doubles.h"\n');
            end
        end

        function addTestIncludesToHeaderFilePHYchmod(obj, fileID)
        %addTestIncludesToHeaderFilePHYsigproc(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors. This
        %   method is meant for blocks of type "phy/upper/channel_modulation".

            fprintf(fileID, '#include "srsgnb/adt/complex.h"\n');
            fprintf(fileID, '#include "srsgnb/%s/%s.h"\n', ...
                obj.srsBlockType, obj.srsBlock);
            fprintf(fileID, '#include "srsgnb/support/file_vector.h"\n');
            fprintf(fileID, '#include <array>\n');
        end

        function addTestDefinitionToHeaderFilePHYsigproc(obj, fileID)
        %addTestDefinitionToHeaderFilePHYchproc(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors. This method is meant for blocks of type
        %   "phy/upper/signal_processors".

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '%s::config_t config;\n', obj.srsBlock);
            fprintf(fileID, ...
                'file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            fprintf(fileID, '};\n');
        end

        function addTestDefinitionToHeaderFilePHYchproc(obj, fileID)
        %addTestDefinitionToHeaderFilePHYchproc(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors. This method is meant for blocks of type
        %   "phy/upper/channel_processors".

            fprintf(fileID, 'struct test_case_t {\n');
            if endsWith(obj.srsBlock, 'encoder')
                if strcmp(obj.srsBlock, 'pbch_encoder')
                    fprintf(fileID, '  %s::pbch_msg_t           pbch_msg;\n', obj.srsBlock);
                else
                    fprintf(fileID, '%s::config_t config;\n', obj.srsBlock);
                    fprintf(fileID, 'file_vector<uint8_t>  message;\n');
                end
                fprintf(fileID, '  file_vector<uint8_t>     encoded;\n');
            else
                fprintf(fileID, '%s::config_t config;\n', obj.srsBlock);
                fprintf(fileID, 'file_vector<uint8_t> data;\n');
                fprintf(fileID, ...
                    'file_vector<resource_grid_writer_spy::expected_entry_t> symbols;\n');
            end
            fprintf(fileID, '};\n');
        end

        function addTestDefinitionToHeaderFilePHYchmod(~, fileID)
        %addTestDefinitionToHeaderFilePHYchmod(OBJ, FILEID) adds test details (e.g., type
        %   and variable declarations) to the header file pointed by FILEID, which
        %   describes the test vectors. This method is meant for blocks of type
        %   "phy/upper/channel_modulation".

            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, 'std::size_t          nsymbols;\n');
            fprintf(fileID, 'modulation_scheme    scheme;\n');
            fprintf(fileID, 'file_vector<uint8_t> data;\n');
            fprintf(fileID, 'file_vector<cf_t>    symbols;\n');
            fprintf(fileID, '};\n');
        end

        function testID = generateTestID(obj)
        %generateTestID Generates an identifier for the current test.
            filenameTemplateIn = sprintf('%s/%s_test_input*', obj.tmpOutputPath, obj.srsBlock);
            filenameTemplateOut = sprintf('%s/%s_test_output*', obj.tmpOutputPath, obj.srsBlock);
            testID = max(numel(dir(filenameTemplateIn)), numel(dir(filenameTemplateOut)));
        end

        % varargin is supposed to store list of arguments for saveFunction
        function saveDataFile(obj, suffix, testID, saveFunction, varargin)
        %saveDataFile Records test data
        %   saveDataFile(OBJ, SUFFIX, TESTID, SAVEFUNCTION, VAR) saves the data in
        %   variable VAR, relative to test number TESTID, to a binary file using the function
        %   pointed by the function handle SAVEFUCNTION. SUFFIX is a character string
        %   that is appended to the file name (e.g., 'test_input' or 'test_output').
        %   saveDataFile(OBJ, DIRECTION, TESTID, SAVEFUNCTION, VAR1, VAR2, ...) saves
        %   the data of all variables VAR1, VAR2, ...

            filename = [obj.srsBlock suffix num2str(testID) '.dat'];
            fullFilename = [obj.tmpOutputPath '/' filename];
            saveFunction(fullFilename, varargin{:});
        end

        function testCaseString = testCaseToString(obj, testID, inAndOut, testCaseParams, isStruct)
        %testCaseToString Generates a test entry for the header file.
        %   testCaseToString(OBJ, TESTID, INANDOUT, TESTCASEPARAMS, ISSTRUCT) generates a
        %   data string for test number TESTID. The INANDOUT flag specifies whether the
        %   test includes both input and output test vectors (TRUE) or ouptut only (FALSE).
        %   The data string is generated from the parameters in the cell array TESTCASEPARAMS.
        %   The flag ISSTRUCT instructs the method to surround the output string with
        %   curly brackets (TRUE) or not (FALSE).

            import srsTest.helpers.cellarray2str;
            configStr = cellarray2str(testCaseParams, isStruct);
            inFilename = [obj.srsBlock '_test_input' num2str(testID) '.dat'];
            outFilename = [obj.srsBlock '_test_output' num2str(testID) '.dat'];

            % generate the test case entry (checking first if we generate both input and output data)
            if inAndOut
                testCaseString = sprintf('  {%s, {"%s"}, {"%s"}},\n', configStr, inFilename, outFilename);
            else
                testCaseString = sprintf('  {%s, {"%s"}},\n', configStr, outFilename);
            end
        end
    end % of methods (Access = protected)

    methods (Access = private)
        function fileID = createHeaderFile(obj)
        %createHeaderFile Creates the header file describing the test vectors.

            % create a new header file
            headerFilename = sprintf('%s/%s_test_data.h', obj.tmpOutputPath, obj.srsBlock);
            fileID = fopen(headerFilename, 'w');

            % add unit test definition
            addOpeningToHeaderFile(obj, fileID);

            addTestIncludesToHeaderFile(obj, fileID);

            fprintf(fileID, '\n');
            fprintf(fileID, 'namespace srsgnb {\n');
            fprintf(fileID, '\n');

            addTestDefinitionToHeaderFile(obj, fileID);

            fprintf(fileID, '\n');
            fprintf(fileID, ...
                'static const std::vector<test_case_t> %s_test_data = {\n', obj.srsBlock);
            fprintf(fileID, '// clang-format off\n');
        end

        function closeHeaderFile(obj, fileID)
        %closeHeaderFile(OBJ, FILEID) Adds the closing content to the
        %   test header file with MATLAB identifier FILEID before closing it.

            % write the closing header file contents
            fprintf(fileID, '// clang-format on\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, '} // srsgnb\n');
            fprintf(fileID, '\n');
            fprintf(fileID,'#endif // SRSGNB_UNITTESTS_%s_TEST_DATA_H\n', obj.pathInRepo);

            fclose(fileID);
        end

        function addOpeningToHeaderFile(obj, fileID)
        %addOpeningToHeaderFile Adds opening guards to a test header file.

            fprintf(fileID, '#ifndef SRSGNB_UNITTESTS_%s_TEST_DATA_H\n', obj.pathInRepo);
            fprintf(fileID, '#define SRSGNB_UNITTESTS_%s_TEST_DATA_H\n', obj.pathInRepo);
            fprintf(fileID, '\n');
            fprintf(fileID, '// This file was generated using the following MATLAB class:\n');
            fprintf(fileID, '//   + "%s.m"\n', class(obj));
            fprintf(fileID, '\n');
        end

        function copyTestVectors(obj, outputPath)
        %copyTestVectors(OBJ, OUTPUTPATH) Copies all the binary data files and the decription
        %   header file to the output folder.

            tmp = dir([obj.tmpOutputPath, filesep, '*.dat']);
            if ~isempty(tmp)
                obj.packResults;
                obj.createOutputFolder(outputPath);
                cmd = sprintf('cp %s/%s_test_data.{h,tar.gz} %s', obj.tmpOutputPath, ...
                    obj.srsBlock, outputPath);
                system(cmd);

                % apply clang-format to header file
                formatCmd = sprintf(['LD_LIBRARY_PATH=/usr/lib clang-format -i', ...
                    ' -style=file %s/%s_test_data.h'], outputPath, obj.srsBlock);
                system(formatCmd);
            end
        end

        function packResults(obj)
        %packResults(OBJ) packs all generated test vectors in a single '.tar.gz' file.

            % gzip generated testvectors
            current_pwd = pwd();
            system(sprintf('cd %s && find . -regex ".*.dat" | grep "%s" | xargs tar -czf %s_test_data.tar.gz && cd %s', ...
                obj.tmpOutputPath, obj.srsBlock, obj.srsBlock, current_pwd));
            system(sprintf('rm -rf %s/%s*.dat', obj.tmpOutputPath, obj.srsBlock));
        end

        function createOutputFolder(obj, outputPath)
        %createOutputFolder(OBJ, OUTPUTPATH) creates the folder, as defined by the path
        %   OUTPUTPATH, where the test vectors will be stored (deleting the previous
        %   test vectors, if any).

            % delete previous testvectors (if any)
            if isfolder(outputPath)
                filenameTemplate = sprintf('%s/%s*.dat', outputPath, obj.srsBlock);
                file = dir(filenameTemplate);
                filenames = {file.name};
                if ~isempty(filenames)
                    system(sprintf('rm -rf %s/%s*.dat', outputPath, obj.srsBlock));
                end
                % create the output directory
            else
                mkdir(outputPath)
            end
        end
    end % of methods (Access = private)

    methods (Static, Access = protected)
        function addTestToHeaderFile(fileID, testEntryString)
        %addTestToHeaderFile(OBJ, FILEID, TESTENTRYSTRING) adds the test entry
        %   TESTENTRYSTRING to the test header file with MATLAB identifier FILEID.

            % add a new test case entry to the header file
            fprintf(fileID, '%s', testEntryString);
        end
    end % of methods (Static, Access = protected)
end % of classdef srsBlockUnittest
