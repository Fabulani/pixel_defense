# `Level.waves_survived` counts waves started, not survived

- **Type:** bug (naming / UI)
- **Priority:** low
- **Area:** waves, UI

`Level.waves_survived` returns `wave_manager.wave_index`, which is the number of waves *started*. The end screen therefore says you survived the wave you died in. Either rename it (`waves_reached`) or compute the number of waves fully cleared.
