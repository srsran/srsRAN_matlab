# srsRAN-matlab

*srsRAN-matlab*, developed by [SRS](https://www.srs.io), provides a number of MATLAB-based tools for testing and benchmarking the [srsRAN Project](https://www.srsran.com) software.

## Overview

The project includes utilities for generating the test vectors used for testing in the srsRAN Project, MEX wrappers of a number of srsRAN PHY components, end-to-end simulators, and analysis tools for the baseband captures obtained with the srsRAN gNB (see [`phy_rx_symbols_filename`](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html#log) for how to obtain them).

For a better user experience, we suggest adding the root directory of *srsRAN-matlab* to the MATLAB search path
```matlab
addpath path/to/srsran_matlab
```

### License

For license details, see the [LICENSE](LICENSE) file.

### Requirements

*srsRAN-matlab* runs on MATLAB and builds upon the [5G Toolbox](https://www.mathworks.com/products/5g.html) (tested on MATLAB R2023b, R2024a and R2024b under Linux, but other recent releases should also work).

The srsRAN Project is required to build the MEX wrappers and to run the applications that include them (see the [MEX](#mex) section for further details).

### Compatibility Table

The development of *srsRAN-matlab* closely follows all new features of the srsRAN Project. For this reason, it is important that you always use the latest version of both software: this is the only way to ensure that test vectors agree with the srsRAN API and that MEX binaries compile. The [compatibility table](CompatibilityTable.md) provides a list of reference commits on both repositories that are guaranteed to work together.

### Contents

The repository is organized as follows.

* **Root directory:** MATLAB classes for testing the srsRAN Project, see the [Vector Tests](#vector-tests) section. This directory also contains the [LICENSE](LICENSE), [COPYRIGHT](COPYRIGHT) and [README](README.md) files.
* [`+srsLib`](+srsLib): MATLAB implementation of several NR blocks and functionalities, mostly wrappers around MathWorks 5G Toolbox classes and functions. The internal structure of this directory follows the organization of the [lib](https://github.com/srsran/srsRAN_Project/tree/main/lib) directory in the srsRAN Project. The content of this directory is intended for expert users only. Using functions and classes from this directory is discouraged.
* [`+srsMEX`](+srsMEX): MEX version of a number of srsRAN blocks. The corresponding C++ source files are located in `+srsMEX/source`. See the [MEX](#mex) section for more details.
* [`+srsTest`](+srsTest): Testing framework and utilities. The content of this directory is intended for expert users only. Using functions and classes from this directory is discouraged.
* [`apps`](apps): End user applications, including simulators and analyzers. See the [Apps](#apps) section for more details.
* [`unitTests`](unitTests): Repository CI/CD tools. The content of this directory is intended for expert users only.

### Help

Please read this file for a general overview of the project and its features.

All classes and functions are documented and extensive information can be obtained by typing `help ClassName` at the MATLAB Command Window.

For support requests and community announcements, please use the srsRAN Project [Discussion Board](https://www.github.com/srsran/srsran_project/discussions) with the category "srsRAN-matlab".

## Test Vectors

The classes in the root folder can be used to generate test vectors (a header file and, typically, a tarball file containing the vectors) for the srsRAN Project (see the last paragraph of the [Build Instructions](https://github.com/srsran/srsRAN_Project#build-instructions)).

Call `runSRSRANUnittest` with the `testvector` tag to generate the set of test vectors of all supported blocks with the command:

```matlab
runSRSRANUnittest('all', 'testvector')
```

To generate the test vectors for a specific block, for instance *pbch_encoder*, simply run the command:

```matlab
runSRSRANUnittest('pbch_encoder', 'testvector')
```

All generated files will be automatically placed in a directory named *testvector_outputs*. They can be copied to the proper subfolders inside the srsRAN Project folder with
```matlab
srsTest.copySRStestvectors('testvector_outputs', 'path/to/srsRAN_Project')
```

### Customizing Tests

The classes in the root directory define the tests following the [MATLAB class-based testing framework](https://www.mathworks.com/help/matlab/class-based-unit-tests.html). As a result, all the tools from the framework can be used to run and customize the tests. For instance, the following code will run the `pdcch_candidates_common` tests only for a subset of values of the `numCCEs` parameter.
```matlab
% Select the block to test.
testedBlock = ?srsPDCCHCandidatesCommonUnittest;
% Test only for numCCEs = {24, 72}. By default, the test uses {24, 48, 72, 96, 120, 144}.
extParams = matlab.unittest.parameters.Parameter.fromData('numCCEs', {24, 72});
% Create a test suite.
vecTest = matlab.unittest.TestSuite.fromClass(testedBlock, 'ExternalParameters', extParams);
% Run the tests.
results = vecTest.run;
```

## MEX

The directory `+srsMEX` contains MEX versions of a number of classes and functions from the srsRAN Project. Typically, MEX can be accessed as class methods for a better user experience: for instance, the class `srsMEX.phy.srsPUSCHDecoder` provides access to the MEX version of the srsRAN `pusch_decoder`.

### Building the MEX

The following steps are needed to compile MEX binaries.
1. **Export the srsRAN libraries:** clone a local copy of the [srsRAN Project](https://github.com/srsran/srsRAN_Project) (if not done already) and generate the CMake project with the `-DENABLE_EXPORT=True` option. This creates the file `srsran.cmake` in your srsRAN binary folder (that is, the folder at the top level of CMake build tree).
2. **Build the srsRAN Project:** Follow the instructions in the srsRAN Project repository. You can use the target `srsran_exported_libs` to compile only the libraries needed by *srsRAN-matlab* and reduce compilation time.
3. **Generate the CMake project:** In your local copy of *srsRAN-matlab*, do the following to generate a build system in the directory `builddir`:
    ```bash
    cd +srsMEX/source
    cmake -B builddir
    ```
    If the path to your `srsran.cmake` file matches the patterns `~/srsRAN_Project/{build,build*,cmake-build-*}/srsran.cmake`, `~/*/srsRAN_Project/{build,build*,cmake-build-*}/srsran.cmake` or `~/*/*/srsRAN_Project/{build,build*,cmake-build-*}/srsran.cmake`, running CMake should find the exported libraries automatically. If this doesn't happen or if you have multiple copies of srsRAN on your machine, you should specify the path when running CMake.
    ```bash
    cmake -B builddir -DSRSRAN_BINARY_DIR="~/new_srsran/new_build"
    ```
    Similarly, you can use the CMake option `Matlab_ROOT_DIR` if you have multiple versions of MATLAB on your machine or if MATLAB is not in your system path.
    ```bash
    cmake -B builddir -DMatlab_ROOT_DIR="/usr/local/MATLAB/R2024b"
    ```
4. **Build the MEX:** Once the CMake project has been generated, the MEX binaries can be built with
   ```bash
   cmake --build builddir
   ```
   Finally, to be able to access the MEX binaries from the `srsMEX` library, you need to install them with
   ```bash
   cmake --install builddir
   ```

    To build extra MEX-related documentation, which can be accessed from `+srsMEX/source/build/docs/html/index.html`, run
    ```bash
    cmake --build builddir --target doxygen
    ```

    Depending on your setup, you may need to instruct MATLAB to use the system libraries instead of the internal ones: do the following and (re)start MATLAB.
    ```bash
    cd /usr/local/MATLAB/R2024b/sys/os/glnxa64
    sudo mv libstdc++.so.6 libstdc++.so.6.bak
    ```
> The examples in this section assume you have MATLAB R2024b installed in the typical path `/usr/local/MATLAB/R2024b/`. For other MATLAB releases or paths, adapt the examples accordingly.

### Testing the MEX

Call `runSRSRANUnittest` with the `testmex` tag to test the MEX. This command runs the same code as with the `testvector` tag but sends the generated vectors directly to the MEX instead of writing them on file.
```matlab
runSRSRANUnittest('all', 'testmex')
```

## Apps
The folder `apps` contains a number of applications and examples that use tools of the *srsRAN-matlab* project. Before running them, remember to add the main *srsRAN-matlab* folder to the MATLAB search path.

### apps/simulators/PUSCHBLER
An instance of the *PUSCHBLER* class provides a simulator object for PUSCH BLER and throughput evaluation. The following example shows how to evaluate BLER and throughput at `SNR = -6:0.2:-4` dB for the default configuration. For more information, enter `help PUSCHBLER` at the MATLAB command line.
```matlab
sim = PUSCHBLER       % Create a PUSCHBLER object.
sim(-6:0.2:-4)        % Run the simulation.
sim.ThroughputMATLAB  % Display the evaluated throughput.
sim.plot              % Plot the evaluated throughput and BLER vs SNR.
save my_sim.mat sim   % Save the PUSCHBLER object, including the simulation results,
                      % to file my_sim.mat.
```
Function `combinePUSCHSims` can be used to obtain a summary of several simulation results in graphic and table formats. For instance, the following command will draw the BLER and throughput curves from the PUSCHBLER objects saved in files `my_sim1.mat` and `my_sim2.mat`, as well as creating two tables, namely `tableS` and `tableM`, with the main simulation results using the SRS and MATLAB PUSCH decoder, respectively.
```matlab
[tableS, tableM] = combinePUSCHSims(["my_sim1.mat", "my_sim2.mat"])
```
See `help combinePUSCHSims` for more details.

### apps/simulators/PUCCHPERF
An instance of the *PUCCHPERF* class provides a simulator object for the evaluation of the performance (in terms of BLER, detection and false detection probability, depending on the case) of the PUCCH processors, for PUCCH Formats 0, 1 and 2. The following example shows how to evaluate the PUCCH Format 2 BLER at `SNR = -10:0` dB for the default configuration. For more information, enter `help PUCCHPERF` at the MATLAB command line.
```matlab
sim = PUCCHPERF           % Create a PUCCHPERF object.
sim(-10:10)               % Run the simulation.
sim.BlockErrorRateMATLAB  % Display the evaluated BLER.
sim.plot                  % Plot the evaluated BLER.
save my_sim.mat sim       % Save the PUCCHPERF object, including the simulation results,
                          % to file my_sim.mat.
```

### apps/simulators/PRACHPERF
An instance of the *PRACHPERF* class provides a simulator object for the evaluation of the PRACH probability of detection and of false alarm. The following example show how to evaluate the probability of PRACH detection at `SNR = -6:0.2:-4` dB for the default configuration. For more information, enter `help PRACHPERF` at the MATLAB command line.
```matlab
sim = PRACHPERF           % Create a PRACHPERF object.
sim(-26:0.5:-20)          % Run the simulation.
sim.ProbabilityDetection  % Display the evaluated detection probability.
sim.plot                  % Plot the evaluated detection probability.
save my_sim.mat sim       % Save the PRACHPERF object, including the simulation results,
                          % to file my_sim.mat.
```
### apps/analyzers/srsParseLogs

This app parses a section of the logs generated by the srsRAN gNB and returns carrier and channel (PUSCH, PUCCH or PRACH) configuration objects to be fed to one of the analyzers below (*srsPUSCHAnalyzer*, *srsPUCCHAnalyzer* or *srsPRACHAnalyzer*). See the [Configuration Parameters Section](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html#configuration-parameters) of the srsRAN Project documentation for information on how to configure the logging level of the SRS gNB to record the received samples.

See `help srsParseLogs` for more details.

### apps/analyzers/srsPUSCHAnalyzer

This app analyzes a PUSCH transmission from the baseband complex-valued samples corresponding to one slot, as received by the gNB. See the [Configuration Parameters Section](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html#configuration-parameters) of the srsRAN Project documentation for information on how to configure the logging level of the SRS gNB to record the received samples.

See `help srsPUSCHAnalyzer` for more details.

### apps/analyzers/srsPUCCHAnalyzer

This app analyzes a PUCCH (all formats) transmission from the baseband complex-valued samples corresponding to one slot, as received by the gNB. See the [Configuration Parameters Section](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html#configuration-parameters) of the srsRAN Project documentation for information on how to configure the logging level of the SRS gNB to record the received samples.

See `help srsPUCCHAnalyzer` for more details.

### apps/analyzers/srsPRACHAnalyzer

This app analyzes a PRACH transmission from the baseband complex-valued samples corresponding to one PRACH occasion, as received by the gNB. See the [Configuration Parameters Section](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html#configuration-parameters) of the srsRAN Project documentation for information on how to configure the logging level of the SRS gNB to record the received samples.

See `help srsPRACHAnalyzer` for more details.

### apps/analyzers/srsResourceGridAnalyzer

This app displays the content of a resource grid (all subcarriers and one slot) as a heat map of the resource element amplitudes. See the [Configuration Parameters Section](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html#configuration-parameters) of the srsRAN Project documentation for information on how to configure the logging level of the SRS gNB to record the received samples.

See `help srsResourceGridAnalyzer` for more details.

## Repository CI/CD
### CheckTests.m
The class *unitTests/CheckTests* implements a series of checks to provide a basic level of quality assurance for the unit tests in the root folder.

These checks have been designed mainly for automatic CI/CD procedures. Nevertheless, they can be executed locally by running the following commands from the *srsRAN-matlab* root folder.
```matlab
addpath .
runtests("unitTests/CheckTests.m")
```

### CheckSimulators.m
The class *unitTests/CheckSimulators* carries out short runs of the simulators in the [Apps folder](#apps) to ensure their functioning.

These checks have been designed mainly for automatic CI/CD procedures. Nevertheless, they can be executed locally by running the following commands from the *srsRAN-matlab* root folder.
```matlab
addpath .
runtests("unitTests/CheckSimulators.m")
```

### CheckAnalyzers.m
The class *unitTests/CheckAnalyzers* carries out a demo run of the analyzers in the [Apps folder](#apps) to ensure their functioning.

These checks have been designed mainly for automatic CI/CD procedures. Nevertheless, they can be executed locally by running the following commands from the *srsRAN-matlab* root folder.
```matlab
addpath .
runtests("unitTests/CheckAnalyzers.m")
```

### Conformance Tests
The classes *CheckPUSCHConformance*, *CheckPUCCHF0Conformance*, *CheckPUCCHF1Conformance*, *CheckPUCCHF2Conformace* and *CheckPRACHConformace* run a set of conformance tests (as defined in *TS38.104* and *TS38.141*) of the corresponding PHY channel receivers.

These checks have been designed mainly for automatic CI/CD procedures. Nevertheless, they can be executed locally by running the following commands from the *srsRAN-matlab* root folder (be aware that these tests may run for several hours).
```matlab
addpath .
runtests("unitTests/CheckPUSCHConformance.m")
runtests("unitTests/CheckPUCCHF0Conformance.m")
runtests("unitTests/CheckPUCCHF1Conformance.m")
runtests("unitTests/CheckPUCCHF2Conformance.m")
runtests("unitTests/CheckPRACHConformance.m")
```
