class_name WaveEnemy extends Resource
## An enemy type that can be picked for a wave, paid for from the wave budget.

## Scene to spawn.
@export var scene: PackedScene
## First wave index (as passed to WaveConfig.generate) at which this enemy appears.
@export var first_wave: int = 0
## Threat points this enemy costs (> 0).
@export var cost: int = 1
## Weight of this enemy in the weighted pick.
@export var weight: float = 1.0
## Maximum fraction of the wave budget this entry may take; 1.0 means uncapped.
@export_range(0.0, 1.0) var max_share: float = 1.0
