# Pixel Defense

2D tower defense in **Godot 4.7** (GDScript only, Mobile renderer, 720×720 base viewport, `canvas_items` stretch). Targets desktop, Android and Web, so every input feature needs both a mouse/keyboard and a touch path.

Hand-written first game with AI-assistance past the refactoring phase.

## Commands

There is no test suite, linter or CI on this branch. Verification is a headless load plus playing the game.

```sh
git lfs install && git lfs pull      # PNGs/fonts are in Git LFS; needed once after cloning
godot --headless --import            # (re)build .godot/ cache and parse all scripts
godot --headless --quit-after 120    # boot main scene for 120 frames; must print no SCRIPT ERROR
godot                                # run the game (main scene: main/main.tscn)
godot -e                             # open the editor
```

- On a fresh clone (no `.godot/`), the **first** `--import` reports a bogus parse error in `levels/level.gd` because autoloads are not registered yet. Run it a second time before trusting any error.
- The locally installed Godot may be newer than 4.6. Do not commit version bumps to `project.godot` or `export_presets.cfg` that the editor makes on its own.
- F1 in game reloads the current scene.

## Layout

Feature folders: a script, its scene, its `.tres` data and its sprites live together. There is no global `assets/` or `scenes/` folder any more; do not reintroduce one.

```
core/controls/   PanningCamera, TouchControls, KBMControls, SmoothDamp, InputController
core/managers/   building, currency, pathfinding, projectile, wave
core/game_data.gd
entities/        bases, enemies (+ components), projectiles, spawners, towers (+ upgrades, hue_swap.gdshader)
levels/          level.tscn (TileMapLayer + tileset) and level.gd
main/            main.tscn / main.gd: entry point and composition root
ui/              hud, start_menu, game_end, highlight, tower_preview, tower_menu, mobile, themes
docs/            screenshots and asset licences (.gdignore'd)
```

## Architecture

**Autoloads** (`project.godot`): `CurrencyManager`, `PathfindingManager`, `GameData`. They have no `class_name` and are used by their autoload name. Their state survives `reload_current_scene()`, so `Level._ready()` re-initialises them (`coins = 5`, `PathfindingManager.setup(tile_map_layer)`).

**Scene tree**

```
Main
├─ Level              TileMapLayer, PathfindingPreview (Line2D), PlayerBase,
│                     EnemySpawner, WaveManager, ProjectileManager
├─ BuildingManager    towers are added as its children
├─ InputController
├─ TowerPreview, HighlightTile
├─ TowerMenu          CanvasLayer with upgrade / major / sell buttons above the selected tower
├─ PanningCamera      children: TouchControls, KBMControls
└─ HUD, GameEndScreen, StartMenu, MobileDisplayHandler
```

**`main/main.gd` is the composition root.** It injects cross-scene dependencies into `@export` vars and connects all cross-scene signals in `_ready()`. Siblings do not look each other up; new cross-scene wiring goes in `Main._ready()`. `Level` is a facade: Main and `BuildingManager` use its signals (`wave_started`, `enemy_count_changed`, `lost`, `won`) and methods (`start()`, `register_tower()`, `is_cell_buildable()`, `would_block_path()`) and never reach into its children. `Level` reports only the first outcome (`lost` or `won`). Inside a scene, dependencies are `@export` node references or `%UniqueName` / `@onready`.

**Input flow.** `TouchControls` and `KBMControls` turn raw events into signals (`tapped`, `clicked`, `pan_changed`, `pinch_changed`, `zoomed`, …) in `_unhandled_input`. `PanningCamera` consumes pan/zoom and smooths them through `SmoothDamp` (a `Resource` holding goal + spring state). `InputController` consumes tap/click and converts screen position to a tile cell. Both paths are always connected. `KBMControls` drops mouse events emulated from touch (`device == InputEvent.DEVICE_ID_EMULATION`), so a touch is handled once. A touch is a `tapped` only if it stayed under the drag threshold (3 mm, converted to viewport units per gesture), never had a second finger and was not cancelled; `clicked` needs a press and release within 8 px with no panning.

