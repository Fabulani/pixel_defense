# 4. Waves and enemies

## Wave lifecycle (`core/managers/wave/wave_manager.gd`)

```mermaid
stateDiagram-v2
  [*] --> Waiting: setup(spawners, map_seed)
  Waiting --> Spawning: Level.start() → start_next_wave()<br/>(wave 1: no countdown)
  Spawning --> Countdown: all open spawners emitted spawning_complete<br/>→ delay step down, end_current_wave():<br/>plan next (wave_planned), WaveTimer 12 s
  Countdown --> Spawning: WaveTimer timeout
  Countdown --> Spawning: call_next_wave()<br/>pays floori(time_left × 0.5), early_called
  Spawning --> Done: last wave sent and spawning complete
  Done --> Won: total alive == 0 → all_waves_done → Level.won (guarded by _finished)
  Spawning --> Lost: enemy reaches base → PlayerBase.destroyed
  Countdown --> Lost
  Done --> Lost
```

Waves overlap: the countdown starts when spawning *completes*, not when the wave is cleared.

### `start_next_wave()` in detail

1. Use the stored `_next_plan`. Re-plan with a `push_warning` if its index or open-spawner count no longer matches.
2. For each open spawner *k*: `set_active(true)`, record its template in `_last_templates[spawner]`, then `start_spawning(plan.enemies, delay × n × template.spawn_delay_multiplier, delay × (k + 1))`. The staggered first delay makes the spawners alternate.
3. `wave_index += 1`, then emit `wave_started`. Level redraws the previews (a newly opened spawner gets its line), and HUD shows the banner.

`spawn_delay` starts at 1.0 and drops by 0.1 after each wave whose spawning completed, down to a floor of 0.3 (reached after wave 7).

## Planning a wave (`WaveConfig.generate`, wave_config.gd:46)

```mermaid
flowchart TD
  rng["rng = make_rng(wave_seed, index)<br/>= hash([wave_seed, index])"] --> boss
  boss{"boss wave?<br/>index % 10 == 9 or last wave"} -- yes --> bslot[pick one spawner for boss_template<br/>others get normal_template]
  boss -- no --> tpl["each spawner draws a template by weight<br/>among templates with first_wave <= index;<br/>never the same special twice in a row"]
  bslot --> share
  tpl --> share["budget = (4 + 2i) × 1.08^i × difficulty<br/>share = budget / open spawners"]
  share --> fill["per spawner: _fill(share × template.budget_multiplier)"]
  fill --> plan["WavePlan { index, budget, spent,<br/>spawners: [SpawnerPlan{template, budget, spent, enemies}] }"]
```

The rng draw order is fixed: boss slot, then templates per spawner, then fills per spawner. A wave therefore depends on the seed, its index, the open-spawner count, and each spawner's previous template.

### The budget fill (`_fill`, wave_config.gd:98-148)

```mermaid
flowchart TD
  s[remaining = spawner budget] --> e["eligible = entries where<br/>first_wave <= index<br/>cost <= remaining<br/>capped? spent_by_entry + cost <= max_share × budget<br/>weight × template multiplier > 0"]
  e --> any{any eligible?}
  any -- no --> done[return list]
  any -- yes --> pick["weighted pick: rng.randf() × total weight"]
  pick --> add[append scene, remaining -= cost] --> e
```

`basic` costs 1 and is uncapped, so a spawner ends within 1 point of its budget whenever basic is eligible.

Capped enemies only appear once `cost ≤ max_share × spawner budget`. With several spawners the budget is split, so they can appear later than their `first_wave`.

### Templates (`core/managers/wave/templates/`)

| id | special | weight | effect |
|---|---|---|---|
| normal | no | 3 | default |
| swarm | yes, from wave idx 2 | | basic & fast ×3, others ×0.3, delay ×0.5 |
| tank | yes, from idx 2 | | heavy & armored ×3, basic ×0.3, delay ×1.2 |
| rush | yes, from idx 2 | | fast & dasher ×3, delay ×0.7 |
| boss | (only via boss slot) | 0 | tank weights, budget ×1.5, delay ×1.2 (placeholder until phase 4) |

## Life of an enemy

```mermaid
sequenceDiagram
  participant S as EnemySpawner
  participant P as Pathfinding (child)
  participant E as Enemy
  participant PF as PathfindingManager
  participant B as PlayerBase
  participant CM as CurrencyManager

  S->>E: _create_enemy(): instantiate, position, split_generation,<br/>target, connect died/armor_deflected/tree_exiting, alive++
  S->>E: add_child (deferred for death children)
  P->>PF: _ready: get_valid_path_world → path, snap facing
  E->>E: _ready: hp = max, group "enemies", flash material, spawn tween
  loop _physics_process
    E->>P: move(delta, knockback) → follow path, rotate_toward, move_and_slide
  end
  PF-->>P: grid_changed → recalculate_path (from current cell)
  alt killed
    E->>E: die(): emit died (once)
    E-->>S: died → CM.earn(coins), enemy_died, spawn death children (deferred)
    E->>E: stop pathing, layer 0, leave group, release effects, fade 0.25 s, free
    E-->>S: tree_exiting → alive--
  else reaches base
    E->>B: body_entered → take_damage(1) → destroyed → lost
    Note over B: base frees the enemy: no died, no coins, no split
  end
```

Splitting (`EnemySpawner._spawn_death_children`): children are counted alive *immediately*, then added deferred at the parent's position plus 2-6 px. The alive count therefore never touches 0 between parent and children, and the win cannot fire early. Depth is capped at `MAX_SPLIT_DEPTH` 3, and a scene that spawns itself is refused.

## Enemy variants (placeholders)

| Variant | hp | speed | armor | coins | wave cost | weight | max_share | first banner wave | Extra |
|---|---|---|---|---|---|---|---|---|---|
| basic | 3 | 50 | 0 | 1 | 1 | 3 | 1 | 1 | |
| dasher | 2 | 60 | 0 | 1 | 2 | 2 | 0.4 | 4 | `Dash` ×3 for 0.5 s every 2.5 s |
| fast | 1 | 100 | 0 | 1 | 1 | 2 | 0.4 | 6 | |
| armored | 6 | 40 | 0.6 | 2 | 5 | 1 | 0.4 | 7 | `DamageSmoke` |
| regenerator | 8 | 45 | 0 | 3 | 4 | 1 | 0.4 | 9 | `Regeneration` 2 hp/s after 1.5 s; smoke |
| heavy | 10 | 30 | 0 | 3 | 4 | 1 | 0.4 | 11 | smoke |
| splitter | 12 | 35 | 0 | 3 | 6 | 1 | 0.3 | 12 | 3× `mini` on death; smoke |
| mini | 1 | 90 | 0 | 1 | never in waves | | | | |

Enemy components: `Health` (Resource, local to scene), `Pathfinding` (Node, reads `owner`), `EnemyStats`/`Drops` (Resources), and optional ability or effect nodes. Speed factors and damage factors are dictionaries keyed by source (`&"dash"`, `&"debug"`), and their values are multiplied.

## Pathfinding

`PathfindingManager` keeps one `AStarGrid2D` over the tile layer's used rect. It uses `DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES`, and cells with `movement_cost == 255` are solid. There are no weights: roads are cosmetic, and enemies take the shortest path.

- `set_cell_solid()` emits `grid_changed`. Every enemy re-paths, and the preview lines are redrawn.
- `would_block_path(cell, start, end)` temporarily makes the cell solid and asks for a path. `Level.would_block_path` asks this for **every** spawner, open or not.
