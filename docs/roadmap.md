# Roadmap

Written 2026-11-16, after the "oomf" game-feel pass (PR #24). Each item is its own feature with its own plan, branch and PR. They are done in this order.

## 1. Tower direction (decided)

A build bar and a multi-kind tower harness (`TowerType`, `BuildBar`) were built and removed after playtesting (2026-11-16). The game has one base tower with upgrade paths, built by tapping a cell twice (first tap shows the ghost, second tap builds). What remains from that work is the cannon on the build ghost.

## 2. Enemy variety

First batch built (all values are placeholders): `armored` (flat armor, hits flash steel blue), `regenerator` (heals after 1.5 s without damage, green flash), `splitter` (spawns 3 `mini` on death), `mini` (only from splitters), `dasher` (periodic x3 speed burst). New mechanisms: armor stat, `Health.heal`, per-source speed factors on `Enemy` (also the hook for slowing towers), coloured flash, ability components, death spawns. Waves use them from wave 4 to 12 (wave numbers as on the banner, which shows the internal wave index + 1).

Left: the obstacle breaker (issue #11), aura / support enemies, a boss. Health bars were rejected (screen clutter); instead enemy state effects were built: smoke on damaged big enemies (below 75 % health), green pluses while regenerating, a wind trail while dashing, a deflect burst on armor hits.

## 3. Multiple spawners

Built (placeholders for position and timing): `Level.enemy_spawners` holds any number of spawners; the level has two. `WaveManager` deals each wave round-robin to the spawners that are open (`EnemySpawner.first_wave`, the second one opens at banner wave 3) and owns the spawn pacing, so the whole wave spawns at the old single-spawner rate. The next-wave timer waits for every spawner; the HUD count and the win use the total over all spawners. Closed spawners are drawn faded and have no path preview line. `Level.would_block_path()` checks every spawner, so a tower cannot wall off a closed one either.

Left: per-spawner wave composition (e.g. a spawner that only sends dashers), a stronger tell when a spawner opens, handling enemies that get walled in mid-path (they re-path on `grid_changed`, but nothing checks that a path still exists), a human playtest of the placement and timing.

## 4. Procedural map generation

Built (all values are placeholders): every run (start, restart, F1) plays a generated 45x45 grass island: sea ring, lakes, trees, decoration (dirt dots, a farmland patch near the base, small islands in the water), one base and two spawners near the edge (the second opens at banner wave 3). It uses only tiles of the current tileset; the shore tile is looked up from the tileset's terrain peering bits. The generator only produces shapes the tileset can draw (it has no tile for diagonal water pinches or grass with water on opposite sides). Maps are seeded and deterministic: the seed is printed to the log and shown on the end screen, `godot -- --seed=N` replays a map, and `-- --legacy-map` (or `Level.use_generated_map = false`) plays the hand-made map, which stays in `levels/level.tscn`.

Pathfinding no longer weights tiles: every walkable cell costs the same (enemies are planes), so roads are not preferred and the generator draws none.

Left: seed entry in the start menu, replay-this-map, map sizes other than 45x45 and camera limits for them, the dirt tile set / biomes, roads as decoration, per-spawner count and difficulty scaling, tuning of all `default_map.tres` values, a human playtest. Generation takes about 45 ms per map in a headless desktop run; Web and Android are not measured.

## Later

- Optimization pass. The Web build lags a bit (reported by the author, 2026-11-16); Android is unmeasured. Notes in `docs/ideas.md`.
- Sound; options to reduce screen shake and flashes.
- Effect tuning and the smaller polish items listed in `docs/handoff-oomf.md`.
- More upgrade paths for the tower.
