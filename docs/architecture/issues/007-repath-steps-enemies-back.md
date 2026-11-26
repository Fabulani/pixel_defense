# Enemies step back slightly every time a tower is built

- **Type:** bug (visual)
- **Priority:** low
- **Area:** pathfinding, enemies

## Description
`Pathfinding.recalculate_path()` sets `_path_index = 0`. Point 0 of the new path is the centre of the enemy's current cell, so every enemy that is past its cell centre turns around for a moment and walks back to it. Every tower built makes every enemy do this.

## Fix idea
After re-pathing, skip point 0 if the enemy is already within the cell, or if point 1 is closer than point 0 along the travel direction.

## Done when
Building a tower causes no visible backtracking in enemies that keep the same route.
