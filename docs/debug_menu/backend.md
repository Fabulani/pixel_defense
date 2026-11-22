# Debug menu: backend bundle

Read [roadmap.md](roadmap.md) (Decisions, Contract, Agent briefing) first. Implement the Contract and nothing else: no UI, no scenes, no `main/`, `ui/`, `debug/`, `project.godot`.

## Per file

### `entities/bases/player_base.gd`
- `var invulnerable: bool = false`. In `_on_body_entered`, still `queue_free()` the enemy, but skip `take_damage` while invulnerable.

### `entities/enemies/enemy.gd`
- `debug_invulnerable`: in `take_damage`, everything as today (armor, flash, `armor_deflected`, `damaged`) except `health.take_damage` is skipped.
- `set_health_ratio(ratio)`: sets `health.hp` directly (no signals; `DamageSmoke` polls).

### `entities/enemies/components/{effects/damage_smoke.gd, abilities/regeneration.gd, abilities/dash.gd}`
- `_enemy = owner as Enemy`, and if null `get_parent() as Enemy`. Keep the `push_error` when both are null. Update the `##` class doc ("owner, or parent when added at runtime").
- Check each still works when added after the enemy's `_ready` (e.g. `Dash` vs the spawn tween, `DamageSmoke` emitter attach). Fix only what breaks.

### `entities/spawners/enemy_spawner.gd`
- `func spawn_extra(scene: PackedScene, world_position: Vector2) -> Enemy`: public wrapper of `_create_enemy(scene, world_position, false)`. Counted alive like any spawn.

### `core/managers/wave/wave_config.gd`
- `generate(..., last_templates := [], budget_scale: float = 1.0)`: multiply the wave budget before the split. Default 1.0 must leave `print_waves` digests unchanged.

### `core/managers/wave/wave_manager.gd`
- `var budget_scale: float = 1.0`, passed to `generate` in `_plan_next_wave`. `set_budget_scale(scale)`: store; if `_next_plan != null`, re-plan it and emit `wave_planned`.
- `set_countdown_held(held)`: `wave_timer.paused = held`; `_process` emits no `countdown_changed` while paused.
- `debug_jump_to_wave(index)`: clamp to `0..config.max_waves - 1`, set `wave_index`. If `_next_plan != null` (countdown running or game not started yet), re-plan and emit `wave_planned`. If a wave is spawning, only set the index (the next `end_current_wave` plans from it). Spawners open by `first_wave` as usual.
- `debug_spawn_wave(index)`: generate the plan of `index` (seeded `WaveConfig.make_rng(_wave_seed, index)`, open spawners for that index, no `last_templates`, current `budget_scale`). Release each `SpawnerPlan.enemies` through a **separate debug queue** (one enemy per spawner every `_current_spawn_delay * open_count`, via `spawner.spawn_extra(scene, spawner.global_position)`), driven by `_process` or its own `Timer`. It must not touch `_spawning_count`, `wave_index`, the countdown, `_current_spawn_delay` or `_last_templates`, and must not call `EnemySpawner.start_spawning` (that replaces a running wave queue). Known edge, accept: after the last wave, the win may fire between two debug releases.

### `levels/level.gd`
- Facade methods from the Contract. `set_god_mode` → `player_base.invulnerable`. `get_enemies` → nodes in group `"enemies"` that are `Enemy` and not `is_dying()`.
- `debug_spawn_enemies`: invalid `spawner_index` → `push_warning`, return `[]`. Spawn `count` via `spawn_extra`, each offset a few px (e.g. small ring/jitter from a local rng), return them.
- `debug_spawn_enemies_at`: cell = `PathfindingManager.world_to_cell`; if solid or not walkable, search outward (rings) for the nearest walkable cell (cap radius ~8; none → `push_warning`, `[]`). Owner spawner = nearest by distance. Same offset/return as above.
- `debug_spawn_wave`, `debug_jump_to_wave`, `set_budget_scale`, `set_countdown_held` relay to `wave_manager`.

### `entities/towers/tower.gd`, `entities/towers/turret/turret_component.gd`
- `TurretComponent.hold_fire: bool = false`: aim, lead, idle sweep, reload all as today; only the fire call is skipped (stays `_loaded`). `Tower.set_hold_fire` sets it.

### `core/managers/building/building_manager.gd`
- `debug_set_level(tower, level, major)`: managed towers only (else `push_warning`). Clamp level to `0..TowerStats.MAX_LEVEL`. Below max: `major = null`. At max: `major` or, if null, `tower.major_upgrades[0]`. Set `tower.level` / `tower.major` and rebuild via the tower's existing refresh path (add a small public `Tower` method if needed, e.g. `debug_set_level(level, major)` calling `_apply_upgrades()`; it must also reset appearance when going from a major back down). No currency change, `total_spent` untouched. Emit `tower_upgraded(tower)`.
- `set_hold_fire(enabled)`: store, apply to all managed towers, and apply to each tower placed later.

## Acceptance (headless, scratch scripts in the scratchpad dir, never in the repo)

- `godot --headless --import`, `godot --headless --quit-after 120`: no `SCRIPT ERROR` / `ERROR:` from your files. **Note:** the UI bundle edits `main/main.gd` in parallel and calls this contract; errors there that disappear once your methods exist are expected. Report them, don't touch `main/`.
- `godot --headless res://tools/print_waves.tscn -- --seed=1` and `--seed=42`: digest identical to before your change (record before/after).
- Scenario in the main scene (temp `@tool`/runner scene in scratchpad or a temp in-repo scene deleted after): spawn each enemy type at spawner 0 and at the base area; `set_health_ratio(0.25)` on heavy → its smoke emitter `emitting`; `basic.add_child(Regeneration.new())` after damage → hp rises; `Dash.new()` on basic → speed factor applied periodically; freeze via `set_speed_factor(&"debug", 0.0)` → position constant; god mode → enemy reaching base, no `lost`; `debug_spawn_wave(9)` → alive count rises, `wave_index` unchanged, countdown unaffected; `debug_jump_to_wave(9)` before start → `wave_planned` plan index 9, `is_special()`; `set_budget_scale(2.0)` → re-planned budget doubles; `set_countdown_held(true)` → `time_left` constant over 1 s; `debug_set_level` 0→5→2 → appearance/stats follow, `total_spent` unchanged; hold fire → no `shot` with an enemy in range.

Report in the implementer.md format with command output.
