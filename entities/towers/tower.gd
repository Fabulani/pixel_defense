class_name Tower extends Node2D

signal shot(pos: Vector2, direction: float)

@export var stats: TowerStats
@export var _turret: TurretComponent

func _ready():
	#_turret.target_acquired.connect(_on_target_acquired)
	_turret.shot.connect(_on_shot)
	add_to_group("towers")	
	
## Signal relay.
func _on_shot(pos: Vector2, direction: float) -> void:
	shot.emit(pos, direction)
