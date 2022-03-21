# srsgnb_matlab

## Unit Tests

Call *runTestVector* with the tag *unittests* to generate the set of unit test testvectors of a specific block. The function also expects as inputs the name of the Matlab unit test class and the location of the unit under test within the repository hierarchy. As an example, find below the call to generate testvectors of the PBCH modulator unit test:

```
runTestvector('unittests','pbch_modulator', 'phy/upper/channel_processors');
```
