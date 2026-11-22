# Ideas

## Game direction and UX

- [x] **Remove the tower build button.** Go back to the previous way of building: tapping a floor cell shows the ghost, tapping the ghost builds the tower. The game has only one tower type, which is upgraded along different paths (majors).
- [ ] **Separate interface scale for mobile.** The mobile UI is too small for a touchscreen. Add a dedicated UI scale for mobile (HUD, tower menu, buttons).
- [x] **Smooth turning.** Enemies and tower cannons currently snap to their direction of movement / target. Rotate them smoothly toward it.
- [ ] **Glossary.** A screen listing enemy and tower types, their stats and what they do.
- [x] **Wave notification.** A short on-screen notice that disappears by itself and says which enemies come this wave and what is special about them, in a few words. Covered by wave rework phase 3 (`docs/wave_rework/phase-3.md`): banner names special waves only.
- [ ] **Debug scene.** A separate scene for testing individual features, towers and enemies in isolation (spawn a chosen enemy or tower on demand, free coins, no waves).
- [ ] **Map generation options.** A screen (from the start menu) where the player tunes the generated map to their liking: seed, map size, island size and coast roughness, number of spawners, lakes, trees, decoration, farms, road wiggle and lamp spacing. Each setting maps to a `MapGenConfig` export; keep a "default" reset and show the seed so a map can be shared and replayed.
- [ ] **Enemies spread out like a wave.** Enemies currently clump and only walk the shortest path from flag to base. Experiment: each enemy starts on the flag-to-base path but keeps its own independent path, so when it is pushed off the main path (knockback, crowding) it may take a different route instead of snapping back. Goal: no more big clumps; a wave should spread and expand across the map.
- [ ] **Turret turn slowdown after a shot.** For 1 s after firing, a turret turns at 25 % of its turn speed.
- [ ] **Allow building on farms.** Farmland cells should be buildable like grass.
- [ ] **Difficulty setting.** A difficulty choice that scales `WaveConfig.budget_growth` (and maybe `max_waves`). Belongs with the wave-settings / advanced settings screen.
- [ ] **Unique maps.** Hand-made maps playable next to generated ones. The old legacy map (still painted in `levels/level.tscn`, not playable since wave rework phase 0) becomes the first unique map. Needs its own plan: map selection, where unique maps live, spawner `first_wave` per map.
- [ ] **Boss varieties.** A base boss plus varieties: shielded (big shield effect that keeps regenerating like the regenerator; once broken, no more regen), carrier (keeps spawning fast / dasher enemies), stealther (goes invisible every x seconds, untargetable), more later. Planned as wave rework phase 4 (`docs/wave_rework/phase-4.md`).

## UI rework

- [ ] **Top bar.** A slim horizontal bar across the top of the screen: total coins on the left, current wave on the right.
- [ ] **Wave banner as a drop-down notification.** The banner drops from the top of the screen like a mobile notification. Title `Wave N`, subtitle `<special wave name>`, description `<enemy icon> <amount> <other enemy icon> <amount> ...` (one icon + count per enemy type in the wave).
- [ ] **Minimap.** A square minimap in the bottom right with a simplified view of the map: enemies are red dots, the player base a blue dot, built towers green dots, obstacles gray dots. Below the map: `<red dot> x <enemy count> left`.
- [ ] **Early-call toast.** The next-wave button becomes a toast in the bottom left: `Next wave`, second line `+<bonus><coin icon>`, and a progress bar along the top of the toast going from full to empty instead of the numeric countdown.

## Effects polish

- [ ] **Damage smoke.** More visible particles, gray colour, and spawned at random positions around the sprite instead of one point.
- [ ] **Dash trail.** The dash currently shows a few pixels that pop. Make it a straight, continuous trail behind the enemy.
- [ ] **Regeneration pluses.** The plus particles should be green, matching the regeneration flash.
- [ ] **Death effect at the base.** Enemies that reach the base are freed by `PlayerBase` with no death effect.
- [ ] **Fade behind the end screen.** Dying enemies freeze mid-fade behind the win/loss screen (the tree is paused); let them finish.
- [ ] **Knockback cap.** `Enemy.knockback_max_speed` (60) is reached by a single basic hit at `TowerStats.knockback` 60, so long_shot (x1.5) and big_boy (x2) are clipped and push no harder than a normal tower. Raise the cap together with the base value. Total shove is about 0.5 x speed x `knockback_decay_time`; the push follows the bullet direction.
- [ ] **Effect tuning by eye.** All game-feel values are first-pass: `@export` vars on `Enemy`, `Tower`, `TurretComponent`, `VfxManager`, `CameraShake`, `HUD`, plus `TowerStats.knockback` / `recoil` and the `MajorUpgrade` fields.
- [ ] **Phone check.** Coin pop-up and wave banner legibility on a phone screen.
- [ ] **Re-save hand-edited scenes.** `core/controls/panning_camera.tscn` and `ui/hud/hud.tscn` each have a node without `unique_id`; open and save them in the editor.

## Optimization pass

Android playtest notes: late waves with many enemies dropped to 14 fps, probably from too many particles. Most of the small particles are hard to notice and cost more than they give. Cut them:

- [ ] **Damage smoke.** Remove it from normal enemies. Replace it with the white hit flash turning a reddish hue when health is low. Keep smoke for bosses only.
- [ ] **Armor deflect particles.** Remove. Either find another tell (e.g. the steel-blue flash alone) or drop the effect entirely.
- [ ] **Dash trail.** Make it much cheaper, or remove it. The stretched sprite tell may be enough.
- [ ] **Regenerator.** It never heals in practice because of the `delay_after_hit` delay. Regenerate continuously whenever health is not full (drop the delay).
- [ ] **General rule.** Prefer cheap tells (flash, tint, sprite stretch) over per-enemy emitters. Keep particles only where they are clearly visible.

- [ ] Tune particle limits (`max_live_bursts`, `max_live_popups`, trail and emitter amounts) by stress testing: push waves, towers and effects until the frame rate drops, then set the caps below that.
- [ ] Profile on a real Android device in late waves (frame time, draw calls, particle count).
- [ ] Every bullet, muzzle flash and burst creates its own `GPUParticles2D` and `ParticleProcessMaterial`. Cache materials per effect kind and pool bursts / trails (the factory is `VfxManager.make_particles()`).
- [ ] Check `CPUParticles2D` vs `GPUParticles2D` on Web and mobile.
- [ ] Look for other per-frame allocations (tweens, `ProjectileData`, pop-up labels) once the profile points at them.
- [ ] Only spawn particle effects near the visible screen: skip one-shot bursts (impact, death, deflect, muzzle, coin pop-ups) whose position is outside the camera's visible rect plus a small margin, and pause continuous emitters (bullet trails, damage smoke, regen pluses, dash trails) while off-screen, e.g. with `VisibleOnScreenNotifier2D` or a rect check in `VfxManager`.
