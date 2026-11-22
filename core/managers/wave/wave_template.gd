class_name WaveTemplate extends Resource
## Describes the flavour of one spawner's share of a wave. A modifier wave is just another template.

## Identifier, also the file name.
@export var id: StringName = &""
## Player-facing name (special waves only).
@export var display_name: String = ""
## One-line player-facing description.
@export var description: String = ""
## Normal waves have no name on the banner.
@export var is_special: bool = false
## First wave index (0-based) at which this template can be drawn.
@export var first_wave: int = 0
## Chance weight of the template draw.
@export var weight: float = 1.0
## Multiplies the spawner's share of the wave budget.
@export var budget_multiplier: float = 1.0
## Multiplies the spawn delay of the spawner.
@export var spawn_delay_multiplier: float = 1.0
## Per enemy weight multipliers.
@export var enemy_weights: Array[WaveEnemyWeight] = []
## Weight multiplier of enemies not listed in [member enemy_weights].
@export var other_multiplier: float = 1.0


## Multiplier for [param scene]: its listed value, else [member other_multiplier].
func get_multiplier(scene: PackedScene) -> float:
	for entry: WaveEnemyWeight in enemy_weights:
		if entry != null and entry.scene == scene:
			return entry.multiplier
	return other_multiplier
