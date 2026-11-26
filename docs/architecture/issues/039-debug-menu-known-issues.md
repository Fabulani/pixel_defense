# Debug menu known issues

- **Type:** debug tooling
- **Priority:** low
- **Area:** debug

The debug menu is verified by headless runs and code review, not yet looked at by a human:
- layout and overlap with the HUD panel; touch on a device;
- the inner `LineEdit` of a `SpinBox` may take focus and swallow WASD;
- freeze and invulnerable apply to live enemies and later *debug* spawns only, not to wave enemies spawned later;
- turning pause off while `StartMenu` or `GameEndScreen` is shown unpauses the game behind it;
- after the last wave, the win may fire between two releases of an extra wave;
- spawn delay ×0.05 multiplies the stepped delay (0.05 s on wave 1, 0.015 s from wave 8).

(See also 008 and 017.)
