# CLAUDE.md outdated

- **Type:** docs
- **Priority:** low

`CLAUDE.md` (project instructions) is out of date in these places:

## Items
- The open item "`console_wrapper_icon` points at `uid://bgfcsb8hwikmn`" is stale: the value is now `""`.
- "After `tower_built`, `Level` … makes every node in group `enemies` recalculate its path": this happens only through `PathfindingManager.grid_changed`; there is no `call_group`.
- `Enemy.damaged(amount)` carries the amount after armor **and** the damage factors.
- The input-action list in Conventions leaves out `debug>toggle`.
- "The locally installed Godot may be newer than 4.6" contradicts "Godot 4.7" at the top.
- The Layout section describes `docs/` as only screenshots and licences. It now also holds `ideas.md`, `roadmap.md`, `wave_rework/` and `architecture/`.
- "Land is never within 2 cells of the map edge" does not hold for the fallback map (see 014).
- Open items that are now stale and should be removed or reworded: "multiple spawners … not playtested by a human" (the roadmap marks the playtest done); "Special waves have no banner/name yet (phase 3)" (phase 3 shipped the banner); probably also the two "re-save once in the editor" notes for `EnemySpawner2` and `%SeedLabel` (both nodes now have an editor `unique_id`; check once).
- The open items are being moved to GitHub issues (see `docs/architecture/issues/`); once they are created, replace them with links.
