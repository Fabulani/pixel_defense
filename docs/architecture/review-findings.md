# Review findings (2026-11-26, at f2980f8)

These were found while mapping the code. They are not fixed. "Verified" means it was checked line by line; the rest comes from a first pass and still needs confirming.

## Likely bugs

1. **Enemies freeze forever if a tower is built on their cell. Verified.**
   - `would_block_path` only checks spawner → base, so you can build on a cell an enemy stands on.
   - `recalculate_path()` (pathfinding.gd) asks A* for a path from the enemy's current cell. That cell is now solid, so `AStarGrid2D.get_point_path` returns an empty path.
   - `_follow_path` then sets the velocity to 0 forever.
   - The enemy is still alive, so `all_waves_done` never fires. The last wave can soft-lock the win.
   - Knockback can also push an enemy onto a tower cell, because enemies have `collision_mask = 0`.
   - This is a wider case than the "walled-in enemies" roadmap item. Check it in a playtest.
2. **`start_next_wave()` stops `WaveTimer` *before* its "still spawning" early return** (wave_manager.gd:84-88). An outside call during spawning kills the countdown. The debug menu's `skip_to_wave` is a candidate caller.
3. **`upgrade_denied` flashes the wrong cell.** `HighlightTile.flash_denied` flashes the cell under the pointer, and the pointer is on the menu button, not the tower.
4. **The mouse wheel zooms over the GUI.** `KBMControls` reads zoom with `Input.is_action_just_pressed` in `_process`, which GUI consumption does not stop.
5. **Re-pathing resets `_path_index = 0`.** Point 0 is the current cell's centre, so every enemy steps back a little whenever any tower is built.
6. **`set_spawn_delay_multiplier()` uses the open-spawner count of the *next* wave.** `wave_index` is already incremented, so the count may differ from the one the running spawners started with.

## Fragile assumptions

- **Four cell↔world conversions** (`InputController`, `TowerPreview`, `BuildingManager` via `GameData.grid_cell_size`, and `HighlightTile`) agree only because `TileMapLayer` sits at the origin with no transform. `Bullet.setup` also writes a global origin into the local `position`.
- `Bullet._physics_process` dereferences `_data` even when `setup()` was never called.
- `BuildingManager.place_tower` instantiates the tower (running its `_ready`) *before* checking coins.
- `ReloadTimer` wait 0.5 in the `.tscn` is a dummy. It is overwritten by `configure()`.
- The release job depends on the sed matching `exclude_filter="tools/*"` exactly 4 times and on exactly 4 artifacts. An editor change to the presets fails the release.
- The fallback map has no reachability flood-fill, and its land is 1 cell from the edge.
- `Pathfinding` uses only `owner` (no parent fallback), so unlike `Dash` and `Regeneration` it cannot be attached at runtime.
- `MobileDisplayHandler` is a childless `MarginContainer` under a `Node2D`, so its safe-area margins affect nothing. It also ignores mobile Web.
- `ExtraWaveSpawner` (debug) passes `[]` as `last_templates` and ignores `spawn_delay_multiplier`.

## Dead or unused API

- `TowerMenu.contains_screen_point`, `PanningCamera.zoom_by` and the `Tower.upgraded` signal have no callers or listeners.

## CLAUDE.md / docs out of date

- The CLAUDE.md open item "`console_wrapper_icon` points at `uid://bgfcsb8hwikmn`" is stale: the value is now `""`. Verified.
- "Level makes every node in group enemies recalculate its path": in the code, this happens only through `PathfindingManager.grid_changed`. There is no `call_group`.
- `Enemy.damaged(amount)` carries the amount after armor **and** the damage factors, not after armor alone.
- The input-action list leaves out `debug>toggle`. The text says "Godot may be newer than 4.6", but the project is on 4.7. The Layout section describes `docs/` as only screenshots and licences.
- "Land is never within 2 cells of the edge" does not hold for the fallback map.
- `enemy.gd:17` says the knockback cap is "3× a base hit (20 px/s)", but `tower_stats.tres` knockback is 60, so the cap is 1× a base hit.
- README: "randomly generated every wave" should say every run, and the structure section is outdated. `roadmap.md` still mentions `--legacy-map`. `ideas.md` leaves "Debug scene" unchecked although it is done.
- The `MapGenConfig` doc comments say lake and tree coverage are shares of "interior cells", but the code uses the land count. `max_attempts` says it falls back to "an empty map", but the fallback is a square island.
