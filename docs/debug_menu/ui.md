# Debug menu: UI bundle

Read [roadmap.md](roadmap.md) (Decisions, Contract, Agent briefing) first. Code against the Contract. **Do not read or edit the backend files**: the backend bundle implements them in parallel. Your files: `debug/debug_menu.gd` (new), `main/main.gd`, `ui/hud/hud.gd`, `ui/hud/hud.tscn`, `project.godot`.

## Existing public API you may also use
- `CurrencyManager.earn(amount: int)` (autoload).
- `TowerMenu.get_tower() -> Tower` (null when none selected). `Tower.level: int`, `Tower.major: MajorUpgrade`, `Tower.major_upgrades: Array[MajorUpgrade]`, `MajorUpgrade.caption: String`, `TowerStats.MAX_LEVEL` (5).
- `BuildingManager.tower_upgraded(tower)` signal (refresh the Towers section).
- `Enemy.set_speed_factor(source: StringName, factor: float)`, `clear_speed_factor(source)`, `take_damage(amount: float)`, `die()`, `is_dying()`.
- `VfxManager`: `play_muzzle(origin, angle, color)`, `play_impact(pos, direction, color)`, `play_death(pos, color)`, `play_deflect(pos)`, `play_coin_popup(pos, coins)`, `play_tower_built(pos)`, `play_tower_upgraded(pos)`.
- `PanningCamera.shake(amount: float)`, `Camera2D.get_screen_center_position()`.
- Component classes for attach: `DamageSmoke`, `Regeneration`, `Dash` (`X.new()` then `enemy.add_child(...)`).

## `project.godot`
Add input action `debug>toggle` = physical F8 (`physical_keycode` 4194339), modelled exactly on the existing `f1` entry. Small hand edit, nothing else in the file.

## `ui/hud/*`
Remove `%DebugCoinsButton` (node in `hud.tscn`, var/connect/handler in `hud.gd`). The menu takes it over.

## `main/main.gd`
In `_ready()`, after the existing wiring: `if OS.is_debug_build():` create `DebugMenu.new()`, set its refs (`level`, `building_manager`, `tower_menu`, `vfx`, `camera`), `add_child`. Nothing else changes in Main.

## `debug/debug_menu.gd`: `class_name DebugMenu extends CanvasLayer`
- `layer` above HUD/TowerMenu/GameEndScreen/StartMenu (e.g. 100). `process_mode = PROCESS_MODE_ALWAYS`. Whole UI built in code in `_ready()`, hidden at start.
- Toggle: `debug>toggle` in `_unhandled_input` (mark handled), and a small focus-less `DBG` button bottom right (always visible in debug builds; touch path).
- Layout: `PanelContainer` anchored right, full height minus the HUD panel at the top right (leave ~top 25 % free; read the HUD panel size from nothing, just a margin constant). `mouse_filter = STOP` on the panel so presses on its background never reach the map. Inside: `ScrollContainer` → `VBoxContainer`. Each section = header toggle `Button` (▸/▾ + name) + content `VBoxContainer` shown when open. Width ~200 px viewport units, compact font (~14). Every `Button`/`OptionButton`/`SpinBox` focus-less where possible (`focus_mode = FOCUS_NONE`), so nothing grabs keyboard and presses never leak to `clicked`/`tapped`.
- `static var`s keep toggles and open sections across `reload_current_scene()`: god mode, budget scale, countdown held, freeze, invulnerable, hold fire, time scale, open sections, selected enemy type/count/spawn location, wave number. On `_ready()` re-apply the ones that act on the game (god mode, budget scale, countdown held, hold fire, time scale).
- The time scale stays as chosen (static, re-applied on ready) until changed in the menu; the Time section shows the current value.

### Sections
1. **Game**: `God mode` toggle → `level.set_god_mode`. `+9999 coins`.
2. **Waves**: wave number SpinBox 1..`level.get_max_waves()` (banner numbers; API is 0-based, pass n − 1). `Spawn wave N` → `debug_spawn_wave`. `Jump to wave N` → `debug_jump_to_wave`. `Budget ×N` cycle button 0.5/1/2/4/8 → `set_budget_scale`. `Hold countdown` toggle → `set_countdown_held`. `Clear enemies` → `die()` on all `level.get_enemies()`.
3. **Enemies**: type OptionButton from scanning `res://entities/enemies/` subfolders with `ResourceLoader.list_directory()` (Godot 4.4+, handles exported remaps); keep scenes whose root instantiates as `Enemy` (instantiate once, check, `free()`); sorted by name. Count SpinBox 1..50. Spawn-at OptionButton: `Spawner 1..level.get_spawner_count()` + `View centre`. `Spawn` → `debug_spawn_enemies` / `debug_spawn_enemies_at(camera.get_screen_center_position())`; apply freeze / invulnerable to the returned enemies. Toggles `Freeze` (`set_speed_factor(&"debug", 0.0)` / `clear_speed_factor(&"debug")`) and `Invulnerable` (`debug_invulnerable`) apply to all live enemies when toggled and to later debug spawns. Buttons `HP 100/75/50/25/10 %` (`set_health_ratio`), `Hit 1`, `Kill all`. `Attach` buttons `Smoke`, `Regen`, `Dash`: add the component to each live enemy that has no child of that class.
4. **Towers**: label `Selected: lvl N [major caption]` or `Select a tower`. Buttons `L0`..`L5` and a major OptionButton (the selected tower's `major_upgrades` captions) → `building_manager.debug_set_level(tower, level, chosen major)`. Disabled without a selection; refresh on `tower_upgraded` and when the menu opens, and poll `tower_menu.get_tower()` cheaply (e.g. every 0.2 s while visible). `Hold fire` toggle → `building_manager.set_hold_fire`.
5. **Time**: buttons 0.1 / 0.25 / 0.5 / 1 / 2 / 4 → `Engine.time_scale`, current one marked. `Pause` toggle → `get_tree().paused` (reflects the real state when the menu opens; StartMenu / GameEndScreen pause too, don't fight them). `Step` (only while paused): unpause, `await get_tree().physics_frame`, pause.
6. **VFX** (at `camera.get_screen_center_position()`): `Muzzle`, `Impact`, `Death`, `Deflect`, `Coins +5`, `Built`, `Upgraded`, `Shake` (0.7). Use white / a fixed colour where a colour is needed.

## Acceptance
- `godot --headless --import` (twice if `.godot/` is fresh), `godot --headless --quit-after 120`. **Note:** the backend bundle adds the Contract methods in parallel; parse errors that only name missing Contract members are expected while it runs. Report them; any other error is yours.
- Scratch scenario (scratchpad, or a temp in-repo scene deleted after) once the backend has landed if it has by then, else skip and say so: menu hidden at start; injected F8 key → visible; injected mouse press + release and touch press + release on a menu button and on the panel background → no `KBMControls.clicked` / `TouchControls.tapped`; each section opens.
- Never hand-write `uid://`. You create no `.tscn`/`.tres`; `.uid` sidecar for the new script comes from `--import`.

Report in the implementer.md format with command output.
