# Refactor bundle A: game API

Before you start, read these sections of [roadmap.md](roadmap.md): "Agent briefing", and "Refactor", which includes the Contract.

Turn the debug-only code in the game scripts into the plain game API defined by the Contract, and remove what moves to `debug/`.

Do not touch:
- `debug/`
- `main/`
- `ui/`
- `.github/`
- `project.godot`
- any docs

Another implementer is rewriting `debug/` against the Contract at the same time. Until both are done, `debug/debug_menu.gd` will call methods that no longer exist, so the parse errors coming from `debug/` are expected. Your own files must parse cleanly.

## Per file

Change only the files listed here.

### `entities/towers/tower.gd`
- Rename `debug_set_level` to `set_level`. Keep its body.
- Rename `set_hold_fire(enabled)` to `set_firing_enabled(enabled)`, which sets `_turret.firing_enabled`.

### `entities/towers/turret/turret_component.gd`
- Replace `hold_fire` with `var firing_enabled: bool = true`. The fire condition becomes `_loaded and firing_enabled and ...`.

### `core/managers/building/building_manager.gd`
- Rename `debug_set_level` to `set_tower_level`, calling `tower.set_level`.
- Delete `set_hold_fire`, `_hold_fire`, and the `set_hold_fire` call in `place_tower`.

### `entities/spawners/enemy_spawner.gd`
- Rename `spawn_extra` to `spawn`. Doc comment: an enemy outside any wave queue, for example a boss's minions.

### `entities/enemies/components/health/health.gd`
- Add `signal changed(hp: float)`, emitted after hp changes in `take_damage` and `heal`.
- Add `set_hp(value: float)`, which sets hp and emits `changed`. It does not emit `depleted`; callers keep the value above 0.

### `entities/enemies/enemy.gd`
- Remove `debug_invulnerable` and `signal health_set`.
- `set_health_ratio` uses `health.set_hp(...)`. Its doc says nothing about debug.
- Add `_damage_factors: Dictionary[StringName, float]` with `set_damage_factor` / `clear_damage_factor`, modelled on the speed factors.
- New `take_damage` order:
  1. Armor reduction.
  2. Multiply by the product of the damage factors.
  3. Flash, `armor_deflected`, and `damaged.emit(final)`.
  4. `health.take_damage(final)`, which does nothing for 0 because `Health` returns early. Check that `Health.take_damage(0)` does not emit `depleted` at full hp.

### `entities/enemies/components/abilities/regeneration.gd`
- Replace the `health_set` connection with `_enemy.health.changed.connect(...)`.
- The handler takes `_hp: float` and keeps today's logic: if the enemy is not dying, hp is below max and the timer is stopped, start the timer.
- Heal ticks emit `changed` while the timer runs, which is harmless.
- The class doc keeps "owner, or the parent when added at runtime".

### `entities/bases/player_base.gd`
- Remove `invulnerable`. Add `_damage_factors` with `set_damage_factor` / `clear_damage_factor`.
- `take_damage(amount)`:
  - Returns if already destroyed.
  - Always emits `damaged(amount)` (the camera shake listens).
  - Then `_health -= roundi(amount * product)`.
  - Destroys at <= 0 as today.
- `_on_body_entered` calls `take_damage(1)` and frees the enemy, with no branch.

### `core/managers/wave/wave_config.gd`
- Rename the param `budget_scale` to `difficulty`. Doc: multiplies the wave budget (1.0 = normal).

### `core/managers/wave/wave_manager.gd`
- Rename `budget_scale` to `difficulty` and `set_budget_scale` to `set_difficulty`.
- Rename `set_countdown_held` to `set_countdown_paused`, and `debug_jump_to_wave` to `skip_to_wave`. Keep the restart-after-the-last-wave logic.
- Delete `debug_spawn_wave`, `_debug_releases`, `_process_debug_releases` and its call in `_process`.
- Replace `_spawn_delay_override` / `set_spawn_delay_override` with:
  - `var spawn_delay_multiplier: float = 1.0`.
  - `set_spawn_delay_multiplier(m)`: clamp to > 0, then keep today's push to the spawners still spawning.
  - `_effective_spawn_delay()` becomes public `get_spawn_delay()`, returning `_current_spawn_delay * spawn_delay_multiplier`.
  - Update every caller.
- Add `get_wave_seed() -> int`.
- Rename `_get_active_spawners_for` to public `get_spawners_open_at(index)`, and update the callers.

### `levels/level.gd`
Delete:
- `set_god_mode`
- `get_max_waves`
- `get_spawner_count`
- `debug_spawn_enemies`, `debug_spawn_enemies_at`
- `debug_spawn_wave`, `debug_jump_to_wave`
- `set_budget_scale`, `set_countdown_held`, `set_spawn_delay_override`
- `_spawn_extra`
- `DEBUG_SEARCH_RADIUS`

Add the getters `get_wave_manager()`, `get_spawners()` (returns `enemy_spawners`) and `get_player_base()`. Rename `_is_walkable` to public `is_cell_walkable` (`##` doc). Keep `get_enemies()`.

After editing, these greps must find nothing:
- `grep -rn "debug_\|hold_fire\|invulnerable\|budget_scale\|spawn_extra\|health_set\|spawn_delay_override" core entities levels`
- `grep -rni "debug" core entities levels`, apart from unrelated existing lines. Report any that remain.

## Verify
- Run `godot --headless --import` twice. The only errors allowed come from `debug/debug_menu.gd`.
- Run `godot --headless res://tools/print_waves.tscn -- --seed=1` and `-- --seed=42`. The digests must be 3007133961 and 761581635.
- Report the files changed and any Contract point that could not be done exactly.
