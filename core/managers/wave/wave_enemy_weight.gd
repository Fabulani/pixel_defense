class_name WaveEnemyWeight extends Resource
## Pick weight multiplier of one enemy type inside a [WaveTemplate].

## Enemy scene this entry applies to (matched against [member WaveEnemy.scene]).
@export var scene: PackedScene
## Multiplies the enemy's pick weight; 0 excludes it.
@export var multiplier: float = 1.0
