# `Pathfinding` cannot be attached at runtime (it uses `owner` only)

- **Type:** consistency
- **Priority:** low
- **Area:** enemies

## Description
`Pathfinding._ready()` uses `owner as Enemy`. `Dash` and `Regeneration` fall back to the parent, so they can be added at runtime (the debug menu does this). A `Pathfinding` created in code has no owner and would crash on `_entity.global_position`.

## Fix
Use the same "owner, else parent" lookup and `push_error` when it is not an `Enemy`.
