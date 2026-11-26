# README, roadmap, ideas and code comments are out of date

- **Type:** docs
- **Priority:** low

## Items
- `README.md`: "randomly generated every wave" should say every run. The project-structure section predates the feature folders and `debug/`.
- `docs/roadmap.md`: still mentions `-- --legacy-map` / `Level.use_generated_map`, which wave rework phase 0 removed.
- `docs/ideas.md`: "Debug scene" is unchecked although the debug menu exists.
- `levels/generation/map_gen_config.gd`: `lake_coverage` / `tree_coverage` say "share of interior cells", but the code uses the land count. `max_attempts` says it falls back to "an empty map", but the fallback is a square island.
- `entities/enemies/enemy.gd:17`: the knockback-cap comment says "3× a base hit (20 px/s)", but `tower_stats.tres` knockback is 60, so the cap equals one hit.
- The header comment of `.github/workflows/build.yml` says "release exports", but non-tag builds are debug exports.
