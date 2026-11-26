# Map generation: check on phone/Web, tune `default_map.tres`

- **Type:** test / tuning
- **Priority:** medium
- **Area:** map generation

Map generation (pangea, roads, lamps, 50x50, camera fit) is verified by headless runs over 500 seeds and has been looked at in game on PC, but not on a phone or on Web.

- Check the look, readability and camera fit on a phone and in a browser.
- All values in `levels/generation/default_map.tres` and the newer `MapGenConfig` exports are placeholders. Tune them, maybe as named presets (small/large island, many lakes).
- `spawner_count_max` (10) is clamped by what fits on the island, which gives about 3.6 spawners per map. Decide the intended count and per-spawner difficulty scaling.
