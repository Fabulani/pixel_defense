# Phase 1: seeded budget generator

Read [roadmap.md](roadmap.md) "Agent briefing" first. Requires phase 0 merged (`map_seed` always >= 1).

## Goal

Replace Fibonacci count + slot overwrite w/ a per-wave budget spent on enemies by weighted pick. Seeded from the map seed. 20 waves. No UI change. A headless tool prints the waves.

## Design

### `WaveEnemy` (`core/managers/wave/wave_enemy.gd`)
Keep `scene`, `first_wave` (0-based index). Remove `share`. Add:
- `cost: int` threat points (> 0)
- `weight: float` pick weight
- `max_share: float` (`@export_range(0, 1)`): max fraction of the wave budget this entry may take. `1.0` = uncapped.

### `WaveConfig` (`wave_config.gd`)
- `max_waves: int = 20`
- `base_budget: float`, `budget_per_wave: float`, `budget_growth: float`
- `budget(index: int) -> float` = `(base_budget + budget_per_wave * index) * pow(budget_growth, index)`
- `enemies: Array[WaveEnemy]`
- Remove `base_enemy_count`, `default_enemy`, `variants`, `_fibonacci`.
- `generate(index: int, rng: RandomNumberGenerator) -> WavePlan`

Fill rule in `generate`:
1. `remaining = budget(index)`, `spent_by_entry` per entry = 0.
2. Eligible entry: `first_wave <= index` AND `cost <= remaining` AND (`max_share >= 1.0` OR `spent_by_entry + cost <= max_share * budget`).
3. None eligible -> stop. Else weighted pick among eligible (`rng`), append its scene, `remaining -= cost`, add to its spend. Loop.
4. Spawn order = pick order.

Guard: empty `enemies` or all weights 0 -> `push_error`, empty plan.

### `WavePlan` (new `core/managers/wave/wave_plan.gd`, `class_name WavePlan extends RefCounted`)
Fields: `index: int`, `budget: float`, `spent: int`, `enemies: Array[PackedScene]`. Plain container; phases 2-3 extend it.

### Seeding
- `WaveManager.setup(spawners: Array[EnemySpawner], wave_seed: int)`. `Level._ready()` passes `map_seed`.
- Per wave: new `RandomNumberGenerator`, `seed = hash([wave_seed, index])`. Same wave index + seed -> same plan regardless of earlier waves. No global `randi`/`randf` in wave code.

### `WaveManager` (`wave_manager.gd`)
- `start_next_wave()` uses `config.generate(wave_index, rng).enemies`; keep round-robin deal, pacing, `_spawning_count`, win gate, all signals unchanged.
- `min_spawn_delay` default 0.3 (placeholder).

### `default_waves.tres` (placeholders, do not tune)
`max_waves = 20`, `base_budget = 4.0`, `budget_per_wave = 2.0`, `budget_growth = 1.08` (-> wave 1 ≈ 4, wave 10 ≈ 44, wave 20 ≈ 181).

| enemy | cost | weight | max_share | first_wave |
|---|---|---|---|---|
| basic | 1 | 3.0 | 1.0 | 0 |
| fast | 1 | 2.0 | 0.4 | 5 |
| dasher | 2 | 2.0 | 0.4 | 3 |
| heavy | 4 | 1.0 | 0.4 | 10 |
| regenerator | 4 | 1.0 | 0.4 | 8 |
| armored | 5 | 1.0 | 0.4 | 6 |
| splitter | 6 | 1.0 | 0.3 | 11 |

Edit the `.tres` in a way the editor would write it (sub-resources `WaveEnemy`, keep existing uids). If unsure the file stays loadable -> say so in report.

### Economy
`entities/enemies/fast/fast_enemy_drops.tres`: `coins = 1`.

### Tool `tools/print_waves.tscn` + `tools/print_waves.gd`
- Scene (so autoloads load). Run: `godot --headless res://tools/print_waves.tscn -- --seed=N --waves=20`. Defaults: seed 1, waves = `max_waves`. Loads `res://core/managers/wave/default_waves.tres`.
- Per wave one line: `wave <banner n> budget <b> spent <s> count <c> | <type>:<n> ... | coins <wave coins> total <cumulative>`. Type name = scene file basename. Coins: instantiate each scene once, read `Enemy.drops.coins`, add death children (`stats.death_spawn_scene` × `death_spawn_count`) recursively; free instances.
- Last line: `digest <hash of all printed lines>`. Then `get_tree().quit()`.
- Add `tools/*` to `exclude_filter` of every preset in `export_presets.cfg` (small hand edit; touch nothing else there).

## Acceptance (report output of each)

- Import + `--quit-after 120` clean.
- `print_waves --seed=1` twice -> identical; `--seed=2` -> different digest.
- From tool output (or a scratch check script): every wave `spent <= budget` and `spent > budget - 1` (basic cost 1 always eligible); no type before its `first_wave`; no capped type over `max_share * budget`.
- 20 waves; wave 21 never sent (scratch scenario or code read, say which).
- Scratch scenario (scratch dir, not repo): `Level.won` fires after the last wave is cleared; reload (`reload_current_scene`) mid-game never fires it.

## Out of scope

Templates, per-spawner composition, countdown/UI, spawn pacing rework, balancing.
