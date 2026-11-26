# `start_next_wave()` stops the countdown before its "still spawning" early return

- **Type:** bug (latent)
- **Priority:** low
- **Area:** waves

## Description
`WaveManager.start_next_wave()` (core/managers/wave/wave_manager.gd:84-88) calls `wave_timer.stop()` first and only then returns if a wave is still spawning. If anyone calls it while spawning *and* a countdown is running, the countdown dies and no next wave is ever started.

Today every caller is safe: `Level.start()` runs once, `call_next_wave()` is guarded by `can_call_next_wave()`, and the timer's timeout can't fire while spawning. A future caller (for example a debug tool) could hit it.

## Fix
Move `wave_timer.stop()` below the two early returns.

## Done when
Calling `start_next_wave()` during spawning leaves the countdown state untouched.
