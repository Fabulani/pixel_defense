class_name Bullet extends Area2D

@export var stats: ProjectileStats

var direction: Vector2
var _hit := false

func setup(pos: Vector2, angle: float) -> void:
	position = pos
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	
func _process(_delta: float) -> void:
	position += direction * stats.speed * _delta

func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body is EnemyEntity:
		_hit = true
		body.take_damage(stats.damage)
		queue_free()
		
func _on_lifetime_timer_timeout() -> void:
	queue_free()