**Selecting and upgrading.** Tapping a cell with a built tower makes `InputController` call `cancel_preview()` and emit `tower_selected`; any other cell emits `tower_deselected` first. `Main` shows `TowerMenu` and the range ring (`TowerPreview.show_range()` draws only the ring and hides the ghost sprite; `show_at()` brings the ghost back; the ring is shown after `cancel_preview()`) and on deselect hides both, but only if a tower was selected, so the build ghost is left alone. On lost / won `Main` calls `TowerMenu.hide_menu()` and `InputController.cancel_preview()`. `TowerMenu` ignores button presses for 300 ms after its row was (re)built (double-press protection) and clears its tower before hiding (a hidden pressed button emits `pressed`). `TowerMenu` only emits `upgrade_requested`, `major_requested`, `sell_requested`; `Main` forwards them to `BuildingManager.upgrade_tower()`, `apply_major_upgrade()`, `sell_tower()`, which own all currency and tower changes. `tower_sold` makes `Main` call `Level.unregister_tower()` (frees the pathfinding cell, disconnects the projectile hook). Each button has a bottom-left caption `Label` (`lvl+`, `sell`, and `MajorUpgrade.caption`; ignores the mouse, Kenney font, white with outline; it dims with the button and is not recoloured by the major icon tint material). Major buttons use the cannon as icon (`icon` = `turret_texture`, `icon_tint` = `turret_tint`); the button row sits in an 8 px `MarginContainer` inside `%Panel`. Menu buttons are `Control`s, so the GUI consumes presses and touches on them before `_unhandled_input`; `KBMControls.clicked` / `TouchControls.tapped` do not fire for them, so nothing leaks to the cell below.

**Building is two-step:** the first tap on a valid cell shows `TowerPreview` (range ghost); a second tap on the same cell emits `build_requested` → `BuildingManager.place_tower()`. Placement is valid when the cell is unused, the tile is `buildable`, and `PathfindingManager.would_block_path()` says spawner → base is still reachable. After `tower_built`, `Level` marks the cell solid, makes every node in group `"enemies"` recalculate its path, hooks the tower to `ProjectileManager`, and redraws the path preview.

**Waves.** `WaveConfig.generate()` (resource `core/managers/wave/default_waves.tres`, assigned to `WaveManager.config`; enemy variants are `WaveEnemy` sub-resources) builds an `Array[PackedScene]` (count = base + fibonacci(index) × 3; fast enemies from wave 5, heavy from wave 10) and hands it to `EnemySpawner.start_spawning()`. The next wave timer starts when *spawning* completes, not when the wave is cleared. `all_waves_done` (win) fires when the last wave is cleared; `PlayerBase.destroyed` fires on the first enemy that reaches the base (health is 1).

**Tower levels.** `Tower.level` is 0..5 (`TowerStats.MAX_LEVEL`). Effective stats (damage, fire rate, range) = base stats x (1 + 0.1 x level) x the major multiplier; `TowerStats` (base) is never mutated, `Tower._effective_stats` is a copy rebuilt in `_apply_upgrades()` and pushed to `TurretComponent.configure()`. Upgrades 1-4 cost `TowerStats.cost x next level`; the 5th is a `MajorUpgrade` resource (`entities/towers/upgrades/`: `rapid_fire`, `long_shot`, `big_boy`; the tower scene lists the choices) costing `major_cost` (50). Levels 1-4 show the level as a number (`%LevelLabel`, Kenney font 32 px at scale 0.2, white with black outline, top-right corner of the tower; hidden at 0 and 5); a major sets the turret texture (drawn at `MajorUpgrade.turret_scale`, 0.8, via `TurretComponent.set_appearance()`; the normal cannon is 1.0), a hue-swap `ShaderMaterial` (`hue_swap.gdshader`) on base/turret/bullet (all three majors tint their bullet; `rapid_fire` and `big_boy` also swap the bullet texture) and the bullet texture. `Tower.total_spent` is kept by `BuildingManager`; selling refunds all of it.

**Combat.** `TurretComponent` tracks `Enemy` bodies in its detection area and emits `shot(origin, angle)` on its reload timer. `Tower` wraps that in a `ProjectileData` (`RefCounted`, carries damage, penetration and an optional bullet texture/material from the major upgrade) and re-emits `shot`. `ProjectileManager` instantiates the `Bullet`. Bullets damage anything with a `take_damage` method and die after `penetration` hits or on their lifetime timer.

**Data.** Tunables are `Resource` subclasses saved as `.tres` beside the scene: `TowerStats`, `EnemyStats`, `Drops`. `Health` is also a `Resource`. Enemy variants (`basic`, `fast`, `heavy`) are inherited scenes of `entities/enemies/enemy.tscn` with their own stats/drops `.tres`.

**Tiles.** 16 px tiles. The tileset is embedded in `levels/level.tscn` with custom data layer 0 `buildable` (bool) and layer 1 `movement_cost` (int; `255` means solid). `PathfindingManager` reads `movement_cost` by name, rebuilds its grid on every `setup()`, and emits `grid_changed` from `set_cell_solid()` (enemy `Pathfinding` components and the path preview re-path on it). It also writes the tile size to `GameData.grid_cell_size`.

