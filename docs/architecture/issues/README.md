# Issue drafts

One file per issue, ready to become a GitHub issue: the first line is the title and the rest is the body. They come from the code review of 2026-11-26 (v0.0.2, commit `f2980f8`).

| # | Title | Type | Priority | Area |
|---|---|---|---|---|
| [001](001-enemy-frozen-on-tower-cell.md) | Enemy freezes forever when a tower is built on its cell | bug | high | pathfinding |
| [002](002-start-next-wave-stops-timer-early.md) | `start_next_wave()` stops the countdown before its early return | bug (latent) | low | waves |
| [003](003-upgrade-denied-flashes-wrong-cell.md) | No feedback when pressing an unaffordable upgrade (TowerMenu) | bug (playtest) | medium | UI |
| [004](004-mouse-wheel-zooms-over-gui.md) | Mouse wheel zooms the map over the GUI | bug (playtest) | medium | controls |
| [005](005-camera-has-no-pan-limit.md) | Camera can pan off the map forever | bug (playtest) | medium | controls |
| [006](006-fast-scroll-loses-zoom-steps.md) | Fast wheel scrolling loses zoom steps | bug | low | controls |
| [007](007-repath-steps-enemies-back.md) | Enemies step back on every tower build | bug (visual) | low | pathfinding |
| [008](008-spawn-delay-multiplier-open-count.md) | `set_spawn_delay_multiplier()` uses the wrong open count | bug (debug) | low | waves |
| [009](009-controls-architecture-refactor.md) | Controls: explicit classifier / consumer / output layers | refactor | low | controls |
| [010](010-unify-cell-world-conversion.md) | Unify cell ↔ world conversions | refactor | medium | core |
| [011](011-bullet-without-setup-crashes.md) | `Bullet` crashes without `setup()` | robustness | low | projectiles |
| [012](012-place-tower-checks-cost-after-instantiate.md) | `place_tower()` instantiates before checking coins | cleanup | low | building |
| [013](013-release-workflow-fragile-sed.md) | Release workflow depends on exact preset text | robustness | medium | CI |
| [014](014-fallback-map-not-validated.md) | Fallback map not validated, breaks the edge margin | robustness | low | map gen |
| [015](015-pathfinding-runtime-attach.md) | `Pathfinding` cannot be attached at runtime | consistency | low | enemies |
| [016](016-mobile-display-handler-no-effect.md) | `MobileDisplayHandler` has no visible effect | bug | low | mobile |
| [017](017-extra-wave-spawner-pacing.md) | Debug extra wave does not match real pacing | debug | low | debug |
| [018](018-remove-unused-api-and-dead-code.md) | Remove unused API and dead code | cleanup | low | various |
| [019](019-claude-md-outdated.md) | CLAUDE.md outdated | docs | low | docs |
| [020](020-other-docs-out-of-date.md) | README, roadmap, ideas and comments out of date | docs | low | docs |

### From the CLAUDE.md open items (non-stale only)

| # | Title | Type | Priority | Area |
|---|---|---|---|---|
| [021](021-spawner-open-tell.md) | Spawner-open tell | feature | medium | UI |
| [022](022-mapgen-device-check-and-tuning.md) | Map generation: phone/Web check, tune `default_map.tres` | test / tuning | medium | map gen |
| [023](023-mapgen-performance-web-android.md) | Measure map generation time on Web and Android | performance | low | map gen |
| [024](024-seed-ui.md) | Seed UI: entry, replay, Web URL parameter | feature | medium | UI |
| [025](025-seed-engine-hash-stability.md) | Seeds depend on engine `hash()` | robustness | low | map gen, waves |
| [026](026-multitouch-menu-and-map.md) | Multi-touch across TowerMenu and map | bug | low | controls |
| [027](027-balance-pass.md) | Balance pass: enemies, waves, towers, economy | tuning | high | balance |
| [028](028-call-early-has-no-cap.md) | Calling the next wave early has no cap | design | medium | waves |
| [029](029-next-wave-button-double-press.md) | NextWaveButton double press leaks to the map | bug | low | UI |
| [030](030-towermenu-double-press-row-shrinks.md) | TowerMenu double press leaks when the row shrinks | bug | low | UI |
| [031](031-hud-panel-blocks-map.md) | HUD panel blocks building under it | bug / UX | low | UI |
| [032](032-device-and-web-test-pass.md) | Device and Web test pass | test | high | all |
| [033](033-particle-pooling.md) | Particles are never pooled | performance | low | VFX |
| [034](034-sound.md) | Add sound | feature | medium | audio |
| [035](035-accessibility-flash-shake-settings.md) | Settings to reduce flashes and shake | accessibility | low | settings |
| [036](036-end-screen-freezes-dying-enemies.md) | Dying enemies freeze behind the end screen | polish | low | enemies |
| [037](037-base-hit-no-death-effect.md) | Enemies removed by the base get no death effect | polish | low | enemies |
| [038](038-waves-survived-counts-started.md) | `waves_survived` counts waves started | bug | low | UI |
| [039](039-debug-menu-known-issues.md) | Debug menu known issues | debug | low | debug |
| [040](040-turret-aim-cone-fast-close-enemies.md) | Slow cannons may never hit fast close enemies | design | low | towers |

Folded into existing drafts: "walled-in enemies" → 001; "fallback map never hit" → 014.

Left out on purpose:
- **Stale:** `console_wrapper_icon` (now `""`); "multiple spawners not playtested" (roadmap marks the playtest done); "special waves have no banner yet" (phase 3 is done); "re-save `EnemySpawner2` / `%SeedLabel` in the editor" (both nodes now carry an editor `unique_id`, so they were most likely re-saved; worth one glance).
- **Already GitHub issues:** targeting priorities (#10), obstacle-breaking enemy (#11).
- **Descriptions, not problems:** one base tower by design; `TurretComponent.configure()` timer behaviour; the slightly-under fire rate (kept on purpose); health bars rejected.

By design, not issues: a tap or click acts at the release position, and the first 3 mm of a one-finger drag don't pan.

