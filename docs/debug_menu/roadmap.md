# Debug menu

Planned 2026-11-22. Replaces the "debug scene" idea (`docs/ideas.md`). Unblocks wave rework phase 4 (bosses).

## Why

Tuning enemies, towers and effects (smoke on a big enemy, regenerator pluses, majors, late-wave load) needs set-up situations, not full runs.

## Decisions

- No separate scene or map: an **overlay menu in the normal game**, **debug builds only** (`OS.is_debug_build()`).
- Toggle: **F12** (action `debug>toggle`; F8 stops the game when run from the editor) in start menu and game, or the `DBG` tab (touch). Collapsible sidebar: the tab sits on the sidebar's left edge; closed, only the tab shows at the right screen edge, pressing it slides the sidebar in, pressing again slides it out.
- Right-side column of collapsible sections: Game, Waves, Enemies, Towers, Time, VFX.
- Value tuning = Godot editor remote inspector. No in-game sliders, no `.tres` saving.
- UI built in code (`debug/debug_menu.gd`, `class_name DebugMenu extends CanvasLayer`), no `.tscn` (dynamic lists, no uid issues).
- `Main` creates it only in debug builds and injects references. It calls only the public API in [Contract](#contract).
- Menu toggles survive F1 / restart via `static var`s in `DebugMenu`.

## Work split

Two bundles, run **in parallel** by two fresh implementers. They touch disjoint files. [Contract](#contract) is the boundary.

| Bundle | Brief | Files |
|---|---|---|
| Backend | [backend.md](backend.md) | `levels/level.gd`, `core/managers/wave/wave_manager.gd`, `core/managers/wave/wave_config.gd`, `entities/spawners/enemy_spawner.gd`, `entities/enemies/enemy.gd`, `entities/bases/player_base.gd`, `entities/towers/tower.gd`, `entities/towers/turret/turret_component.gd`, `core/managers/building/building_manager.gd`, `entities/enemies/components/{effects/damage_smoke.gd,abilities/regeneration.gd,abilities/dash.gd}` |
| UI | [ui.md](ui.md) | `debug/debug_menu.gd` (new), `main/main.gd`, `ui/hud/hud.gd`, `ui/hud/hud.tscn`, `project.godot` |

Then one sonnet reviewer (code only) over `git diff origin/main` against both briefs.

## Contract

Backend implements exactly these, UI calls only these (plus the existing public API listed in ui.md). Defaults change nothing in a normal run. `##` doc comment on each.

```gdscript
# Level (facade)
func set_god_mode(enabled: bool) -> void                      ## base takes no damage (enemies reaching it are still freed)
func get_max_waves() -> int                                   ## WaveConfig.max_waves
func get_spawner_count() -> int                               ## all spawners, open or not
func get_enemies() -> Array[Enemy]                            ## live enemies (group "enemies", not dying)
func debug_spawn_enemies(scene: PackedScene, count: int, spawner_index: int) -> Array[Enemy]   ## at that spawner
func debug_spawn_enemies_at(scene: PackedScene, count: int, world_position: Vector2) -> Array[Enemy]  ## at nearest walkable cell
func debug_spawn_wave(index: int) -> void                     ## spawn plan of wave index (0-based) as an extra
func debug_jump_to_wave(index: int) -> void                   ## next wave started/planned is index (0-based)
func set_budget_scale(scale: float) -> void                   ## multiplies wave budgets planned from now on
func set_countdown_held(held: bool) -> void                   ## pause/resume the next-wave countdown

# Enemy
var debug_invulnerable: bool = false                          ## take_damage flashes/emits but health is untouched
func set_health_ratio(ratio: float) -> void                   ## hp = clamp(ratio, 0.01, 1) * max_health; no-op while dying

# Tower
func set_hold_fire(enabled: bool) -> void                     ## turret aims and sweeps but never fires

# BuildingManager
func debug_set_level(tower: Tower, level: int, major: MajorUpgrade) -> void  ## free; emits tower_upgraded
func set_hold_fire(enabled: bool) -> void                     ## all managed towers + towers built later

# Effect components (DamageSmoke, Regeneration, Dash)
# Enemy resolved as `owner as Enemy`, else `get_parent() as Enemy`, so `enemy.add_child(DamageSmoke.new())` works at runtime.
```

## Agent briefing (every brief links this)

Same as `docs/wave_rework/roadmap.md` "Agent briefing" (read it). Additionally:
- Keep context low: read only the files your brief names, plus whatever they directly call. Do not explore the repo.
- Contract names and signatures are fixed. If one cannot work, stop and report instead of renaming.
- Both bundles work in the same checkout at the same time. Never touch a file outside your bundle's list. Never run `git checkout`/`restore`/`stash`.

## Status

| Bundle | Status |
|---|---|
| Backend | done (review fixed) |
| UI | done (review fixed) |
| Playtest | open |
| Refactor: game | done (review fixed) |
| Refactor: debug | done (review fixed) |

## Refactor: separate debug code from game code

The first version put debug-only code into game scripts: `debug_*` methods, cheat flags, a release queue in `WaveManager`, and eight relays on `Level`. The refactor makes the dependency one-way: `debug/` uses game code, and game code never names `debug/`.
- Capabilities become plain game API.
- Cheat flags become general modifiers.
- Debug-only orchestration moves into `debug/`.

There are two bundles, run in parallel, on disjoint files:
- [refactor-game.md](refactor-game.md): game scripts.
- [refactor-debug.md](refactor-debug.md): `debug/`, `main/main.gd`, CI.

### Contract (game API after the refactor)

Doc comments must not say "debug". Defaults change nothing.

| Class | API |
|---|---|
| `Tower` | `set_level(new_level: int, new_major: MajorUpgrade) -> void`: no currency, no `upgraded` signal; resets a major's look when the major is dropped. `set_firing_enabled(enabled: bool) -> void` |
| `TurretComponent` | `var firing_enabled: bool = true`: aims, leads, sweeps and reloads as usual; fires only while true. `reset_appearance()` stays |
| `BuildingManager` | `set_tower_level(tower: Tower, level: int, major: MajorUpgrade) -> void`: free, managed towers only, clamped; at max level uses `major` or, if null, the tower's first major; emits `tower_upgraded`; `total_spent` untouched |
| `EnemySpawner` | `spawn(scene: PackedScene, world_position: Vector2) -> Enemy`: outside any wave queue, counted alive; null if not an `Enemy` |
| `Health` | The built-in `Resource.changed` signal (no parameter; `Health` calls `emit_changed()`), emitted by `take_damage`, `heal` and `set_hp(value: float) -> void` |
| `Enemy` | `set_health_ratio(ratio: float) -> void` (via `health.set_hp`; clamped 0.01..1; not while dying). `set_damage_factor(source: StringName, factor: float)` / `clear_damage_factor(source: StringName)`. `take_damage`: armor, then × the product of factors, then flash, deflect and `damaged.emit(final)` (final may be 0), then `health.take_damage(final)` |
| `PlayerBase` | `set_damage_factor(source, factor)` / `clear_damage_factor(source)`. `take_damage(amount: int)` always emits `damaged(amount)`, then subtracts `roundi(amount × product)` |
| `WaveConfig` | `generate(index, rng, open_spawners, last_templates := [], difficulty: float = 1.0)`: multiplies the wave budget |
| `WaveManager` | `var difficulty: float = 1.0` and `set_difficulty(value: float)`, which re-plans a stored plan and emits `wave_planned`. `set_countdown_paused(paused: bool)`. `skip_to_wave(index: int)` (clamped; restarts the flow after the last wave). `var spawn_delay_multiplier: float = 1.0` and `set_spawn_delay_multiplier(m: float)`, which also updates spawners still spawning. `get_spawn_delay() -> float` (stepped delay × multiplier). `get_wave_seed() -> int`. `get_spawners_open_at(index: int) -> Array[EnemySpawner]` |
| `Level` | `get_wave_manager() -> WaveManager`, `get_spawners() -> Array[EnemySpawner]`, `get_player_base() -> PlayerBase`, `is_cell_walkable(cell: Vector2i) -> bool`, `get_enemies() -> Array[Enemy]`. No debug relays |

### Debug-side rules

- Scripts in `debug/` have no `class_name`. They reference each other through `preload` consts.
- `Main` loads the menu with `load("res://debug/debug_menu.gd")` inside `if OS.is_debug_build()`, and calls `setup(level, building_manager, tower_menu, vfx, camera)` on it.
- Debug may read through the `Level` getters, but changes state only through public game methods.
- Release exports exclude `debug/*`: the CI Export step adds it to the preset `exclude_filter` when `REQUIRE_SIGNING` is true.
