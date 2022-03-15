% RUN_NR_PBCH_SYMBOL_MODULATOR_TESTVECTOR_GENERATION:
%   Function generating unittest testvectors to validate PBCH symbol modulation functions of SRS GNB.

import matlab.unittest.TestSuite

% add the simulator folders to the MATLAB path
addpath('../../src/phy','../unittest','../helpers');

% run the testvector generation tests from the related unit test class
nr_pbch_symbol_modulator_testvector_tests = TestSuite.fromClass(?nr_pbch_symbol_modulator_unittest,'Tag','testvector');
testResults = nr_pbch_symbol_modulator_testvector_tests.run;
