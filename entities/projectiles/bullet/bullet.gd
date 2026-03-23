class_name Bullet extends Node2D

var _hit_count := 0
var _direction: Vector2
var _data: ProjectileData

@onready var hitbox: Area2D = %Hitbox
@onready var lifetime_timer: Timer = %LifetimeTimer

func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)

## Setup the projectile. Must be called for it to function correctly.
func setup(data: ProjectileData) -> void:
	position = data.origin
	rotation = data.angle
	_direction = Vector2.DOWN.rotated(data.angle)
	_data = data
	
func _physics_process(delta: float) -> void:
	position += _direction * _data.speed * delta

func _hit(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	body.take_damage(_data.damage)
	_hit_count += 1

func _die() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_hit(body)
	if _hit_count >= _data.penetration:
		_die()

func _on_lifetime_timer_timeout() -> void:
	_die()
