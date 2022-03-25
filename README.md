# srsgnb_matlab

## Unit Tests

Call *runTestVector* with the tag *unittests* to generate the set of unit test testvectors of a specific block. The function also expects as inputs the name of the Matlab unit test class and the location of the unit under test within the repository hierarchy. The following blocks are currently supported:

- modulation mapper:

```
runTestVector('unittests','modulation_mapper', 'phy/upper/channel_modulation', 'srsModulationMapperUnittest');
```

- PBCH modulator:

```
runTestVector('unittests','pbch_modulator', 'phy/upper/channel_processors', 'srsPBCHmodulatorUnittest');
```

- PBCH DMRS processor:

```
runTestVector('unittests','dmrs_pbch_processor', 'phy/upper/signal_processors', 'srsPBCHdmrsUnittest');
```

- PDCCH DMRS processor

```
runTestVector('unittests','dmrs_pdcch_processor', 'phy/upper/signal_processors', 'srsPDCCHdmrsUnittest');
```

- PDSCH modulator:

```
runTestVector('unittests','pdsch_modulator', 'phy/upper/channel_processors', 'srsPDSCHmodulatorUnittest');
```
