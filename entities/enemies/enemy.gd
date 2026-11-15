class_name Enemy extends CharacterBody2D

signal died(enemy: Enemy)

@export var stats: EnemyStats
@export var drops: Drops
@export var pathfinding: Pathfinding
@export var health: Health
@export_group("Feel")
## Seconds the knockback takes to decay to zero.
@export var knockback_decay_time: float = 0.12
## Maximum knockback speed (px/s) after scaling; 3x a base hit (20 px/s).
@export var knockback_max_speed: float = 60.0
@export var flash_duration: float = 0.08
@export var death_duration: float = 0.25
@export var spawn_duration: float = 0.2

var _knockback: Vector2 = Vector2.ZERO
var _knockback_time_left: float = 0.0
var _is_dying: bool = false
var _base_scale: Vector2 = Vector2.ONE
var _tween: Tween

const _HIT_FLASH_SHADER: Shader = preload("res://core/vfx/hit_flash.gdshader")

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health.hp = stats.max_health
	health.depleted.connect(_on_health_depleted)
	add_to_group("enemies")
	var flash_material := ShaderMaterial.new()
	flash_material.shader = _HIT_FLASH_SHADER
	flash_material.set_shader_parameter("flash", 0.0)
	_sprite.material = flash_material
	_play_spawn_in()


func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	_knockback_time_left = maxf(0.0, _knockback_time_left - delta)
	pathfinding.move(_current_knockback())


## Apply damage to this enemy's health.
func take_damage(amount: float) -> void:
	if _is_dying:
		return
	Flash.play(_sprite, flash_duration)
	health.take_damage(amount)


## True once the enemy started dying; it can no longer be hurt or targeted.
func is_dying() -> bool:
	return _is_dying


## Set the world position this enemy walks towards.
func set_target_position(pos: Vector2) -> void:
	pathfinding.target_position = pos


## Push the enemy with a knockback [param impulse] (px/s), scaled by its stats' knockback_scale.
## Adds to a knockback still in progress, capped at [member knockback_max_speed].
func apply_knockback(impulse: Vector2) -> void:
	if _is_dying:
		return
	_knockback = (_current_knockback() + impulse * stats.knockback_scale).limit_length(knockback_max_speed)
	_knockback_time_left = knockback_decay_time


## Emit [signal died] once, stop moving, and fade out before freeing the enemy.
func die() -> void:
	if _is_dying:
		return
	_is_dying = true
	died.emit(self)
	pathfinding.active = false
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	remove_from_group("enemies")
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "modulate:a", 0.0, death_duration)
	_tween.tween_property(_sprite, "scale", _base_scale * 0.5, death_duration)
	_tween.chain().tween_callback(queue_free)


## Knockback velocity left right now: linear decay over [member knockback_decay_time].
func _current_knockback() -> Vector2:
	if knockback_decay_time <= 0.0:
		return Vector2.ZERO
	return _knockback * (_knockback_time_left / knockback_decay_time)


func _play_spawn_in() -> void:
	_base_scale = _sprite.scale
	_sprite.scale = _base_scale * 0.3
	_sprite.modulate.a = 0.0
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "scale", _base_scale, spawn_duration)
	_tween.tween_property(_sprite, "modulate:a", 1.0, spawn_duration)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _on_health_depleted() -> void:
	die()
