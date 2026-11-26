# `Bullet` crashes if it enters the tree without `setup()`

- **Type:** robustness
- **Priority:** low
- **Area:** projectiles

## Description
`Bullet._ready()` returns early when `_data` is null, but `_physics_process()` still dereferences `_data`, so the bullet crashes instead of failing cleanly. Today only `ProjectileManager.create_bullet()` makes bullets, and it always calls `setup()`.

## Fix
`push_error` and `queue_free()` in `_ready()` when `_data` is null, or disable physics processing.
