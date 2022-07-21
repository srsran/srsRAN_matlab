# srsgnb_matlab

## Unit Tests

Call *runSRSGNBUnittest* with the *testvector* tag to generate the set of unit test testvectors of all supported blocks with the command:

```matlab
runSRSGNBUnittest('all', 'testvector')
```

To generate the testvectors for a specific block, for instance *pbch_encoder*, simply run the command:

```matlab
runSRSGNBUnittest('pbch_encoder', 'testvector')
```

All generated files will be automatically placed in an auto-generated folder named *testvector_outputs*.

## MEX
The following steps are needed to compile MEX functions.
1. Export the SRSGNB libraries: clone a local copy of SRSGNB (if not done already) and build CMake with the `-DENABLE_EXPORT=True` option. This creates the file `srsgnb.cmake` in your SRSGNB binary folder (that is, the folder at the top level of CMake build tree).
2. In your local copy of SRSGNB_MATLAB, do the following
```bash
cd sourceMex
mkdir build
cd build
cmake ..
```
If the path to your `srsgnb.cmake` file matches the patterns `~/srsgnb*/{build,build*,cmake-build-*}/srsgnb.cmake` or `~/*/srsgnb*/{build,build*,cmake-build-*}/srsgnb.cmake`, running CMake should find the exported libraries automatically. If this doesn't happen or if you have multiple copies of SRSGNB on your machine, you should specify the path when running CMake, e.g.
```bash
cmake -DSRSGNB_BINARY_DIR="~/new_srsgnb/new_build" ..
```
Similarly, you can use the CMake option `Matlab_ROOT_DIR` if you have multiple versions of MATLAB on your machine and the one selected by default is not the desired one.
3. Simply run `make` to build the MEX executables and `make doxygen` to build the documentation.

## Repository QA
The class *unitTests/CheckTests* implements a series of checks to provide a basic level of quality assurance for the unit tests in the root folder. To run such checks, execute the following commands from the *srsgnb_matlab* root folder.
```matlab
addpath .
runtests("unitTests/CheckTests.m")
```
