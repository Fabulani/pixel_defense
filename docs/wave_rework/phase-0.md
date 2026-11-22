# Phase 0: remove legacy map option

Read [roadmap.md](roadmap.md) "Agent briefing" first.

## Goal

Every run plays a generated map. The hand-made map can no longer be selected; its tilemap stays in `levels/level.tscn` as data for future unique maps. `map_seed` is always >= 1.

## Files

- `core/game_data.gd`: remove `legacy_map` and the `--legacy-map` arg branch. Fix doc comments (`map_seed` never 0 once a level loaded).
- `levels/level.gd`: remove `use_generated_map` export; `_ready()` always calls `_generate_map()`. Fix doc comments mentioning legacy (`map_seed`, `_pick_seed`).
- `levels/level.tscn`: only if it stores `use_generated_map = ...` -> remove that line (small hand edit). Keep painted tiles, `EnemySpawner`, `EnemySpawner2`.
- `ui/game_end/game_end_screen.gd`: `%SeedLabel` always visible.
- Grep whole repo (`*.gd`, `*.tscn`, `*.tres`) for `legacy_map`, `use_generated_map`, `legacy-map` -> none left outside `docs/`, `CLAUDE.md`, `README.md` (manager edits those).

## Acceptance

- `godot --headless --import` + `godot --headless --quit-after 120`: no `SCRIPT ERROR` / `ERROR:`; log shows `Map seed: N`.
- `godot --headless --quit-after 120 -- --seed=12345` twice -> `Map seed: 12345` both runs.
- `-- --legacy-map` -> still a generated map, no error (unknown args are ignored).

## Out of scope

Unique maps, map selection UI, removing the painted tilemap or the scene's spawners.
