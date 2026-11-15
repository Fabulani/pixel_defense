class_name WaveEnemy extends Resource
## An enemy type that can appear in a wave, replacing part of the default enemy slots.

## Scene to spawn.
@export var scene: PackedScene
## First wave index (as passed to WaveConfig.generate) at which this enemy appears.
@export var first_wave: int = 0
## Fraction of the wave's slots that are re-rolled to this enemy.
@export_range(0.0, 1.0) var share: float = 0.0
