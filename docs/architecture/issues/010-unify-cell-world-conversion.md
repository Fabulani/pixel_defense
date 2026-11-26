# Unify cell ↔ world conversions

- **Type:** refactor / robustness
- **Priority:** medium
- **Area:** core

## Description
There are four different conversions between cells and world positions:
- `InputController`: canvas inverse → `tile_map_layer.to_local` → `local_to_map`.
- `TowerPreview`: `map_to_local` → `to_global`.
- `BuildingManager.place_tower`: `cell × GameData.grid_cell_size + half`.
- `HighlightTile`: `floor(mouse / cell_size)`. `PathfindingManager.world_to_cell` works the same way.

`Bullet.setup()` also writes a global origin into the local `position`.

They only agree because `Level` and `TileMapLayer` sit at the origin with no transform and no scale. Moving or scaling the level would break placement, highlighting and bullets in different ways.

## Fix
Add a single pair, `Level.cell_to_world(cell)` / `world_to_cell(pos)` (based on the `TileMapLayer`), use it everywhere, and set the bullet's `global_position`.
