# Phase 3: countdown, call-early bonus, wave banner

Read [roadmap.md](roadmap.md) "Agent briefing" first. Requires phase 2 merged. Manager rechecks this brief vs merged code before start. Covers `docs/ideas.md` "Wave notification" (text only, no icons).

## Goal

The player sees what the next wave is and can call it early for coins. Normal waves show only "Wave N"; special waves add their name + description.

## Design

### `WaveManager`
- `wave_delay: float = 12.0` (placeholder; replaces the `int` export). Countdown starts when all spawning is complete (as today).
- Plan the next wave at countdown start (and the first wave in `setup`/before `start`), keep it, spawn exactly that plan when the wave starts.
- New signals:
  - `wave_planned(plan: WavePlan)`: next plan ready.
  - `countdown_changed(time_left: float)`: on countdown start, then at most ~10×/s while running, and `0.0` when it ends or is skipped.
  - `early_called(coins: int)`.
- `call_next_wave() -> void`: only while the countdown runs (not while spawning, not after the last wave was sent). Pays `floori(time_left × early_bonus_per_second)` via `CurrencyManager.earn`, emits `early_called`, starts the wave. `early_bonus_per_second: float = 0.5` (placeholder).
- `can_call_next_wave() -> bool`.
- Remove unused `wave_done`.
- Countdown must stop while the tree is paused (Timer in tree is fine).

### `Level` facade
Relay `wave_planned`, `countdown_changed`, `early_called`; add `call_next_wave()`. No reaching into `WaveManager` from outside `Level`.

### `Main`
Wire: `Level.wave_planned` -> `HUD.show_wave_plan`; `Level.countdown_changed` -> `HUD.set_countdown`; `HUD.next_wave_requested` -> `Level.call_next_wave`; `Level.early_called` -> coin pop-up (see VFX). On lost / won: hide the button.

### `HUD`
- `%NextWaveButton`: focus-less `Button` (like `%DebugCoinsButton`), touch-sized (min 64×64 viewport px, placeholder), text `Next wave (+<bonus>)` and remaining seconds. Visible only while a countdown runs. Emits `next_wave_requested`.
- Banner (`show_wave_banner`):
  - Normal wave: `Wave N` (as today).
  - Special wave: `Wave N` + per special spawner one line `<display_name>: <description>`.
- Shown when the plan is announced (countdown start, upcoming wave number) and again at wave start (`Wave N` + special line).
- Banner + button work with mouse and touch (GUI consumes presses; no leak to `clicked`/`tapped`).

### VFX (optional)
If `VfxManager` has a coin pop-up usable at a screen/world position w/o a new effect kind: show `+<coins>` on early call. Else skip and report.

## Acceptance

- Clean import + boot.
- Scratch headless scenario w/ injected mouse press and touch press on `%NextWaveButton`: coins += expected bonus, next wave starts, no `clicked`/`tapped` emitted.
- `call_next_wave()` while spawning -> no-op, no coins.
- After the last wave is sent: button hidden, `call_next_wave()` no-op; win still fires once all are cleared.
- Paused tree -> countdown does not advance.
- Planned wave == spawned wave (same plan object or same composition).

Manual (user): check on a phone/touch device; button size, banner legibility.

## Out of scope

Upcoming-waves strip, enemy icons, intro cards, fast-forward, auto-start toggle, balancing.
