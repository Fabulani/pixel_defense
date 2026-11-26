# 3. Combat and game feel

## Turret loop (`entities/towers/turret/turret_component.gd`, `_process`)

```mermaid
flowchart TD
  P[_process] --> T{"_get_priority_target()<br/>(first live, non-dying body; issue #10)"}
  T -- none --> idle["after idle_delay: sweep ±idle_sweep_angle<br/>at 31.5°/s (visual only)"]
  T -- target --> lead["lead point = pos + path_velocity × dist / bullet_speed<br/>(1 iteration, knockback ignored)"]
  lead --> aim["rotate_toward(lead, turn_speed × delta)"]
  aim --> F{"_loaded AND firing_enabled AND<br/>ANY live target's lead point within aim_tolerance?"}
  F -- no --> P
  F -- yes --> fire["_fire(): shot(origin, angle), recoil,<br/>_loaded = false, ReloadTimer.start()"]
  RT[ReloadTimer timeout] --> ld[_loaded = true]
```

The reload timer starts only *after* a shot. The real fire rate is therefore slightly under `shots_per_second`, because it adds the time spent waiting to be aimed. This is on purpose.

## A shot, end to end

```mermaid
sequenceDiagram
  participant TC as TurretComponent
  participant T as Tower
  participant PM as ProjectileManager
  participant B as Bullet
  participant E as Enemy
  participant L as Level
  participant M as Main/VFX

  TC->>T: shot(origin, angle)
  T->>T: _package_projectile → ProjectileData<br/>(damage, penetration, knockback, texture, material, trail, color)
  T->>PM: shot(data) (connected in Level.register_tower)
  PM->>B: instantiate, setup(data), hit.connect(bind data), add_child
  PM-->>L: bullet_fired(data) → Main → play_muzzle
  loop _physics_process
    B->>B: move along angle
  end
  B->>E: body_entered → take_damage(damage), apply_knockback
  B-->>PM: hit(pos, dir) → bullet_hit → Level → Main → play_impact
  Note over B: dies after `penetration` hits or 3 s lifetime,<br/>its trail is handed to the parent to fade out
```

## Damage pipeline (`Enemy.take_damage`, enemy.gd:68)

```mermaid
flowchart LR
  hit[hit] --> z{hit <= 0?} -- yes --> no[nothing]
  z -- no --> ar["armor: max(hit - armor, hit × min_damage_share)"]
  ar --> f["× product of damage factors<br/>(per source; 0 = invulnerable)"]
  f --> fl["flash: steel blue if armor reduced it, else white"]
  fl --> sig["armor_deflected(pos) if reduced<br/>damaged(amount)"]
  sig --> h["Health.take_damage → changed"]
  h --> dep{hp <= 0?} -- yes --> die["Enemy.die()"]
```

`PlayerBase` uses the same damage-factor idea. God mode is the debug source `&"debug"` with factor 0.

## Game-feel layer

The rule is that effects are visual only and never change stats, timing or bullet origin.

| Trigger | Effect | Where |
|---|---|---|
| `bullet_fired` | muzzle burst | `VfxManager.play_muzzle` |
| `bullet_hit` | impact burst | `play_impact` |
| `enemy_died` | death burst + coin pop-up | `play_death`, `play_coin_popup` |
| `armor_deflected` | falling pixels (own cap 100) | `play_deflect` |
| `early_called` | coin pop-up at base | `play_coin_popup` |
| `tower_built` | burst + squash tween | `play_tower_built`, `Tower.play_placed` |
| `tower_upgraded` | burst + flash | `play_tower_upgraded` |
| base hit / loss | camera trauma 0.4 / 0.7 | `CameraShake` (offset only) |
| any hit | shader flash | `Flash.play` → `flash` uniform in `hit_flash` / `hue_swap` shaders |
| enemy state | smoke < 75 % hp, green `+` while healing, dash trail | `DamageSmoke`, `Regeneration`, `Dash` via `Enemy.attach_effect` |

All particles come from `VfxManager.make_particles()` (static factory, `GPUParticles2D`). Bursts are capped (`max_live_bursts`, `max_live_popups`, `max_live_deflects`) and freed on `finished` plus a safety timer.

**Hue swap** (`entities/towers/hue_swap.gdshader`): pixels with saturation above 0.5 get the major's `target_color` hue. This is why flashing with an overbright `modulate` is banned: it would feed the saturation test (and is lost on Web).
