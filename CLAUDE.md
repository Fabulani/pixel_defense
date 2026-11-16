# Pixel Defense

2D tower defense in **Godot 4.7** (GDScript only, Mobile renderer, 720×720 base viewport, `canvas_items` stretch). Targets desktop, Android and Web, so every input feature needs both a mouse/keyboard and a touch path.

Hand-written first game with AI-assistance past the refactoring phase.

## Commands

There is no test suite or linter. CI (see "CI / releases") only checks that the project exports; verification is a headless load plus playing the game.

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
core/controls/   PanningCamera, CameraShake, TouchControls, KBMControls, SmoothDamp, InputController
core/managers/   building, currency, pathfinding, projectile, vfx, wave
core/vfx/        Flash helper and hit_flash.gdshader (shared by enemies and towers)
core/game_data.gd
entities/        bases, enemies (+ components), projectiles, spawners, towers (+ upgrades, hue_swap.gdshader)
levels/          level.tscn (TileMapLayer + tileset) and level.gd
main/            main.tscn / main.gd: entry point and composition root
ui/              hud, start_menu, game_end, highlight, tower_preview, tower_menu, build_bar, mobile, themes
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
├─ VfxManager         one-shot particle bursts and coin pop-ups, drawn above towers
├─ InputController
├─ TowerPreview, HighlightTile   (TowerPreview shows base + cannon ghost or the range ring)
├─ TowerMenu          CanvasLayer with upgrade / major / sell buttons above the selected tower
├─ PanningCamera      children: TouchControls, KBMControls, CameraShake
└─ HUD, GameEndScreen, StartMenu, MobileDisplayHandler
```

**`main/main.gd` is the composition root.** It injects cross-scene dependencies into `@export` vars and connects all cross-scene signals in `_ready()`. Siblings do not look each other up; new cross-scene wiring goes in `Main._ready()`. `Level` is a facade: Main and `BuildingManager` use its signals (`wave_started`, `enemy_count_changed`, `lost`, `won`, and the effect signals `bullet_fired`, `bullet_hit`, `enemy_died`) and methods (`start()`, `register_tower()`, `is_cell_buildable()`, `would_block_path()`) and never reach into its children. `Level` reports only the first outcome (`lost` or `won`). Inside a scene, dependencies are `@export` node references or `%UniqueName` / `@onready`.

**Input flow.** `TouchControls` and `KBMControls` turn raw events into signals (`tapped`, `clicked`, `pan_changed`, `pinch_changed`, `zoomed`, …) in `_unhandled_input`. `PanningCamera` consumes pan/zoom and smooths them through `SmoothDamp` (a `Resource` holding goal + spring state). `InputController` consumes tap/click and converts screen position to a tile cell. Both paths are always connected. `KBMControls` drops mouse events emulated from touch (`device == InputEvent.DEVICE_ID_EMULATION`), so a touch is handled once. A touch is a `tapped` only if it stayed under the drag threshold (3 mm, converted to viewport units per gesture), never had a second finger and was not cancelled; `clicked` needs a press and release within 8 px with no panning.

**Selecting and upgrading.** Tapping a cell with a built tower makes `InputController` call `cancel_preview()` and emit `tower_selected`; any other cell emits `tower_deselected` first. `Main` shows `TowerMenu` and the range ring (`TowerPreview.show_range()` draws only the ring and hides both ghost sprites (base and cannon); `show_at()` brings the ghost back; the ring is shown after `cancel_preview()`) and on deselect hides both, but only if a tower was selected, so the build ghost is left alone. On lost / won `Main` calls `TowerMenu.hide_menu()` and `InputController.cancel_preview()`. `TowerMenu` ignores button presses for 300 ms after its row was (re)built (double-press protection) and clears its tower before hiding (a hidden pressed button emits `pressed`). `TowerMenu` only emits `upgrade_requested`, `major_requested`, `sell_requested`; `Main` forwards them to `BuildingManager.upgrade_tower()`, `apply_major_upgrade()`, `sell_tower()`, which own all currency and tower changes. `tower_sold` makes `Main` call `Level.unregister_tower()` (frees the pathfinding cell, disconnects the projectile hook). Each button has a bottom-left caption `Label` (`lvl+`, `sell`, and `MajorUpgrade.caption`; ignores the mouse, Kenney font, white with outline; it dims with the button and is not recoloured by the major icon tint material). Major buttons use the cannon as icon (`icon` = `turret_texture`, `icon_tint` = `turret_tint`); the button row sits in an 8 px `MarginContainer` inside `%Panel`. Menu buttons are `Control`s, so the GUI consumes presses and touches on them before `_unhandled_input`; `KBMControls.clicked` / `TouchControls.tapped` do not fire for them, so nothing leaks to the cell below.

**Building is three-step.** (1) The player picks a kind on `BuildBar` (`ui/build_bar/`, CanvasLayer at the bottom centre; one 64x64 button per `TowerType` in `BuildingManager.tower_types`, own translucent background, no shared panel; icon = base + cannon sprites, bottom-left cost caption, dimmed at alpha 0.4 when unaffordable but still pressable). The selected button is scaled to 0.9 with a thicker (4 px instead of 2 px) white outline and the same translucent background; pressing it again deselects, pressing another switches. Each button sits in a fixed-size slot `Control` because a `Container` resets the scale of its direct children. `BuildBar` only emits `tower_type_selected` / `tower_type_deselected`; `Main` forwards them to `InputController.set_build_type()` (which hides a showing ghost, not the range ring of a selected tower), and on selection also closes the tower menu and ring. Without a selected type, taps on non-tower cells do nothing (no ghost, no denied flash); tapping a built tower still selects it and keeps the type. On lost / won `Main` also calls `BuildBar.deselect()`. Bar buttons are `Control`s (the row wrapper ignores the mouse), so presses on them never reach the map. (2) The first tap on a valid cell shows `TowerPreview.show_at(cell, type)` (base and cannon ghost at 0.5 alpha plus range ring from `type.stats.detection_range`); (3) a second tap on the same cell emits `build_requested(cell, type)` -> `BuildingManager.place_tower(cell, type)`, which spends `type.stats.cost`, instantiates `type.scene`, sets `stats` and `tower_type` before `add_child`. The type stays selected after a build. `TowerType` (`entities/towers/tower_type.gd`, `.tres` per kind, e.g. `basic_tower.tres`) holds id, name, scene, base `TowerStats` and the icon / ghost textures; `TowerType.stats` and the textures override what the tower scene carries, so keep both in step for a new kind; a new kind needs only a scene, a `TowerType` `.tres` and one entry in `BuildingManager.tower_types`. Placement is valid when the cell is unused, the tile is `buildable`, and `PathfindingManager.would_block_path()` says spawner → base is still reachable. After `tower_built`, `Level` marks the cell solid, makes every node in group `"enemies"` recalculate its path, hooks the tower to `ProjectileManager`, and redraws the path preview.

**Waves.** `WaveConfig.generate()` (resource `core/managers/wave/default_waves.tres`, assigned to `WaveManager.config`; enemy variants are `WaveEnemy` sub-resources) builds an `Array[PackedScene]` (count = base + fibonacci(index) × 3; fast enemies from wave 5, heavy from wave 10) and hands it to `EnemySpawner.start_spawning()`. The next wave timer starts when *spawning* completes, not when the wave is cleared. `all_waves_done` (win) fires when the last wave is cleared; `PlayerBase.destroyed` fires on the first enemy that reaches the base (health is 1).

**Tower levels.** `Tower.level` is 0..5 (`TowerStats.MAX_LEVEL`). Effective stats (damage, fire rate, range) = base stats x (1 + 0.1 x level) x the major multiplier; `TowerStats` (base) is never mutated, `Tower._effective_stats` is a copy rebuilt in `_apply_upgrades()` and pushed to `TurretComponent.configure()`. Upgrades 1-4 cost `TowerStats.cost x next level`; the 5th is a `MajorUpgrade` resource (`entities/towers/upgrades/`: `rapid_fire`, `long_shot`, `big_boy`; the tower scene lists the choices) costing `major_cost` (50). Levels 1-4 show the level as a number (`%LevelLabel`, Kenney font 32 px at scale 0.2, white with black outline, top-right corner of the tower; hidden at 0 and 5); a major sets the turret texture (drawn at `MajorUpgrade.turret_scale`, 0.8, via `TurretComponent.set_appearance()`; the normal cannon is 1.0), a hue-swap `ShaderMaterial` (`hue_swap.gdshader`) on base/turret/bullet (all three majors tint their bullet; `rapid_fire` and `big_boy` also swap the bullet texture) and the bullet texture. `Tower.total_spent` is kept by `BuildingManager`; selling refunds all of it.

**Combat.** `TurretComponent` tracks `Enemy` bodies in its detection area and emits `shot(origin, angle)` on its reload timer. `Tower` wraps that in a `ProjectileData` (`RefCounted`, carries damage, penetration and an optional bullet texture/material from the major upgrade) and re-emits `shot`. `ProjectileManager` instantiates the `Bullet`. Bullets damage anything with a `take_damage` method and die after `penetration` hits or on their lifetime timer.

**Game feel.** All effects are visual only and must not change tower stats, fire timing or bullet origin.

- *Wiring.* `Bullet.hit` → `ProjectileManager.bullet_hit` / `bullet_fired`, and `EnemySpawner.enemy_died`, are relayed by `Level`; `Main` connects them, `tower_built`, `tower_upgraded`, `lost` and `wave_started` to `VfxManager.play_*`, `Tower.play_placed()`, `PanningCamera.shake()` and `HUD.show_wave_banner()`.
- *Particles.* `VfxManager.make_particles()` (static) is the only place that constructs particle nodes (`GPUParticles2D`, 1 px texture, alpha fade ramp), so swapping to `CPUParticles2D` is a one-function change. Bursts are one-shot, freed on `finished` (plus a safety timer), capped at `max_live_bursts`; pop-ups at `max_live_popups`. `VfxManager` runs with `PROCESS_MODE_ALWAYS` so effects finish behind the end screen. Bullets build their trail with the same factory and hand it to their parent on death so it fades out.
- *Flash.* `Flash.play(sprite, duration)` tweens the `flash` uniform that both `hit_flash.gdshader` and `hue_swap.gdshader` have. Enemies own a permanent hit-flash material; towers without a major get a temporary one that is removed afterwards. Do not flash with overbright `modulate` (lost on Web, and it feeds the hue-swap saturation test).
- *Enemy death.* `Enemy.die()` is idempotent (`is_dying()`): it emits `died` once (coins are paid then), stops pathing, sets `collision_layer = 0` deferred, leaves group `"enemies"`, fades and shrinks the sprite to half its normal scale over 0.25 s, then frees. The HUD count, `wave_cleared` and the win therefore lag the kill by the fade. Bullets and `TurretComponent` ignore dying enemies.
- *Knockback.* `ProjectileData.knockback` = `TowerStats.knockback` × `MajorUpgrade.knockback_multiplier`; `Enemy.apply_knockback()` scales it by `EnemyStats.knockback_scale`, caps it, and `Pathfinding.move(extra_velocity)` adds it after the path velocity (rotation untouched), decaying over 0.12 s.
- *Tower.* Recoil tweens only `%Turret`'s `Sprite2D.offset` (divided by the cannon scale), never `position`, `rotation` or `scale`. The placement squash tweens the base and cannon sprite scales back to their stored target scale; `set_appearance()` kills it. Recoil, knockback and trail (`trail_amount`, `trail_lifetime`, `trail_particle_scale`, colour = bullet tint) differ per major via `MajorUpgrade` exports.
- *Camera shake.* `CameraShake` (always processing) writes only `Camera2D.offset` (trauma² × noise ÷ zoom); `position` and `zoom` belong to `SmoothDamp`. It is triggered only on loss.

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

## CI / releases

- `.github/workflows/build.yml` is a reusable workflow (`workflow_call`: inputs `version`, `require_signing`; optional secrets `ANDROID_KEYSTORE_BASE64/_USER/_PASSWORD`). It runs a `check` job and an `export` matrix (windows, linux, android, web) and uploads artifacts `export-<platform>`, one file each, named `pixel_defense-v<version>-<platform>...`.
- `.github/workflows/release.yml` runs on tag `vMAJOR.MINOR.PATCH`: `meta` validates the tag strictly and requires the commit to be on `main`; `build` calls `build.yml` with `require_signing: true` (secrets passed explicitly); `release` creates the GitHub release with `gh release create --verify-tag --generate-notes` (custom "Downloads" text is prepended) plus `SHA256SUMS.txt`, and uses `--clobber` uploads on re-runs; `pages` deploys the web export (after `release`).
- Top-level `permissions: contents: read`; jobs raise only what they need (a called workflow cannot exceed its caller). Never put `${{ }}` context values inside `run:`; pass them through `env:`.
- One-time setup (Pages with Actions source, `v[0-9]*` tag rule on the `github-pages` environment, Android keystore secrets) and the release steps are in README "Releasing". Cut a release: `git tag v0.1.0 && git push origin v0.1.0`. Only tag releases are release-signed (`require_signing`); PR/main/manual builds get a throwaway Android debug key. Failure logs are `logs-*` artifacts (not `export-*`). `v0.0.0` is rejected (start at v0.0.1).

## Where the refactor stopped

Done so far: feature-folder layout, enemy components + stats resources, tower/turret split, `ProjectileData`, camera split into `TouchControls` / `KBMControls` / `SmoothDamp`, `InputController` extraction, explicit wiring in `Main`, `Level` facade, pathfinding `grid_changed`, `WaveConfig` resource, `GameEndScreen`, touch/mouse separation (issue #18).

Open items:

- The multi-kind harness exists (`TowerType`, `BuildBar`, `BuildingManager.tower_types`) but only the basic tower ships; more kinds need their own scene, stats and sprites. "Individual tower stats" is still wip. The old `feat/add-ui-for-tower-construction` branch is obsolete for the build UI.
- `entities/towers/basic_tower.tres` and `ui/build_bar/build_bar.tscn` were written by hand without `uid://`; re-save them once in the editor.
- `BuildBar` is verified only headless (injected mouse and touch events) and in one desktop render. Not checked on a phone: button size, safe area / notch, overlap with the map's bottom rows.
- No keyboard shortcut to pick a tower type.
- Multi-touch across the build bar or tower menu and the map is not coordinated: a finger held on a button does not block a second finger's map tap, and a pinch starting on a button cannot zoom.
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
- Game-feel effects are checked by headless scenario runs and by the author playing on PC. Not yet checked: Web export (GPU particles and trails on the Compatibility renderer, first-emission stutter), Android frame rate in late waves, a phone screen. All effect values are first-pass, not tuned.
- Every bullet, muzzle flash and burst creates its own `GPUParticles2D` and `ParticleProcessMaterial`; nothing is pooled or cached. Measure on a device before optimising.
- There is no sound, and no setting to reduce flashes or screen shake.
- Dying enemies freeze mid-fade behind the win/loss screen (the tree is paused; only `VfxManager`, `CameraShake` and the wave banner keep running).
- Enemies removed by the base (`PlayerBase` frees them) get no death effect.
