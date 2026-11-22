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
