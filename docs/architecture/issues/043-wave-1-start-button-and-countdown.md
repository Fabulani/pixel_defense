# Wave 1 starts immediately: add a player-started first wave

- **Type:** feature / design
- **Priority:** medium
- **Area:** waves, UI

## Now

`Main` calls `Level.start()` when the start menu closes, and `Level.start()` calls `WaveManager.start_next_wave()` at once. Wave 1 has no countdown and no warning, so the player has no time to read the map and plan a build.

## Wanted

- A build phase before wave 1: the player builds towers and plans freely.
- A "Start waves" button, so the run begins on the player's signal (not on a timer).
- A countdown before wave 1 once it is pressed (or the button itself could start the usual countdown).

## Where

- `levels/level.gd` `start()`, `core/managers/wave/wave_manager.gd` `start_next_wave()` / `end_current_wave()`.
- `ui/hud/` `%NextWaveButton` could double as the start button (same signal path HUD → Main → `Level.call_next_wave()`), but `call_next_wave()` only works while the countdown runs, so wave 1 needs its own path.

## Questions

- Does calling wave 1 early pay a bonus? (Probably not, or the build phase becomes free coins.)
- Does the first-wave countdown interact with the redesign in issue 044?
