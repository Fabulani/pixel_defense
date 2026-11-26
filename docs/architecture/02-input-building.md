# 2. Input, building, selecting, upgrading

## Input pipeline

Both input paths are always connected. The split is by *meaning*: the camera consumes pan and zoom, and `InputController` consumes tap and click.

```mermaid
flowchart LR
  ev[InputEvent] --> GUI{"over a GUI Control?<br/>(TowerMenu button, HUD panel,<br/>NextWaveButton)"}
  GUI -- yes --> eaten[consumed by GUI,<br/>never reaches _unhandled_input]
  GUI -- no --> UI["_unhandled_input"]
  UI --> TC[TouchControls]
  UI --> KBM["KBMControls<br/>(drops DEVICE_ID_EMULATION mouse events)"]
  TC -- "pan_changed, pinch_started,<br/>pinch_changed" --> Cam[PanningCamera]
  KBM -- "mouse_panned, zoomed" --> Cam
  Cam --> SD["SmoothDamp<br/>(zoom_goal, position_goal, spring)"]
  SD --> camT[Camera2D position / zoom]
  CS[CameraShake] --> camO[Camera2D offset only]
  TC -- "tapped(pos)" --> IC[InputController]
  KBM -- "clicked(pos)" --> IC
  IC -- "screen to canvas to tile cell" --> cell((cell))
```

- **Tap** (`touch_controls.gd`): fires when the *last* finger lifts, as long as the touch stayed under 3 mm of travel (converted to viewport units per gesture), never had a second finger, and was not cancelled (focus loss clears all fingers).
- **Click** (`kbm_controls.gd:70`): press and release within 8 px with no panning.
- Mouse-wheel zoom is read with `Input.is_action_just_pressed` in `_process`, so it is **not** blocked by the GUI (see review findings).

## Decision tree on a cell (`InputController._handle_cell_input`, :40)

```mermaid
flowchart TD
  start[tap / click on cell] --> en{input_enabled?}
  en -- no --> x[ignore]
  en -- yes --> tw{tower on cell?}
  tw -- yes --> s1[cancel_preview] --> s2[emit tower_selected]
  tw -- no --> d[emit tower_deselected]
  d --> same{"cell == _preview_cell?<br/>(second tap)"}
  same -- yes --> br[emit build_requested]
  same -- no --> valid{"check_valid_tower_placement:<br/>unused AND buildable AND<br/>not would_block_path (every spawner)"}
  valid -- no --> inv[cancel_preview + placement_invalid<br/>→ red flash]
  valid -- yes --> ghost[_preview_cell = cell<br/>TowerPreview.show_at: ghost + ring]
```

## Building (second tap)

```mermaid
sequenceDiagram
  participant IC as InputController
  participant BM as BuildingManager
  participant CM as CurrencyManager
  participant L as Level
  participant PF as PathfindingManager
  participant E as Enemies (Pathfinding)
  participant M as Main

  IC->>BM: build_requested(cell)
  BM->>BM: re-validate, instantiate Tower
  BM->>CM: spend(stats.cost)
  alt cannot afford
    BM->>BM: free tower
    BM-->>M: tower_placement_denied → flash
  else paid
    BM->>BM: position, add_child, total_spent, _towers[cell]
    BM-->>L: tower_built → register_tower
    L->>PF: set_cell_solid(cell, true)
    PF-->>E: grid_changed → recalculate_path()
    PF-->>L: grid_changed → redraw preview lines
    L->>L: projectile_manager.connect_tower(tower)
    BM-->>M: tower_built → play_placed, VFX, cancel_preview
  end
```

## Selecting, upgrading, selling

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Ghost: tap valid empty cell
  Ghost --> Ghost: tap another valid cell
  Ghost --> Idle: second tap (build) / invalid cell
  Idle --> Selected: tap tower
  Ghost --> Selected: tap tower (cancel_preview)
  Selected --> Selected: lvl+ / major (menu refresh, 300 ms guard)
  Selected --> Idle: sell / tap other cell (deselect)
  Selected --> Ghost: tap valid empty cell (deselect, then ghost)
  Idle --> Disabled: lost / won
  Selected --> Disabled: lost / won
  Ghost --> Disabled: lost / won
```

**TowerMenu** (`ui/tower_menu/tower_menu.gd`) only emits requests. `BuildingManager` does all coin and tower changes:

| Button | Shown when | BuildingManager call | Cost |
|---|---|---|---|
| `lvl+` | level < 4 (no major due) | `upgrade_tower` → `Tower.upgrade()` | `TowerStats.cost × next level` |
| 3 majors (cannon icon, tinted) | level == 4 | `apply_major_upgrade` → `Tower.apply_major()` | `major_cost` 50 |
| `sell` | always | `sell_tower` → refund `total_spent`, `tower_sold` → `Level.unregister_tower` | refund |

**Effective tower stats** (`Tower._apply_upgrades`, rebuilt from a copy, base `TowerStats` never mutated):

```
damage, fire rate, range = base × (1 + 0.1 × level) × major multiplier
turn speed             = base turn_speed × major turn_speed_multiplier   (no level bonus)
```

Then `TurretComponent.configure(effective)` sets the reload timer and detection radius. A pending shot is never delayed (`min(time_left, new period)`).
