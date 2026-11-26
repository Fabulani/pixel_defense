# Upgrades: rework stat calculation and on-hit effects

- **Type:** refactor / design
- **Priority:** low
- **Area:** towers

## Now

`Tower` keeps two copies of `TowerStats`: the base (`stats`, never mutated) and `_effective_stats`, a `duplicate()` rebuilt in `_apply_upgrades()` from base × (1 + 0.1 × level) × major multipliers. Every new stat or modifier means touching `_apply_upgrades()` and often `_package_projectile()` as well. Some values bypass the copy (knockback and the trail are applied in `_package_projectile()`, recoil goes straight to the turret). `MajorUpgrade` is a fixed list of multipliers, so a major cannot add a new behaviour (penetration, slow, splash) without new code in `Tower`.

## Wanted (author's note, 2026-11-26)

- One place that computes effective values from modifiers, without keeping and syncing two stat copies.
- Special effects on hit (slow, burn, splash, ...) applied by composition: small effect resources or component nodes, not new branches in `Tower` or `Bullet`.

## Pieces that already exist

- `Enemy.set_speed_factor(source, factor)` / `set_damage_factor(source, factor)`: per-source factors, so a slow is one factor with its own key and does not stack with itself.
- Runtime-attachable components (`Dash`, `Regeneration`: read `owner`, else the parent).
- `ProjectileData` already carries per-shot data from the tower to the bullet; an `effects` list would travel the same way and be applied in `Bullet._hit()`.

## Related

- 045 level damage bonus
- 027 balance pass
- GitHub #10 targeting priorities
