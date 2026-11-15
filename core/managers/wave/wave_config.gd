class_name WaveConfig extends Resource
## Describes how waves are sized and which enemies they contain.

## Enemy count of wave 0, before the Fibonacci growth is added.
@export var base_enemy_count: int = 3
## Number of waves before the game is won.
@export var max_waves: int = 20
## Enemy that fills every slot not taken by a variant.
@export var default_enemy: PackedScene
## Variants applied in order; later variants may overwrite earlier ones.
@export var variants: Array[WaveEnemy] = []


## Builds the spawn list for the wave at [param index].
func generate(index: int) -> Array[PackedScene]:
	# Using Fibonacci sequence for enemy count for fun.
	var enemy_count: int = base_enemy_count + _fibonacci(index) * 3
	var wave: Array[PackedScene] = []
	wave.resize(enemy_count)
	wave.fill(default_enemy)

	for variant: WaveEnemy in variants:
		if index < variant.first_wave:
			continue
		var variant_count: int = ceili(enemy_count * variant.share)
		for i: int in range(variant_count):
			wave[randi() % enemy_count] = variant.scene

	return wave


## Calculates the nth Fibonacci number.
func _fibonacci(n: int) -> int:
	if n <= 0:
		return 0
	var a: int = 0
	var b: int = 1
	for i: int in range(n - 1):
		var temp: int = a + b
		a = b
		b = temp
	return b
