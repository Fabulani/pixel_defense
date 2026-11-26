# 1. Overview: modules, scene tree, wiring

## Module map

```mermaid
flowchart LR
  subgraph autoloads["Autoloads (survive reload_current_scene)"]
    CM[CurrencyManager<br/>coins, spend/earn]
    PM[PathfindingManager<br/>AStarGrid2D, grid_changed]
    GD[GameData<br/>requested_seed, map_seed, grid_cell_size]
  end

  subgraph main["main/"]
    Main[Main<br/>composition root]
  end

  subgraph core["core/"]
    controls[controls/<br/>PanningCamera, Touch/KBMControls,<br/>SmoothDamp, CameraShake, InputController]
    managers[managers/<br/>building, currency, pathfinding,<br/>projectile, vfx, wave]
    vfxh[vfx/<br/>Flash + hit_flash.gdshader]
  end

  subgraph entities["entities/"]
    towers[towers/<br/>Tower, TurretComponent, TowerStats, MajorUpgrade]
    enemies[enemies/<br/>Enemy + components, 8 variants]
    proj[projectiles/<br/>Bullet, ProjectileData]
    spawners[spawners/<br/>EnemySpawner]
    bases[bases/<br/>PlayerBase]
  end

  subgraph levels["levels/"]
    Level[Level facade + TileMapLayer]
    gen[generation/<br/>MapGenConfig, MapGenerator,<br/>MapData, MapPainter]
  end

  ui[ui/<br/>HUD, TowerMenu, TowerPreview,<br/>HighlightTile, StartMenu, GameEndScreen]
  debug[debug/<br/>DebugMenu, debug builds only]
  tools[tools/print_waves<br/>headless CLI, not exported]

  Main --> Level & managers & controls & ui
  Main -. "load() if debug build" .-> debug
  debug -->|public API only| Level
  Level --> gen & spawners & bases & managers
  tools --> managers
```

## Scene tree at runtime

`main/main.tscn` is the main scene. Spawners are created at runtime by `Level._generate_map()`. The two spawners painted in `level.tscn` are freed.

```mermaid
flowchart TD
  Main --> Level
  Level --> TML[TileMapLayer<br/>embedded tileset: buildable, movement_cost]
  Level --> PPrev[PathfindingPreview Line2D<br/>+ one copy per extra spawner]
  Level --> PB[PlayerBase]
  Level --> SP["EnemySpawner × N (runtime)<br/>enemies are its children"]
  Level --> WM["WaveManager (+ WaveTimer)"]
  Level --> ProjM["ProjectileManager<br/>bullets are its children"]
  Main --> BM["BuildingManager<br/>towers are its children"]
  Main --> VFX[VfxManager]
  Main --> IC[InputController]
  Main --> TP[TowerPreview]
  Main --> HT[HighlightTile]
  Main --> TM[TowerMenu CanvasLayer]
  Main --> Cam[PanningCamera]
  Cam --> TC[TouchControls]
  Cam --> KBM[KBMControls]
  Cam --> CS[CameraShake]
  Main --> HUD & GES[GameEndScreen] & SM[StartMenu] & MDH[MobileDisplayHandler]
  Main -. debug build .-> DBG["DebugMenu (CanvasLayer 100)"]
```

The spawners are inserted *before* `WaveManager` in the tree (`level.gd:208`, `move_child(spawner, insert_at + i)`). Children are readied in tree order, so the spawners are ready before `WaveManager`, and `WaveManager` is ready before `Level`.

## Boot order

```mermaid
sequenceDiagram
  participant GD as GameData (autoload)
  participant L as Level._ready
  participant Gen as MapGenerator/Painter
  participant PF as PathfindingManager
  participant WM as WaveManager
  participant M as Main._ready
  participant SM as StartMenu

  GD->>GD: parse --seed= (requested_seed)
  Note over L: children are readied first, then Level
  L->>L: CurrencyManager.coins = 5
  L->>Gen: _generate_map(): pick seed, generate, paint
  L->>L: move PlayerBase, replace spawners
  L->>GD: map_seed = seed
  L->>PF: setup(tile_map_layer) (fresh AStarGrid2D)
  L->>WM: setup(spawners, map_seed)
  L->>L: connect relays, create path previews
  Note over M: Main is ready last (parent after children)
  M->>M: inject deps, connect all cross-scene signals
  M->>M: camera.fit_rect(level.get_map_rect())
  SM->>SM: paused = true (in its own _ready)
  SM-->>M: start_requested
  M->>L: input_enabled = true; level.start()
  L->>WM: start_next_wave() (wave 1, no countdown)
```

