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

## Repository QA
The class *unitTests/CheckTests* implements a series of checks to provide a basic level of quality assurance for the unit tests in the root folder. To run such checks, execute the following commands from the *srsgnb_matlab* root folder.
```matlab
addpath .
runtests("unitTests/CheckTests.m")
```
