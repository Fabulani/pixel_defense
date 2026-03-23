class_name Tower extends Node2D

## Relay for internal signal. Indicate that a projectile should be spawned.
signal shot(data: ProjectileData)

@export var stats: TowerStats  ## Data container for tower stats
@export var _turret: TurretComponent  ## Component for detection, aiming, and firing

func _ready():
	_turret.shot.connect(_on_shot)
	_turret.configure(stats)
	add_to_group("towers")	
	
## Create a ProjectileData object using TowerStats
func _package_projectile(origin: Vector2, angle: float) -> ProjectileData:
	var projectile_data := ProjectileData.new(
		origin,
		angle,
		stats.damage,
		stats.penetration
	)
	return projectile_data
	
## Signal relay that packages projectile data
func _on_shot(origin: Vector2, angle: float) -> void:
	var projectile_data: ProjectileData = _package_projectile(origin, angle)
	shot.emit(projectile_data)
