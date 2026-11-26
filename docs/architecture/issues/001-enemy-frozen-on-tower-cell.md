# Enemy freezes forever when a tower is built on its cell (can soft-lock the win)

- **Type:** bug
- **Priority:** high
- **Area:** pathfinding, building
- **Status:** found by reading the code (verified line by line), not reproduced in game yet

## Description
You can build a tower on a cell an enemy is standing on: `Level.would_block_path()` only checks that every spawner can still reach the base, so occupied cells pass.

What happens next:
1. `PathfindingManager.set_cell_solid()` emits `grid_changed`.
2. The enemy's `Pathfinding.recalculate_path()` asks A* for a path that starts at its own cell, which is now solid.
3. `AStarGrid2D.get_point_path` returns an empty path when its start point is solid.
4. `_follow_path()` sets the velocity to 0 for as long as the path is empty, which is forever.

The enemy stays alive, so the alive count never reaches 0 and `all_waves_done` (the win) can never fire after the last wave. Knockback can also push an enemy onto a tower cell, because enemies have `collision_mask = 0`.

## Repro (expected)
Let an enemy walk onto an empty buildable cell, then build a tower there (tap twice). The enemy stops moving.

## Files
- `entities/enemies/components/pathfinding/pathfinding.gd` (`recalculate_path`, `_follow_path`)
- `core/managers/pathfinding/pathfinding_manager.gd`
- `levels/level.gd` (`would_block_path`)

## Ideas
- Re-path from the nearest walkable cell when the current one is solid.
- Or reuse the roadmap's "walled-in enemies" plan (also an open item in CLAUDE.md): when a tower is built on enemies, spread them to the closest free cells; if the map still blocks them, move them toward the base at half speed.
- Or forbid building on cells with an enemy in them. This one is simple, but it changes the feel.

## Done when
An enemy on a cell that turns solid keeps moving to the base, and the last wave can still be won.
