# Pixel Defense: architecture guide

Written 2026-11-26, after v0.0.2, on branch `docs-update`. Line numbers are as of commit `f2980f8`.

The guide is in reading order:

1. [01-overview.md](01-overview.md): the module map, the scene tree, the composition root, and the autoloads.
2. [02-input-building.md](02-input-building.md): the input pipeline, two-step building, selecting, upgrading and selling.
3. [03-combat.md](03-combat.md): turret aim and fire, bullets, the damage pipeline, and game-feel VFX.
4. [04-waves-enemies.md](04-waves-enemies.md): the wave lifecycle, the budget fill, templates, enemy life, and the variant table.
5. [05-mapgen.md](05-mapgen.md): the map generator pipeline and the painter.
6. [06-debug-ci.md](06-debug-ci.md): the debug menu and the CI/release pipeline.
7. [07-controls.md](07-controls.md): controls deep dive: gesture classifier, click vs pan, the camera frame.
8. [08-waves.md](08-waves.md): wave system deep dive: the cycle, pacing, planning, the numbers, and the win check.
9. [review-findings.md](review-findings.md): places where CLAUDE.md and the code disagree, and fragile code found while mapping.

Diagrams are Mermaid. GitHub renders them, and so does VS Code with a Mermaid extension.

## The five rules that explain most of the code

1. **`Main` is the only place that wires scenes together.** If you want to know "who reacts to X", read `main/main.gd:_ready()`.
2. **`Level` is a facade.** Its children (`WaveManager`, `ProjectileManager`, spawners, `PlayerBase`) emit to `Level`, `Level` re-emits, and `Main` connects. Nothing outside reaches into `Level`'s children, except the debug menu through the `get_*()` getters.
3. **Managers own state changes.** `BuildingManager` owns towers and their coins. `WaveManager` owns pacing. `EnemySpawner._create_enemy()` is the *only* place that creates enemies. `VfxManager.make_particles()` is the only place that creates particles.
4. **Entities are thin, behaviour lives in components and resources.** Examples: `Enemy` + `Pathfinding`/`Health`/`Dash`/`Regeneration`/`DamageSmoke`, and `Tower` + `TurretComponent`. Tunables are `.tres` resources (`TowerStats`, `EnemyStats`, `Drops`, `MajorUpgrade`, `WaveConfig`, `WaveTemplate`, `MapGenConfig`).
5. **Everything random that defines a run is seeded.** The map uses `hash([seed, attempt])` and the waves use `hash([wave_seed, index])`. Only cosmetic randomness (dash phase, death offsets, particles) uses global `randf`.
