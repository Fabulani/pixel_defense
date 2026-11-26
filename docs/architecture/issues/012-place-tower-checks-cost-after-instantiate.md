# `place_tower()` instantiates the tower before checking coins

- **Type:** cleanup
- **Priority:** low
- **Area:** building

## Description
`BuildingManager.place_tower()` instantiates the tower scene, which runs its init, just to read `stats.cost`, and frees it again if the player can't pay. `TowerPreview` already `preload`s `tower_stats.tres`. Read the cost from a preloaded `TowerStats` before instantiating.
