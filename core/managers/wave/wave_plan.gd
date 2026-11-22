class_name WavePlan extends RefCounted
## The generated content of one wave.

## Wave index (0-based).
var index: int = 0
## Budget the wave was generated with.
var budget: float = 0.0
## Threat points actually spent.
var spent: int = 0
## Scenes to spawn, in spawn order.
var enemies: Array[PackedScene] = []
