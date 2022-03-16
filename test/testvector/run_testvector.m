% RUN_TESTVECTOR:
%   Function generating unittest testvectors to validate the different PHY functions of SRS GNB.
%
%   Call details:
%     RUN_TESTVECTOR(CLASS_NAME) receives the input parameter
%         * string CLASS_NAME - name of the nr_phy_block_unittest class to be utilized

function run_testvector(class_name)
    import matlab.unittest.TestSuite

    % add the simulator folders to the MATLAB path
    addpath('../../src/phy','../unittest','../helpers','../testvector');

    % run the testvector generation tests from the related unit test class
    unittest_filename = ['../unittest/' class_name '.m']
    nr_phy_testvector_tests = TestSuite.fromFile(unittest_filename,'Tag','testvector');
    testResults = nr_phy_testvector_tests.run;
end