## The composition root: who listens to what

This is everything `Main._ready()` connects (`main/main.gd:20-71`).

```mermaid
flowchart LR
  subgraph Level
    L_wave_started[wave_started]
    L_wave_planned[wave_planned]
    L_countdown[countdown_changed]
    L_early[early_called]
    L_count[enemy_count_changed]
    L_fired[bullet_fired]
    L_hit[bullet_hit]
    L_died[enemy_died]
    L_defl[armor_deflected]
    L_base[base_damaged]
    L_lost[lost]
    L_won[won]
  end
  subgraph BuildingManager
    B_built[tower_built]
    B_up[tower_upgraded]
    B_sold[tower_sold]
    B_denied["tower_placement_denied<br/>upgrade_denied"]
  end
  subgraph InputController
    I_build[build_requested]
    I_inv[placement_invalid]
    I_sel[tower_selected]
    I_desel[tower_deselected]
  end
  subgraph TowerMenu
    T_up[upgrade_requested]
    T_maj[major_requested]
    T_sell[sell_requested]
  end

  L_wave_started --> HUD1["HUD.set_wave + show_wave_banner"]
  L_wave_planned --> HUD2[HUD.show_wave_plan]
  L_countdown --> HUD3[HUD.set_countdown]
  HUDn[HUD.next_wave_requested] --> Lcall[Level.call_next_wave]
  L_early --> V0[VFX coin popup at base]
  L_count --> HUD4[HUD.set_enemy_count]
  L_fired --> V1[VFX.play_muzzle]
  L_hit --> V2[VFX.play_impact]
  L_died --> V3[VFX.play_death + coin popup]
  L_defl --> V4[VFX.play_deflect]
  L_base --> Sh[camera.shake 0.4]
  L_lost --> Lose["shake 0.7, close UI,<br/>GameEndScreen.show_defeat"]
  L_won --> Win["close UI,<br/>GameEndScreen.show_victory"]

  I_build --> BMp[BuildingManager.place_tower]
  I_inv --> HTf[HighlightTile.flash_denied]
  B_denied --> HTf
  I_sel --> Sel["TowerMenu.show_for<br/>TowerPreview.show_range"]
  I_desel --> Desel["hide menu + ring<br/>(only if a tower was selected)"]
  T_up --> BMu[BuildingManager.upgrade_tower]
  T_maj --> BMm[BuildingManager.apply_major_upgrade]
  T_sell --> BMs[BuildingManager.sell_tower]
  B_built --> Reg[Level.register_tower]
  B_built --> Placed["Tower.play_placed, VFX,<br/>cancel_preview"]
  B_up --> Upd["VFX, TowerMenu.refresh,<br/>ring redraw"]
  B_sold --> Unreg["Level.unregister_tower,<br/>hide menu + ring"]
```

## Autoloads and reloads

F1, restart and the end screen all call `get_tree().reload_current_scene()`. The scene tree is rebuilt, but the three autoloads keep their state, so:

| Autoload | Kept across reload | Reset by |
|---|---|---|
| `CurrencyManager` | `coins` | `Level._ready()` sets 5 |
| `PathfindingManager` | `astar_grid`, signal connections from freed nodes drop automatically | `setup()` builds a new `AStarGrid2D` |
| `GameData` | `requested_seed` (on purpose: restart replays the same map when a seed was given), `map_seed`, `grid_cell_size` | `map_seed` is rewritten every `Level._ready()` |

The debug menu's `debug_state.gd` uses `static var` for the same reason: its toggles survive reloads.

## Pause model

| Thing | `process_mode` | Why |
|---|---|---|
| `StartMenu`, `GameEndScreen` | pause the tree | menus |
| `PanningCamera` (+ Touch/KBM), `CameraShake` | ALWAYS, real-time delta | pan and zoom on menus and while paused |
| `TowerMenu`, `HighlightTile` | ALWAYS | building and selecting while *game*-paused is a feature |
| `VfxManager` | ALWAYS | effects finish behind the end screen |
| `InputController` | gated by `input_enabled`, not by pause | the menus block map taps, a game pause does not |
| `DebugMenu` | ALWAYS; its `ExtraWaveSpawner` is PAUSABLE | |
