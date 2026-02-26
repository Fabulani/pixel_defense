class_name Bullet extends Area2D

@export var stats: ProjectileStats

var direction: Vector2

func setup(pos: Vector2, angle: float) -> void:
	position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	
func _process(_delta: float) -> void:
	position += direction * stats.speed * _delta


func _on_body_entered(body: Node2D) -> void:
	if body is EnemyEntity:
		body.hit(stats.damage)
		queue_free()