**Physics layers:** 1 enemies, 2 projectiles, 3 towers, 4 player base. Groups: `"enemies"`, `"towers"`.

**Pause.** `StartMenu` pauses the tree on `_ready` and `GameEndScreen` pauses on show; UI that must work while paused needs the right `process_mode`.

## Conventions

- Static typing everywhere: typed vars, params, return types, typed arrays/dictionaries. `:=` only when the type is obvious. Keep it warning-free (integer-division warnings were fixed on purpose).
- `class_name X extends Y` on one line, for everything except autoloads.
- Signals are `snake_case`, past tense, with typed parameters, and are connected in code (`_ready`), not in the editor. Handlers are `_on_<source>_<signal>`.
- Private members and methods start with `_`. Node-local wiring uses `%UniqueName`.
- Composition over inheritance: behaviour lives in component nodes/resources (`Pathfinding`, `Health`, `TurretComponent`) owned by a thin entity script.
- `##` doc comments for public API. Some older functions use `""" """` string docstrings; use `##` in new code.
- Movement belongs in `_physics_process`.
- Input actions are namespaced with `>`: `camera>pan`, `camera>zoom+`, `camera>zoom-`, `camera>pan_left/right/up/down`; plus `left_mouse` and `f1`.
- Tabs for indentation. Resources are referenced by `uid://`; when moving or renaming files, move the `.uid` / `.import` sidecar with them (use `git mv`, or do it in the editor).
- Edit `.tscn` / `.tres` / `project.godot` by hand only for small, obvious changes. They are generated by the editor and easy to corrupt.
- `.github/agents/godot_scripter.md` is a generic Copilot agent persona, not project documentation.

## Where the refactor stopped

Done so far: feature-folder layout, enemy components + stats resources, tower/turret split, `ProjectileData`, camera split into `TouchControls` / `KBMControls` / `SmoothDamp`, `InputController` extraction, explicit wiring in `Main`, `Level` facade, pathfinding `grid_changed`, `WaveConfig` resource, `GameEndScreen`, touch/mouse separation (issue #18).

Open items:

- Only one tower type exists (it has levels and majors, but not several kinds): `BuildingManager` and `TowerPreview` each `preload` the single tower scene / stats. "Individual tower stats" is marked wip, and the tower-selection UI lives on the unmerged `feat/add-ui-for-tower-construction` branch.
- Tower upgrades / `TowerMenu` are verified only headless with injected mouse and touch events (real `Input.parse_input_event` presses on the menu buttons; no leak to `clicked`/`tapped`, no double handling). Not yet checked on a phone, mobile Web or touchscreen laptop, nor with a human looking at it: menu placement/size at zoom and near screen edges, the hue-swap colours, the level number label and the 0.8 cannon scale are reviewed only in desktop renders, not on a device.
- `entities/towers/upgrades/*.tres`, and the `TowerMenu` scene were partly hand-written (the scene has no script `uid://`); re-save them once in the editor. Tower costs, +10 % per level and the major multipliers are placeholders, not balanced.
- `HUD` has a `%DebugCoinsButton` ("+9999", `CurrencyManager.earn(9999)`), visible only when `OS.is_debug_build()`; it is a focus-less `Button`, so its presses do not reach the map.
- The `HUD` panel eats clicks where it overlaps the map (top right), so a tower under it cannot be built or selected there.
- On touch, a short drag that starts on a menu button still presses it (the camera does not pan). Closing the menu by tapping a cell also runs that cell's normal action (denied flash or build ghost).
- A fast double press on a button whose row then shrinks (the last major: three majors + sell become sell only) puts the second press on the map: it deselects the tower and may start a build ghost.
- `ui/tower_menu/tower_menu.tscn` has a hand-invented, non-canonical `uid://`; the editor rewrites it on the first save.
- `TurretComponent.configure()` restarts the reload timer with `min(time_left, new period)` and then restores `wait_time` (Godot's `Timer.start(time)` overwrites it), so an upgrade never delays the pending shot.
- `TurretComponent._get_priority_target()` always returns the first target (TODO: targeting priorities, issue #10).
- The touch/mouse separation is verified only with injected events in headless runs. It still needs a check on a phone, on mobile Web and on a touchscreen laptop; if a platform sends its own synthesized mouse events with a real device id, one tap would arrive as both `tapped` and `clicked`.
- `core/managers/wave/default_waves.tres` and its reference in `wave_manager.tscn` were written by hand and have no `uid://`; re-save them once in the editor.
- `export_presets.cfg` `application/console_wrapper_icon` points at `uid://bgfcsb8hwikmn`, which does not exist.
- `Level.waves_survived` is the number of waves *started*.
