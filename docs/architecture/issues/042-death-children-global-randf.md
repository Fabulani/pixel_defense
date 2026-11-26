# Death-child offsets use the global random generator

- **Type:** robustness / determinism
- **Priority:** low
- **Area:** spawners

## What happens

`EnemySpawner._spawn_death_children()` places each child with `Vector2.from_angle(randf() * TAU) * randf_range(2.0, 6.0)`, using the global generator.

The wave *contents* stay seeded (`WaveConfig.make_rng`), but the minis' starting positions are not, so a replay of the same seed is not exact. This matters only if replays, a seeded test harness, or recorded runs ever need to be bit-exact.

The architecture README (rule 5) treats this as cosmetic randomness on purpose, so this may well be closed as *by design*.

## Where

`entities/spawners/enemy_spawner.gd`, `_spawn_death_children()`.

## Ideas

- Give `EnemySpawner` a local `RandomNumberGenerator` seeded from the map seed and its index.
- Or use a fixed pattern (evenly spaced angles), which also spreads the minis more evenly.
