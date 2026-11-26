# 7. Controls deep dive (`core/controls/`)

Rendered PNGs of these diagrams are in `img/controls-*.png`.

## 7.1 Wiring: raw events → meaning → consumers

<!-- controls-1-wiring -->
```mermaid
flowchart LR
  subgraph engine["Godot input"]
    st[InputEventScreenTouch]
    sd[InputEventScreenDrag]
    mb[InputEventMouseButton]
    mm[InputEventMouseMotion]
    act["InputMap actions<br/>camera>zoom± (wheel)<br/>camera>pan_* (WASD/arrows/stick)<br/>camera>pan (MMB/RMB)"]
  end

  gui{{"GUI Control under pointer?<br/>(TowerMenu, HUD, NextWaveButton)"}}
  st & sd & mb & mm --> gui
  gui -- "yes: consumed" --> stop((stop))
  gui -- "no: _unhandled_input" --> TC & KBM

  subgraph cam["PanningCamera (PROCESS_MODE_ALWAYS)"]
    TC["TouchControls<br/>gesture classifier"]
    KBM["KBMControls<br/>drops DEVICE_ID_EMULATION"]
    PC["PanningCamera<br/>writes goals only"]
    SD["SmoothDamp (Resource)<br/>critically damped springs"]
    CS["CameraShake<br/>writes offset only"]
  end

  act -- "polled in _process<br/>(bypasses GUI!)" --> KBM
  act -- "Input.get_vector in _process" --> PC

  TC -- "pan_changed(delta)" --> PC
  TC -- "pinch_started()<br/>pinch_changed(factor, anchor)" --> PC
  KBM -- "mouse_panned(delta)" --> PC
  KBM -- "zoomed(±1, anchor)" --> PC
  PC -- "position_goal, zoom_goal" --> SD
  SD -- "position, zoom" --> camera[(Camera2D)]
  CS -- "offset" --> camera

  TC -- "tapped(pos)" --> IC["InputController<br/>(gated by input_enabled)"]
  KBM -- "clicked(pos)" --> IC
  IC --> cell["screen → canvas⁻¹ → tile cell"]
```

Who owns which `Camera2D` property:

| Property | Written by | Never written by |
|---|---|---|
| `position`, `zoom` | `SmoothDamp` output, via `PanningCamera._apply_smooth_damp` (and `fit_rect` once) | input handlers, which only move *goals* |
| `offset` | `CameraShake` | everything else |

## 7.2 Touch gesture classifier (`TouchControls`)

<!-- controls-2-touch -->
```mermaid
stateDiagram-v2
  [*] --> Empty
  Empty --> OneFinger: press (first finger)<br/>_begin_gesture() sets tap_blocked = false,<br/>drag_active = false, threshold = 3 mm → viewport units
  OneFinger --> OneFinger: drag < threshold<br/>(accumulate path length, no pan)
  OneFinger --> Dragging: path length ≥ threshold<br/>drag_active = true, tap_blocked = true
  Dragging --> Dragging: drag → pan_changed(relative)
  OneFinger --> TwoFingers: second finger down<br/>tap_blocked = true, pinch_started
  Dragging --> TwoFingers: second finger down<br/>pinch_started
  TwoFingers --> TwoFingers: drag → pinch_changed(dist / start_dist, midpoint)<br/>+ pan_changed(relative × 0.5)
  TwoFingers --> Dragging: one finger lifts<br/>(drag_active stays true)
  OneFinger --> Empty: release, not blocked<br/>→ tapped(release pos), set_input_as_handled
  Dragging --> Empty: release (blocked, no tap)
  OneFinger --> Empty: canceled / focus lost<br/>(tap_blocked, fingers cleared)
```

Details worth knowing:
- The threshold is the *accumulated path length*, not the distance from the start, so a finger that wobbles out and back still counts as a drag.
- In a two-finger pan, each finger's drag event emits `relative × 0.5`. Summed over both fingers, that gives the movement of the midpoint.
- A pinch is re-armed whenever the finger count becomes exactly two. `PanningCamera` stores `_pinch_start_zoom = zoom.x` (the *current* zoom, not the goal), and the zoom goal becomes `start × factor`, clamped.
- A finger whose press was consumed by the GUI is unknown to `_touch_points`. Its drags are ignored and its release can never tap (`known == false`).

