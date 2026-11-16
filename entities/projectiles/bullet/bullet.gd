class_name Bullet extends Node2D

## Emitted when the bullet damaged a body; never on lifetime end.
signal hit(hit_position: Vector2, direction: Vector2)

var _hit_count := 0
var _direction: Vector2
var _data: ProjectileData
var _trail: GPUParticles2D = null
var _dying: bool = false

@onready var hitbox: Area2D = %Hitbox
@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var _sprite: Sprite2D = %Sprite2D

func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	if _data == null:
		return
	if _data.texture != null:
		_sprite.texture = _data.texture
	if _data.material != null:
		_sprite.material = _data.material
	_build_trail()

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
	if body.has_method("is_dying") and body.is_dying():
		return
	body.take_damage(_data.damage)
	if body.has_method("apply_knockback"):
		body.apply_knockback(_direction * _data.knockback)
	hit.emit(global_position, _direction.normalized())
	_hit_count += 1

## Create the world-space particle trail from the projectile data.
func _build_trail() -> void:
	_trail = VfxManager.make_particles(_data.trail_amount, _data.trail_lifetime, _data.color, _data.trail_particle_scale)
	_trail.local_coords = false
	_trail.show_behind_parent = true
	var reach: float = _data.speed * _data.trail_lifetime + 16.0
	_trail.visibility_rect = Rect2(-reach, -reach, reach * 2.0, reach * 2.0)
	var trail_material: ParticleProcessMaterial = _trail.process_material as ParticleProcessMaterial
	trail_material.direction = Vector3(0.0, -1.0, 0.0)  # Opposite to travel (travel is local +Y)
	trail_material.spread = 12.0
	trail_material.initial_velocity_min = 4.0
	trail_material.initial_velocity_max = 20.0
	_trail.emitting = true
	add_child(_trail)
	move_child(_trail, 0)

## Leave the trail behind to fade out on its own, then free it.
func _release_trail() -> void:
	if not is_instance_valid(_trail):
		return
	var trail: GPUParticles2D = _trail
	_trail = null
	trail.emitting = false
	var host: Node = get_parent()
	if host == null:
		return
	trail.reparent(host, true)
	var tween: Tween = trail.create_tween()
	tween.tween_interval(trail.lifetime + 0.1)
	tween.tween_callback(trail.queue_free)

func _die() -> void:
	if _dying:
		return
	_dying = true
	_release_trail()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_hit(body)
	if _hit_count >= _data.penetration:
		_die()

func _on_lifetime_timer_timeout() -> void:
	_die()
