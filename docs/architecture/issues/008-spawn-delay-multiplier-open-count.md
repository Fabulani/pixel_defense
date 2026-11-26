# `set_spawn_delay_multiplier()` uses the next wave's open-spawner count

- **Type:** bug (debug tooling)
- **Priority:** low
- **Area:** waves, debug

## Description
`WaveManager.set_spawn_delay_multiplier()` (wave_manager.gd:~181) recomputes the per-spawner delay with the open-spawner count of `wave_index`. That index has already been incremented for the running wave, so if a spawner opens on the next wave, the running spawners get a delay computed for the wrong count. Only the debug menu's "spawn delay ×0.05" calls this.

## Fix
Store the open count (or the per-spawner delay) when the wave starts, and reuse it.
