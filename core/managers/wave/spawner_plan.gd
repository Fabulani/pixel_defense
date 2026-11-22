class_name SpawnerPlan extends RefCounted
## What one open spawner spawns in a wave.

## Template this spawner drew.
var template: WaveTemplate
## Budget of this spawner (share of the wave budget x template multiplier).
var budget: float = 0.0
## Threat points actually spent.
var spent: int = 0
## Scenes to spawn, in spawn order.
var enemies: Array[PackedScene] = []
