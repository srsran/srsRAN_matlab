%srsBlockUnittest Unit test template for srsRAN blocks (Abstract class).
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

    properties (ClassSetupParameter)
        %Flag for initializing the random generator with the default seed (true)
        %   or with one based on the current time (false).
        %   Non-expert users are advised against changing this flag.
        RandomDefault = {true}
    end

    properties (Hidden)
        %Path of the tested block relative to the srsRAN include root folder,
        %in guard format (e.g., all capitals and with underscores).
        pathInRepo    (1, :) char

        %Tempoary working directory.
        tmpOutputPath (1, :) char {mustBeFolder(tmpOutputPath)} = '.'

        %Test header file identifier.
        headerFileID (1, 1) double {mustBeInteger(headerFileID)} = -1

        %Seed used by the random generator.
        RngSeed
    end % of properties (Hidden)

    methods (TestClassSetup)
        function initializeClass(obj, outputPath, RandomDefault)
        %initializeClass Test class setup
        %   Creates the temporary working folder, defines its teardown, and creates the
        %   header file for the test vectors. Initializes the random generator.
            tmp = obj.srsBlockType;
            tmp(tmp == filesep) = '_';
            obj.pathInRepo = upper([tmp, '_', obj.srsBlock]);

            import matlab.unittest.fixtures.TemporaryFolderFixture;

            tmp = obj.applyFixture(TemporaryFolderFixture);
            obj.tmpOutputPath = tmp.Folder;

            % Get current random generator state.
            orig = rng;

            if RandomDefault
                % Initialize the random generator to its default state for reproducible
                % results.
                rng('default');
            else
                % Initialize the random generator with a seed based on the current
                % time for producing a completely different set of results.
                rng('shuffle');
            end

            curr = rng;
            obj.RngSeed = curr.Seed;

            obj.headerFileID = obj.createHeaderFile;

            obj.initializeClassImpl();

            % Add teardown steps, in reverse order (it's a LIFO stack).
            obj.addTeardown(@rng, orig);

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

            fprintf(fileID, '#include "srsran/%s/%s.h"\n', ...
                obj.srsBlockType, obj.srsBlock);
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
        end

        function addTestIncludesToHeaderFilePHYchproc(obj, fileID)
        %addTestIncludesToHeaderFilePHYchproc(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors. This
        %   method is meant for blocks of type "phy/upper/channel_processors".

            fprintf(fileID, '#include "srsran/%s/%s.h"\n', ...
                obj.srsBlockType, obj.srsBlock);
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
            if ~endsWith(obj.srsBlock, '_encoder')
                fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            end
        end

        function addTestIncludesToHeaderFilePHYchmod(obj, fileID)
        %addTestIncludesToHeaderFilePHYchmod(OBJ, FILEID) adds include directives to
        %   the header file pointed by FILEID, which describes the test vectors. This
        %   method is meant for blocks of type "phy/upper/channel_modulation".

            fprintf(fileID, '#include "srsran/%s/%s.h"\n', ...
                obj.srsBlockType, obj.srsBlock);
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFilePHYsigproc(obj, fileID)
        %addTestDefinitionToHeaderFilePHYsigproc(OBJ, FILEID) adds test details (e.g., type
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

        function testID = generateTestID(obj, specialFilename)
        %generateTestID Generates an identifier for the current test.
            filenameTemplateIn = sprintf('%s/%s_test_input*', obj.tmpOutputPath, obj.srsBlock);
            filenameTemplateOut = sprintf('%s/%s_test_output*', obj.tmpOutputPath, obj.srsBlock);
            if nargin == 1
                specialFilename = 'void';
            end
            filenameTemplateSpec = sprintf('%s/%s%s*', obj.tmpOutputPath, obj.srsBlock, specialFilename);
            testID = max([numel(dir(filenameTemplateIn)), numel(dir(filenameTemplateOut)), numel(dir(filenameTemplateSpec))]);
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

        function testCaseString = testCaseToString(obj, testID, testCaseParams, isStruct, varargin)
        %testCaseToString Generates a test entry for the header file.
        %   TESTCASESTRING = TESTCASETOSTRING(OBJ, TESTID, TESTCASEPARAMS, ISSTRUCT) 
        %   generates a data string TESTCASESTRING for test number TESTID.
        %   The data string is generated from the parameters in the cell
        %   array TESTCASEPARAMS. The flag ISSTRUCT instructs the method to
        %   surround the output string with curly brackets (TRUE) or not (FALSE).
        %   TESTCASESTRING = TESTCASETOSTRING(..., FILE1, FILE2, ...) adds
        %   a reference to data files described by FILE1, FILE2 and so on
        %   to the data string. FILE can either be a string with the
        %   filename suffix, or a two-element cell array, where the first 
        %   element is the filename suffix and the second element is a cell
        %   array containing numeric parameters related to the file data
        %   format.
            import srsTest.helpers.cellarray2str;
            configStr = cellarray2str(testCaseParams, isStruct);
            testCaseString = ['  {', configStr];

            nFiles = nargin - 4;
            for iIn = 1:nFiles
                fileInput = varargin{iIn};

                if (iscell(fileInput))
                    suffix = fileInput{1};
                    fileParams = fileInput{2};
                    fileName = ['test_data/' obj.srsBlock suffix num2str(testID) '.dat'];
                    fileString = cellarray2str({['"' fileName '"'], fileParams}, true);
                    testCaseString = [testCaseString ', ', fileString]; %#ok<AGROW>                        
                else
                    suffix = fileInput;
                    fileName = ['test_data/' obj.srsBlock suffix num2str(testID) '.dat'];
                    testCaseString = [testCaseString ', {"', fileName, '"}']; %#ok<AGROW>                                            
                end          
            end
            testCaseString = sprintf('%s},\n', testCaseString);
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
            fprintf(fileID, 'namespace srsran {\n');
            fprintf(fileID, '\n');

            addTestDefinitionToHeaderFile(obj, fileID);

            fprintf(fileID, '\n');
            fprintf(fileID, ...
                'static const std::vector<test_case_t> %s_test_data = {\n', obj.srsBlock);
            fprintf(fileID, '    // clang-format off\n');
        end

        function closeHeaderFile(~, fileID)
        %closeHeaderFile(OBJ, FILEID) Adds the closing content to the
        %   test header file with MATLAB identifier FILEID before closing it.

            % write the closing header file contents
            fprintf(fileID, '    // clang-format on\n');
            fprintf(fileID, '};\n');
            fprintf(fileID, '\n');
            fprintf(fileID, '} // namespace srsran\n');
            fprintf(fileID, '\n');

            fclose(fileID);
        end

        function addOpeningToHeaderFile(obj, fileID)
        %addOpeningToHeaderFile Adds opening guards to a test header file.

            fprintf(fileID, '/*\n');
            fprintf(fileID, ' *\n');
            fprintf(fileID, ' * Copyright 2021-2025 Software Radio Systems Limited\n');
            fprintf(fileID, ' *\n');
            fprintf(fileID, ' * By using this file, you agree to the terms and conditions set\n');
            fprintf(fileID, ' * forth in the LICENSE file which can be found at the top level of\n');
            fprintf(fileID, ' * the distribution.\n');
            fprintf(fileID, ' *\n');
            fprintf(fileID, ' */\n');
            fprintf(fileID, '\n');
            fprintf(fileID, '#pragma once\n');
            fprintf(fileID, '\n');
            fprintf(fileID, '// This file was generated using the following MATLAB class on %s (seed %d):\n', ...
                char(datetime('now', 'Format', 'dd-MM-yyyy')), obj.RngSeed);
            fprintf(fileID, '//   + "%s.m"\n', class(obj));
            fprintf(fileID, '\n');
        end

        function copyTestVectors(obj, outputPath)
        %copyTestVectors(OBJ, OUTPUTPATH) Copies all the binary data files and the decription
        %   header file to the output folder.

            % Get header file list.
            tmp_h = dir([obj.tmpOutputPath, filesep, '*.h']);

            % Get data list.
            tmp_dat = dir([obj.tmpOutputPath, filesep, '*.dat']);

            % If a header is found...
            if ~isempty(tmp_h)
                % Create destination folder
                obj.createOutputFolder(outputPath);

                % If any data file is found...
                if ~isempty(tmp_dat)
                    % Compress test vectors
                    obj.packResults;

                    % Command for copying header file and compressed test vector files
                    cmd = sprintf('cp %s/%s_test_data.{h,tar.gz} %s', obj.tmpOutputPath, ...
                        obj.srsBlock, outputPath);
                else
                    % Command for copying header file only
                    cmd = sprintf('cp %s/%s_test_data.h %s', obj.tmpOutputPath, ...
                        obj.srsBlock, outputPath);
                end

                % Copy files
                system(cmd);

                % apply clang-format to header file
                currentPath = fileparts(mfilename("fullpath"));
                formatCmd = sprintf(['LD_LIBRARY_PATH=/usr/lib clang-format -i', ...
                    ' -style=file:"%s/../+srsMEX/source/.clang-format" %s/%s_test_data.h'], currentPath, outputPath, obj.srsBlock);
                system(formatCmd);
            end % of ~isempty(tmp_h)
        end % of copyTestVectors(obj, outputPath)

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

    methods (Access = protected)
        function initializeClassImpl(obj) %#ok<MANU>
            % By default, do nothing. Each derived class may add its extra
            % initialization steps.
        end
    end % of methods (Access = protected)

    methods (Static, Access = protected)
        function addTestToHeaderFile(fileID, testEntryString)
        %addTestToHeaderFile(OBJ, FILEID, TESTENTRYSTRING) adds the test entry
        %   TESTENTRYSTRING to the test header file with MATLAB identifier FILEID.

            % add a new test case entry to the header file
            fprintf(fileID, '%s', testEntryString);
        end
    end % of methods (Static, Access = protected)
end % of classdef srsBlockUnittest
