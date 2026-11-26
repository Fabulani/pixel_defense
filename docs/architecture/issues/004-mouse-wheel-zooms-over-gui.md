# The mouse wheel zooms the map while the pointer is over the GUI

- **Type:** bug
- **Priority:** medium
- **Area:** controls
- **Status:** seen in playtests

## Description
`KBMControls._process()` polls `Input.is_action_just_pressed("camera>zoom+/-")`. Polling `Input` ignores GUI consumption, so scrolling over the HUD panel, the tower menu or the debug menu still zooms the map.

## Files
- `core/controls/kbm/kbm_controls.gd` (`_process`, `_handle_scroll`)

## Fix idea
Handle the wheel through events in `_unhandled_input`, which the GUI consumes first: use `event.is_action_pressed(zoom_in_action)` on `InputEventMouseButton`. Keep a polling path only for the joystick axes. This also fixes 006.

## Done when
Scrolling over any `Control` does not zoom. Scrolling over the map still zooms toward the cursor.
