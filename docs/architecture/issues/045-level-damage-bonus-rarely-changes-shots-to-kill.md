# Level damage bonus rarely changes shots to kill

- **Type:** balance / design
- **Priority:** low
- **Area:** towers

## What happens

Upgrades 1 to 4 add +10 % damage per level (1.0 → 1.4). Enemy hp are small integers, so the number of shots a kill takes barely moves:

| Enemy (hp) | dmg 1.0 | 1.1 | 1.2 | 1.3 | 1.4 | 1.5 (major) |
|---|---|---|---|---|---|---|
| basic (3) | 3 | 3 | 3 | 3 | 3 | 2 |
| dasher (2) | 2 | 2 | 2 | 2 | 2 | 2 |
| fast (1) | 1 | 1 | 1 | 1 | 1 | 1 |

Against the enemies of the first 6 waves, the damage half of every level is wasted; only fire rate and range help. Against armored, regenerator, heavy and splitter, each step does count.

## Where

`entities/towers/tower.gd` `_apply_upgrades()`, `entities/towers/stats/tower_stats.tres`, enemy `*_stats.tres`.

## Ideas

- Part of the balance pass (issue 027): pick hp and damage values so each level crosses a threshold for some enemy.
- Or make levels raise one stat at a time, so each level has a visible effect.
- Or accept it: fire rate and range already make levels worth it.
