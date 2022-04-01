# srsgnb_matlab

## Unit Tests

Call *runSRSGNBUnittest* with the *testvector* tag to generate the set of unit test testvectors of all supported blocks with the command:

```
runSRSGNBUnittest('all', 'testvector')
```

To generate the testvectors for a specific block, for instance *pbch_encoder*, simply run the command:

```
runSRSGNBUnittest('pbch_encoder', 'testvector')
```

All generated files will be automatically placed in an auto-generated folder named *testvector_outputs*.
