class_name ProjectileManager extends Node2D

## Emitted when a bullet was created.
signal bullet_fired(data: ProjectileData)
## Emitted when a bullet damaged a body.
signal bullet_hit(hit_position: Vector2, direction: Vector2, data: ProjectileData)

## Above towers and their level label (z_index 1), so bullets and trails are never hidden.
const _Z_INDEX: int = 2

@export var bullet_scene: PackedScene

func _ready() -> void:
	z_index = _Z_INDEX


func create_bullet(data: ProjectileData) -> void:
	var bullet: Bullet = bullet_scene.instantiate() as Bullet
	bullet.setup(data)
	bullet.hit.connect(_on_bullet_hit.bind(data))
	add_child(bullet)
	bullet_fired.emit(data)

func connect_tower(tower: Tower) -> void:
	tower.shot.connect(create_bullet)

func _on_bullet_hit(hit_position: Vector2, direction: Vector2, data: ProjectileData) -> void:
	bullet_hit.emit(hit_position, direction, data)
