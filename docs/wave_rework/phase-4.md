# Phase 4: bosses (outline)

Blocked on the debug scene (`docs/ideas.md`, roadmap item 2 "postponed until the debug scene exists"). Outline only: the manager writes a full brief per sub-phase when it starts.

## Goal

Real bosses for the `boss` template (phase 2): one base boss + varieties, each variety an ability component.

## Outline

- **Base boss**: inherited scene of `entities/enemies/enemy.tscn` in `entities/enemies/boss/`, own `EnemyStats` / `Drops` / sprite (Kenney pack). Big HP, slow, `knockback_scale` low. Tell: bigger sprite; boss gets a health bar? (open question: health bars were rejected for normal enemies.)
- **Varieties** (each = component under `entities/enemies/components/abilities/`, reading its `Enemy` via `owner`, like `Regeneration` / `Dash`):
  - **Shielded**: big shield effect around it absorbing damage; the shield regenerates over time (like `Regeneration`). Once broken, it stops regenerating for good.
  - **Carrier**: keeps spawning fast + dasher enemies while alive, through `EnemySpawner._create_enemy()` (counted alive -> win cannot fire early).
  - **Stealther**: goes invisible every x seconds; while invisible it is untargetable (`TurretComponent` + `Bullet` ignore it, like dying enemies).
  - More later.
- `boss` template: boss entry (`WaveEnemy`, high cost) + escorts from the remaining budget; variety picked w/ the wave's seeded RNG.
- Sub-phases: 4a base boss + template wiring, 4b shielded, 4c carrier, 4d stealther. Each its own PR.

## Open questions (user)

- Boss health bar or other tell?
- Boss variety per boss wave: random, or fixed order (e.g. wave 10 shielded, wave 20 carrier)?
- Does a boss reaching the base end the run (as every enemy today) or cost more?