## 7.3 Mouse click vs pan (`KBMControls`)

<!-- controls-3-mouse -->
```mermaid
flowchart TD
  ev[mouse event] --> em{"device == EMULATION?<br/>(Godot's mouse copy of a touch)"}
  em -- yes --> drop[ignore]
  em -- no --> kind{event type}
  kind -- "LMB press" --> p["left_pressed = true<br/>click_valid = not pan_active<br/>press_position = pos"]
  kind -- "motion" --> m{"left_pressed and<br/>(pan_active or moved > 8 px)?"}
  m -- yes --> inv[click_valid = false]
  m --> pa{pan_active?}
  pa -- "yes (MMB/RMB held)" --> mp["mouse_panned(relative)"]
  kind -- "LMB release" --> r{"click_valid and<br/>moved ≤ 8 px and<br/>not pan_active?"}
  r -- yes --> clk["clicked(pos) + set_input_as_handled"]
  r -- no --> none[no click]
  kind -- "wheel (only if zoom actions missing)" --> fz["zoomed(±1, pos)"]
  proc["_process: Input.is_action_just_pressed(camera>zoom±)"] --> z["zoomed(±1, mouse pos)"]
```

## 7.4 One camera frame (`PanningCamera._process`)

<!-- controls-4-frame -->
```mermaid
sequenceDiagram
  participant P as PanningCamera._process
  participant SD as SmoothDamp
  participant C as Camera2D

  Note over P: real_delta = delta / Engine.time_scale
  P->>SD: keyboard/stick: position_goal += dir × pan_speed / zoom × dt
  Note over P: pre = world point under _anchor_viewport_position
  P->>SD: smooth_zoom(dt): spring zoom toward zoom_goal
  SD-->>C: zoom = damped zoom
  Note over P: post = world point under the same screen point (new zoom)
  P->>SD: smooth_pan(dt, pre - post)
  Note over SD: shift BOTH position_goal and current pan by the offset,<br/>so the anchor point stays fixed on screen (zoom to cursor)
  SD-->>C: position = damped position
```

The spring (`_smooth_damp`) is the classic *Game Programming Gems 4* critically damped spring, the same algorithm as Unity's `SmoothDamp`. It uses `omega = 2 / (smooth_time / 2)` and a polynomial approximation of `exp(-x)`, and clamps per axis so it never overshoots the goal.

The zoom steps are symmetric: zooming in multiplies by `1 / 0.9` and zooming out by `0.9`, so one step in and one out returns exactly to the start.

## 7.5 Findings in the controls code

- **The mouse wheel zooms over the GUI** (seen in playtests, issue 004). Zoom is polled with `Input.is_action_just_pressed` in `_process`, which runs regardless of the GUI. Scrolling over the HUD or the tower menu zooms the map.
- **Fast scrolling loses steps** (issue 006). `just_pressed` is true once per frame, so several wheel ticks within one frame zoom by only one step. An `if`/`elif` also means zoom-in wins if both happen in the same frame.
- **There is no pan limit** (seen in playtests, issue 005). `fit_rect()` limits zoom out (`min_zoom`), but `position_goal` is never clamped, so the camera can drift off the island forever.
- **`_smooth_damp` has a no-op line.** `target = current - change` is a no-op, since `change = current - target`. In Unity this line exists to apply a `maxSpeed` clamp, which this version doesn't have.
- **`zoom_by()` is unused** (also listed in the review findings).
- *By design:* **a tap fires at the *release* position.** A click does the same. That's consistent, but it means a touch that drifted almost 3 mm acts on the cell under the finger at release.
- *By design:* **the drag dead zone is swallowed.** The first 3 mm of a one-finger drag are not panned, so the map starts moving a little behind the finger. This is probably intended, since it prevents jitter.
