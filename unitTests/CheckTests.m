%CheckTests Unit tests for the SRS unit test classes.
%   This class, based on the matlab.unittest.Testcase framework, double checks
%   that the classes implementing SRS unit tests comply with the required
%   specifications. The test only checks that
%
%   1. the class is an implementation of the main abstract test class;
%   2. all mandatory properties and methods are defined;
%   3. an object of the class can be instantiated correctly;
%   4. the test has the 'testvector' tag.
%
%   CheckTests Properties (Constant):
%
%   fullBlocks - List of all possible SRSGNB blocks.
%
%   CheckTests Properties (TestParameters):
%
%   testName  - The test to check.
%
%   CheckTests Methods (TestParameterDefinition, Static):
%
%   obtainTestNames - Initialize the testName parameter.
%
%   CheckTests Methods (TestClassSetup):
%
%   classSetup - Test setup.
%
%   CheckTests Methods (Test):
%
%   runTest - Main test method.
%
%   Example
%      runtests('CheckTests')
%
%   See also matlab.unittest.

classdef CheckTests < matlab.unittest.TestCase
    properties (TestParameter)
        %Test to check. File name of one of the 'srsBlockUnittest' subclasses defining
        %   the tests for an SRSGNB block (e.g., 'srsModulationMapperUnittest.m').
        testName
    end

    properties (Constant)
        %List of all possible SRSGNB blocks. Here, block names include their type
        %   (e.g., 'phy/upper/channel_modulation/modulation_mapper').
        fullBlocks = srsTest.listSRSblocks('full')
    end

    methods (TestParameterDefinition, Static)
        function testName = obtainTestNames()
        %obtainTestNames initializes the testName parameter by selecting the proper files
        %   in the srsgnb_matlab root directory.

            % Get all .m files in root directory.
            tmp = what('..');
            testName = tmp.m;

            % Remove files that are not unit tests.
            nFiles = numel(testName);
            deletedFiles = false(nFiles, 1);
            for iFile = 1:nFiles
                if ~startsWith(testName{iFile}, 'srs') ...
                        || ~endsWith(testName{iFile}, 'Unittest.m')
                    deletedFiles(iFile) = true;
                end
            end
            testName(deletedFiles) = [];
        end
    end

    methods (TestClassSetup)
        function classSetup(obj)
        %classSetup adds the srsgnb_matlab root directory to the MATLAB path.
            import matlab.unittest.fixtures.PathFixture

            obj.applyFixture(PathFixture('..'));
        end
    end

    methods (Test)
        function runTest(obj, testName)
        %runTest carries out the test as described in the class help.

            import matlab.unittest.constraints.IsSubsetOf
            import matlab.unittest.TestSuite

            className = testName(1:end-2);
            classMeta = meta.class.fromName(className);

            % Check whether test is inherited from srsBlockUnittest
            supClasses = {classMeta.SuperclassList(:).Name};
            msg = sprintf('Class %s does not inherit from srsBlockUnittest.', className);
            obj.assertThat({'srsTest.srsBlockUnittest'}, IsSubsetOf(supClasses), msg);

            % Check whether the test is abstract
            msg = sprintf('Class %s is abstract.', className);
            obj.assertFalse(classMeta.Abstract, msg);

            % Check whether test has the mandatory properties
            props = {classMeta.PropertyList(:).Name};
            [blockFlag, blockIdx] = ismember('srsBlock', props);
            [typeFlag, typeIdx] = ismember('srsBlockType', props);
            pathFlag = ismember('outputPath', props);
            msg = sprintf('Class %s misses one or more mandatory properties.', className);
            obj.assertTrue(blockFlag && typeFlag && pathFlag, msg);

            % Check whether test has the mandatory methods
            meths = {classMeta.MethodList(:).Name};
            msg = sprintf('Class %s misses one or more mandatory methods.', className);
            obj.assertThat({'addTestDefinitionToHeaderFile', 'addTestIncludesToHeaderFile'}, ...
                IsSubsetOf(meths), msg);

            % Check whether the block and block type are correct
            blockVal = classMeta.PropertyList(blockIdx).DefaultValue;
            typeVal = classMeta.PropertyList(typeIdx).DefaultValue;
            msg = sprintf('Class %s refers to invalid block ''%s/%s''.',  className, typeVal, blockVal);
            obj.assertThat({[typeVal '/' blockVal]}, IsSubsetOf(obj.fullBlocks), msg);

            % Check whether an object of class testName can be instantiated.
            constructor = str2func(className);
            try
                constructor();
            catch
                msg = sprintf('Cannot instantiate an object of class %s.', className);
                obj.assertFail(msg);
            end

            % Check whether the class generates test vectors.
            tagged = TestSuite.fromClass(classMeta, 'Tag', 'testvector');
            msg = sprintf('Class %s has no tests with tag ''testvector''.',  className);
            obj.assertFalse(isempty(tagged), msg);

        end
    end
end

