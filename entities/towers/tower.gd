class_name Tower extends Node2D

## Relay for internal signal. Indicate that a projectile should be spawned.
signal shot(pos: Vector2, direction: float)

@export var stats: TowerStats  ## Data container for tower stats
@export var _turret: TurretComponent  ## Component for detection, aiming, and firing

func _ready():
	_turret.shot.connect(_on_shot)
	_turret.configure(stats)
	add_to_group("towers")	
	
## Signal relay.
func _on_shot(pos: Vector2, direction: float) -> void:
	shot.emit(pos, direction)
