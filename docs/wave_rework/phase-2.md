# Phase 2: templates, per-spawner composition, boss slot

Read [roadmap.md](roadmap.md) "Agent briefing" first. Requires phase 1 merged. Manager rechecks this brief vs merged code before start.

## Goal

Special waves via data (`WaveTemplate` `.tres`). Each open spawner gets its own share of the budget and its own template. Boss slot every 5th wave and on the last wave (placeholder boss = tank variant until phase 4).

## Design

### `WaveEnemyWeight` (new `core/managers/wave/wave_enemy_weight.gd`, Resource)
`scene: PackedScene`, `multiplier: float` (0 = excluded).

### `WaveTemplate` (new `core/managers/wave/wave_template.gd`, Resource)
- `id: StringName`, `display_name: String`, `description: String` (one line, player-facing, used by phase 3 banner)
- `is_special: bool` (normal waves have no name on the banner)
- `first_wave: int` (0-based), `weight: float` (pick chance)
- `budget_multiplier: float = 1.0`, `spawn_delay_multiplier: float = 1.0`
- `enemy_weights: Array[WaveEnemyWeight]`, `other_multiplier: float = 1.0` (for enemies not listed)

Effective pick weight of a `WaveEnemy` = `entry.weight × multiplier` (listed) or `entry.weight × other_multiplier`. Eligibility rules from phase 1 unchanged (`first_wave`, cost, `max_share`). Template never unlocks an enemy before its `first_wave`.

A "modifier wave" = just another template `.tres`. No code per template.

### Templates (`core/managers/wave/templates/*.tres`, placeholders)

| id | special | first_wave | weight | budget × | delay × | weights |
|---|---|---|---|---|---|---|
| normal | no | 0 | 3.0 | 1.0 | 1.0 | none |
| swarm | yes | 2 | 1.0 | 1.0 | 0.5 | basic ×3, fast ×3, others ×0.3 |
| tank | yes | 2 | 1.0 | 1.0 | 1.2 | heavy ×3, armored ×3, basic ×0.3 |
| rush | yes | 2 | 1.0 | 1.0 | 0.7 | fast ×3, dasher ×3 |
| boss | yes | n/a | 0 | 1.5 | 1.2 | as tank (placeholder until phase 4) |

Display names/descriptions (placeholder text): Swarm "A horde of small enemies.", Tank "Slow, armored and tough.", Rush "Fast enemies, little warning.", Boss "Something big is coming."

### `WaveConfig` additions
- `templates: Array[WaveTemplate]` (normal, swarm, tank, rush), `normal_template: WaveTemplate`, `boss_template: WaveTemplate`
- `boss_interval: int = 5` -> boss on banner waves 5, 10, 15, 20 (index % 5 == 4) and always on the last wave.
- `generate(index, rng, open_spawners: int) -> WavePlan`.

### Per spawner
- Wave budget `budget(index)` split evenly over `open_spawners`; each spawner's share × its template `budget_multiplier`.
- Normal wave: each spawner draws its template by weight among templates w/ `first_wave <= index`. Rule: a spawner never gets the same special template twice in a row (track last template per spawner slot in `WaveManager`, pass it in, or store on the plan; pick the simplest, report it).
- Boss wave: one spawner (seeded pick) gets `boss_template`, the others `normal_template`.
- Before index 2 (banner 3): `normal` only.

### `WavePlan`
Replace `enemies` w/ `spawners: Array[SpawnerPlan]`. New `SpawnerPlan` (RefCounted): `template: WaveTemplate`, `budget: float`, `spent: int`, `enemies: Array[PackedScene]`. Keep `index`, total `budget`, `spent`. Helper `is_special() -> bool` (any spawner special).

### `WaveManager`
- Drop round-robin. Open spawner k spawns its own `SpawnerPlan.enemies` w/ `spawn_delay = d × open_count × template.spawn_delay_multiplier`, `first_delay = d × (k + 1)`. `start_spawning` signature, `_spawning_count`, win gate unchanged.
- Spawner with empty list -> skipped as today.

### `tools/print_waves`
Add `--spawners=N` (open count from banner wave 3; 1 before). Print per spawner: template id + counts. Keep digest.

## Acceptance

- Clean import + boot.
- Same seed + spawners -> same digest; different seed -> different.
- Boss on banner waves 5, 10, 15, 20 (exactly one spawner `boss`), never elsewhere.
- No spawner gets the same special template on two consecutive waves.
- Banner waves 1-2: all `normal`.
- Per spawner: `spent <= share budget`, `spent > share budget − 1`.
- No enemy before its `first_wave` under any template.

## Out of scope

Boss enemy, banner/UI, countdown, spawner-open tell, balancing.
