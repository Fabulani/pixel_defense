# Remove unused API and dead code

- **Type:** cleanup
- **Priority:** low

## Items
- `TowerMenu.contains_screen_point()`: no callers.
- `PanningCamera.zoom_by()`: no callers.
- The `Tower.upgraded` signal: no listeners (`BuildingManager.tower_upgraded` is the one that's used).
- `SmoothDamp._smooth_damp()`: `target = current - change` is a no-op. It's a leftover from Unity's `maxSpeed` clamp; remove it or add a real `max_speed`.
- `TurretComponent`'s `ReloadTimer` `wait_time = 0.5` in the `.tscn` is a dummy that `configure()` always overwrites. Add a comment or set it from code.

Check `debug/` before removing anything. None of the above is used there today.
