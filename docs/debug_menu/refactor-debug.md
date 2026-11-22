# Refactor bundle B: debug side

Before you start, read these sections of [roadmap.md](roadmap.md): "Agent briefing", and "Refactor", which includes the Contract and the debug-side rules.

Split `debug/debug_menu.gd` (588 lines) into a shell and sections, and move the debug-only orchestration out of game code into `debug/`. Code only against the Contract.

Another implementer is changing the game scripts to match the Contract at the same time. Do not read or edit those scripts, and do not edit any game file.

Files you may touch:
- `debug/**`
- `main/main.gd` (the debug block only)
- `.github/workflows/build.yml` (the Export step only)

Until the other bundle is done, the parse errors caused by the old API in the game scripts are expected. Your own files must be correct against the Contract.

## Structure

None of these files has a `class_name`; they reference each other with `const X = preload("res://debug/...")`. Every typed `var` uses those consts or game classes.

- **`debug/debug_menu.gd`** (extends `CanvasLayer`): the shell.
  - Today's drawer, DBG tab, F12 (`debug>toggle`), slide tween, layer 100, `PROCESS_MODE_ALWAYS`, and the scroll column.
  - `setup(level: Level, building_manager: BuildingManager, tower_menu: TowerMenu, vfx: VfxManager, camera: PanningCamera)` stores a context. `Main` calls it after `add_child`, so build the UI in `setup` or after `_ready`, whichever is called last.
  - Builds one instance of each section in order: Game, Waves, Enemies, Towers, Time, VFX.
  - Forwards refresh calls: the 200 ms poll while open, on open, and on `tower_upgraded`.
- **`debug/debug_context.gd`** (`RefCounted`): holds `level`, `building_manager`, `tower_menu`, `vfx`, `camera`.
- **`debug/debug_ui.gd`**: static helpers moved from today's `_add_button`, `_add_toggle`, `_add_flow`, `_add_spin` and `_add_option`. Keep the same look: focus-less controls and the font size.
- **`debug/debug_state.gd`**: all the `static var`s that keep toggles across F1 and restart. Section state such as `open_sections` also lives here.
- **`debug/sections/debug_section.gd`** (extends `VBoxContainer`): the collapsible header (today's `_add_section` behaviour), a `content` box, a virtual `build(ctx)`, `refresh()` (default no-op) and `apply_state()` (default no-op, re-applies the saved toggles after a reload).
- **`debug/sections/{game,waves,enemies,towers,time,vfx}_section.gd`**: today's buttons and handlers, moved. The behaviour is unchanged except for the mapping below.
- **`debug/extra_wave_spawner.gd`** (Node, child of the menu, `PROCESS_MODE_INHERIT` so it pauses with the game): the release queue that used to be in `WaveManager`.
  - `spawn_wave(index)` plans with `wm.config.generate(i, WaveConfig.make_rng(wm.get_wave_seed(), i), open.size(), [], wm.difficulty)`, where `open = wm.get_spawners_open_at(i)`.
  - It releases one enemy per spawner every `wm.get_spawn_delay() * open.size()`. The first one comes after `get_spawn_delay() * (k + 1)`.
  - It uses `spawner.spawn(scene, spawner.global_position)`, and drops a queue whose spawner is freed.
  - The old code is in `git show HEAD:core/managers/wave/wave_manager.gd`: `debug_spawn_wave` and `_process_debug_releases`.

## Old call → new call

| Old | New |
|---|---|
| `level.set_god_mode(on)` | `level.get_player_base().set_damage_factor(&"debug", 0.0)`, or `clear_damage_factor(&"debug")`. Guard against a freed base with `is_instance_valid` |
| `level.get_max_waves()` | `level.get_wave_manager().config.max_waves` |
| `level.get_spawner_count()` | `level.get_spawners().size()` |
| `level.debug_spawn_wave(i)` | `extra_wave_spawner.spawn_wave(i)` |
| `level.debug_jump_to_wave(i)` | `level.get_wave_manager().skip_to_wave(i)` |
| `level.set_budget_scale(x)` | `wave_manager.set_difficulty(x)`. The button text stays "Budget x…" |
| `level.set_countdown_held(b)` | `wave_manager.set_countdown_paused(b)` |
| Fast spawn, `set_spawn_delay_override(0.05 / 0)` | Toggle "Spawn delay x0.05": `wave_manager.set_spawn_delay_multiplier(0.05 if on else 1.0)` |
| `level.debug_spawn_enemies(scene, n, i)` | `level.get_spawners()[i].spawn(scene, pos + jitter)` for n enemies. Jitter: up to 4 px, none on the first enemy; old code in `git show HEAD:levels/level.gd` `_spawn_extra` |
| `level.debug_spawn_enemies_at(scene, n, pos)` | Nearest walkable cell (ring search, radius 8, with `level.is_cell_walkable` and `PathfindingManager.world_to_cell`), owned by the nearest spawner. Move the search from `git show HEAD:levels/level.gd` into the enemies section |
| `enemy.debug_invulnerable = b` | `enemy.set_damage_factor(&"debug", 0.0)`, or `clear_damage_factor(&"debug")` |
| `building_manager.debug_set_level(...)` | `building_manager.set_tower_level(...)` |
| `building_manager.set_hold_fire(b)` | For every node in group `"towers"` that is a `Tower`: `set_firing_enabled(not b)`. The towers section also connects `building_manager.tower_built` and applies the flag to new towers |
| `enemy.set_health_ratio`, `level.get_enemies`, attach components, VFX, time, step | Unchanged API |

Freeze stays `set_speed_factor(&"debug", 0.0)`. The freeze and invulnerable flags still apply to live enemies and to enemies spawned by debug, not to wave spawns.

## `main/main.gd`
Replace the `DebugMenu.new()` block with:
- `var menu: Node = (load("res://debug/debug_menu.gd") as GDScript).new()`
- `add_child(menu)`
- `menu.call("setup", current_level, building_manager, tower_menu, vfx, camera)`, or a direct call if it stays warning-free.

No other line in `main.gd` changes.

## `.github/workflows/build.yml`
In the Export step, before exporting and only when `REQUIRE_SIGNING` is `true`, run `sed -i 's|^exclude_filter="tools/\*"$|exclude_filter="tools/*,debug/*"|' export_presets.cfg`. Then fail if `grep -c 'debug/\*' export_presets.cfg` is not 4. Pass values only through `env:` and never put `${{ }}` inside `run:`.

## Verify
- Run `godot --headless --import` twice. The only errors allowed come from game scripts that still use the old API.
- `grep -rn "class_name" debug/` must be empty.
- `grep -rn "DebugMenu\|debug/" --include=*.gd . | grep -v "^./debug/"` must show only the `load()` line in `main.gd`.
- Report the files created and any Contract point you could not use as written.
