# Map/wave seeds depend on Godot's `hash()` and may change between engine versions

- **Type:** robustness
- **Priority:** low
- **Area:** map generation, waves

The per-attempt map RNG uses `hash([seed, attempt])`, and the wave RNG uses `hash([wave_seed, index])`. `hash()` is an engine implementation detail, so a Godot upgrade could silently change every seed's map and waves. Shared seeds would then stop replaying.

Fix: replace it with a small fixed mixing function (for example splitmix64 or FNV-1a over the ints). Optionally add a golden-digest check (`tools/print_waves` already prints a digest) to CI.
