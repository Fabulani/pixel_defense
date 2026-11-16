# Roadmap

Written 2026-11-16, after the "oomf" game-feel pass (PR #24). Each item is its own feature with its own plan, branch and PR. They are done in this order.

## 1. Tower-type harness and build bar (in progress)

Make the code able to hold several tower kinds, but ship only the current single-target tower. More towers are blocked on assets; the author decides later whether to add any.

- `TowerType` resource describes a kind (scene, stats, icon textures). `BuildingManager` holds the list; nothing preloads "the" tower any more.
- Build bar at the bottom centre of the screen: one square button per tower type (white outline, rounded corners, translucent black background, tower base + cannon as icon, gaps between buttons, no shared background).
- Build flow: press a tower button (it stays selected, scaled to 0.9) → tap a valid cell (ghost with base, cannon and range ring) → tap the same cell again to build → repeat. Pressing the button again deselects. The camera still pans and zooms while a type is selected. Without a selected type, tapping the map builds nothing.

## 2. Enemy variety

Plan and design more enemy kinds with different effects. Today there are three (`basic`, `fast`, `heavy`) that differ only in stats. Not designed yet. Open issue #11 (an enemy that breaks through obstacles) belongs here.

## 3. Multiple spawners

Current state (checked 2026-11-16): **not supported.** A second `EnemySpawner` node in the level would be ignored. What assumes a single spawner:

- `Level` has one `enemy_spawner` export; it sets its target, relays its signals and draws one path preview line.
- `Level.would_block_path()` only checks the path from that one spawner, so a tower could wall off a second one.
- `WaveManager` hands each wave to one spawner and starts the next-wave timer on that spawner's `spawning_complete`.
- Each spawner keeps its own alive count and emits `wave_cleared` itself, so the HUD count and the win condition would need one aggregate.
- The spawn-delay speed-up is per spawner.

Enemies themselves are fine: they only need a target position and re-path on `grid_changed`.

## 4. Procedural map generation

Generate levels using only the current tileset. Depends on item 3 if generated maps should have several spawners. Not designed yet.

## Later

- Optimization pass. The Web build lags a bit (reported by the author, 2026-11-16); Android is unmeasured. Notes in `docs/ideas.md`.
- Sound; options to reduce screen shake and flashes.
- Effect tuning and the smaller polish items listed in `docs/handoff-oomf.md`.
- More tower kinds, once there are assets.
