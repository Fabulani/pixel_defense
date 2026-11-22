# Roadmap

Written 2026-11-16, after the "oomf" game-feel pass (PR #24). Each item is its own feature with its own plan, branch and PR. They are done in this order.

## [x] 1. Tower direction (decided)

A build bar and a multi-kind tower harness (`TowerType`, `BuildBar`) were built and removed after playtesting (2026-11-16). The game has one base tower with upgrade paths, built by tapping a cell twice (first tap shows the ghost, second tap builds). What remains from that work is the cannon on the build ghost.

## [x] 2. Enemy variety

First batch built (all values are placeholders): `armored` (flat armor, hits flash steel blue), `regenerator` (heals after 1.5 s without damage, green flash), `splitter` (spawns 3 `mini` on death), `mini` (only from splitters), `dasher` (periodic x3 speed burst). New mechanisms: armor stat, `Health.heal`, per-source speed factors on `Enemy` (also the hook for slowing towers), coloured flash, ability components, death spawns. Waves use them from wave 4 to 12 (wave numbers as on the banner, which shows the internal wave index + 1).

Health bars were rejected (screen clutter); instead enemy state effects were built (PR #30): smoke on damaged big enemies (below 75 % health), green pluses while regenerating, a wind trail while dashing, a deflect burst on armor hits.

Left (postponed until the debug menu exists, `docs/debug_menu/roadmap.md`):

- [x] Enemy state effects instead of health bars (PR #30)
- [ ] The obstacle breaker (issue #11)
- [ ] Aura / support enemies
- [ ] A boss

## [x] 3. Multiple spawners

Built (placeholders for position and timing): `Level.enemy_spawners` holds any number of spawners; the level has two. `WaveManager` deals each wave round-robin to the spawners that are open (`EnemySpawner.first_wave`, the second one opens at banner wave 3) and owns the spawn pacing, so the whole wave spawns at the old single-spawner rate. The next-wave timer waits for every spawner; the HUD count and the win use the total over all spawners. Closed spawners are drawn faded and have no path preview line. `Level.would_block_path()` checks every spawner, so a tower cannot wall off a closed one either.

- [x] A human playtest of the placement and timing

Follow-ups (not part of this feature):

- [ ] Per-spawner wave composition (e.g. a spawner that only sends dashers). Belongs to a wave rework that needs its own planning session: the current wave generation is only for testing and development. That session decides how waves, special waves and bosses work.
- [ ] Spawner-open tell: an arrow or exclamation mark at the screen edge pointing to a newly opened spawner. It slides along the edge to follow the spawner's direction as the camera moves and disappears once the spawner is on screen.
- [ ] Walled-in enemies: when a tower is built on top of enemies, they quickly spread out from the tower centre to the closest free cells. If the map still blocks them, they move towards the base at half speed. (Today they only re-path on `grid_changed`; nothing checks that a path still exists.)

## [x] 4. Procedural map generation

Built (all values are placeholders): every run (start, restart, F1) plays a generated 45x45 grass island: sea ring, lakes, trees, decoration (dirt dots, a farmland patch near the base, small islands in the water), one base and two spawners near the edge (the second opens at banner wave 3). It uses only tiles of the current tileset; the shore tile is looked up from the tileset's terrain peering bits. The generator only produces shapes the tileset can draw (it has no tile for diagonal water pinches or grass with water on opposite sides). Maps are seeded and deterministic: the seed is printed to the log and shown on the end screen, `godot -- --seed=N` replays a map, and `-- --legacy-map` (or `Level.use_generated_map = false`) plays the hand-made map, which stays in `levels/level.tscn`.

Pathfinding no longer weights tiles: every walkable cell costs the same (enemies are planes), so enemies do not follow the (purely cosmetic) roads.

Update (PR #29): maps are now 50x50 pangea islands with dirt roads (cosmetic, buildable) and lamps beside them, farms clumped around the base, and the camera fits and limits zoom to the map. Generation takes about 215 ms per map in a headless desktop run; Web and Android are not measured.

Left:

- [ ] Seed entry in the start menu
- [ ] Replay-this-map
- [x] Map sizes other than 45x45 and camera limits for them (50x50, `PanningCamera.fit_rect()`)
- [ ] The dirt tile set / biomes (dirt is used for roads only)
- [x] Roads as decoration
- [ ] Per-spawner count and difficulty scaling
- [ ] Tuning of all `default_map.tres` values
- [ ] Default configurations: a few named presets (e.g. small / large island, many lakes)
- [ ] Advanced config options, added together with the map generation options screen (`docs/ideas.md`)
- [ ] A human playtest

## [ ] 5. Wave rework

Replaces the dev-only wave generation: seeded per-wave budget, 20 waves (configurable), wave templates (special waves, boss slot), per-spawner composition, countdown with call-early bonus, wave banner. Plan, decisions and phase briefs: `docs/wave_rework/roadmap.md`.

- [x] Phase 0: remove the legacy map option
- [x] Phase 1: seeded budget generator
- [x] Phase 2: templates, per-spawner composition, boss slot
- [x] Phase 3: countdown, call-early bonus, wave banner
- [ ] Debug menu (`docs/debug_menu/roadmap.md`), unblocks phase 4
- [ ] Phase 4: bosses (after the debug menu)

## Later

- [ ] Optimization pass. The Web build lags a bit (reported by the author, 2026-11-16); Android is unmeasured. Notes in `docs/ideas.md`.
- [ ] Sound; options to reduce screen shake and flashes.
- [ ] Player time scale (fast-forward), see `docs/ideas.md`.
- [ ] Effect tuning and the smaller polish items listed in `docs/ideas.md` ("Effects polish").
- [ ] More upgrade paths for the tower.
- [ ] Endless mode (after the wave rework): waves past `max_waves` with growing budget; score = waves survived.
