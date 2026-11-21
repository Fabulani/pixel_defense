class_name Enemy extends CharacterBody2D

signal died(enemy: Enemy)
## Emitted for every hit with the damage left after armor, always before the hit is applied to
## health, so it comes before [signal died] on the killing hit.
signal damaged(amount: float)
## Emitted when armor reduced a hit, with the enemy's world position.
signal armor_deflected(hit_position: Vector2)

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
## How many death spawns deep this enemy is: 0 for queue spawns, parent + 1 for death spawns.
var split_generation: int = 0

var _knockback: Vector2 = Vector2.ZERO
var _knockback_time_left: float = 0.0
var _is_dying: bool = false
var _base_scale: Vector2 = Vector2.ONE
var _tween: Tween
var _speed_factors: Dictionary[StringName, float] = {}
var _spawn_done: bool = false
var _stretch: float = 1.0
var _attached_effects: Array[GPUParticles2D] = []

const _HIT_FLASH_SHADER: Shader = preload("res://core/vfx/hit_flash.gdshader")
## Flash colour of a hit that armor reduced.
const _ARMOR_FLASH_COLOR: Color = Color(0.55, 0.7, 0.9)

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


func _process(_delta: float) -> void:
	for effect: GPUParticles2D in _attached_effects:
		if is_instance_valid(effect):
			effect.global_position = global_position


func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	_knockback_time_left = maxf(0.0, _knockback_time_left - delta)
	pathfinding.move(delta, _current_knockback())


## Apply damage to this enemy's health.
func take_damage(amount: float) -> void:
	if _is_dying or amount <= 0.0:
		return
	var flash_color: Color = Color.WHITE
	var deflected: bool = false
	if stats.armor > 0.0:
		var reduced: float = maxf(amount - stats.armor, amount * stats.min_damage_share)
		if reduced < amount:
			flash_color = _ARMOR_FLASH_COLOR
			deflected = true
		amount = reduced
	Flash.play(_sprite, flash_duration, flash_color)
	if deflected:
		armor_deflected.emit(global_position)
	damaged.emit(amount)
	health.take_damage(amount)


## Restore hp up to [member EnemyStats.max_health]. Does nothing while dying.
func heal(amount: float) -> void:
	if _is_dying:
		return
	health.heal(amount, float(stats.max_health))


## Current movement speed (px/s): stats speed times the product of all speed factors.
func get_speed() -> float:
	var speed: float = stats.speed
	for factor: float in _speed_factors.values():
		speed *= factor
	return speed


## Set the speed factor owned by [param source] (replaces that source's previous factor).
## Factors of different sources multiply, so a dash and a slow combine.
func set_speed_factor(source: StringName, factor: float) -> void:
	_speed_factors[source] = factor


## Remove the speed factor owned by [param source].
func clear_speed_factor(source: StringName) -> void:
	_speed_factors.erase(source)


## Flash the sprite with [param color] and fade back over [param duration] seconds.
func flash(color: Color, duration: float) -> void:
	if _is_dying:
		return
	Flash.play(_sprite, duration, color)


## Stretch the sprite along the travel direction by [param factor] (1.0 = normal).
## Applied only after the spawn-in tween and never while dying, so it cannot fight those tweens.
func set_stretch(factor: float) -> void:
	_stretch = factor
	_apply_stretch()


## Velocity from path following only (no knockback); ZERO when not moving along a path.
func get_path_velocity() -> Vector2:
	return pathfinding.path_velocity if pathfinding != null else Vector2.ZERO


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


## Attach a particle emitter that follows this enemy's position but not its rotation
## (it becomes top level). On [method die] it stops emitting, is handed to the enemy's parent
## and freed once its particles have faded.
func attach_effect(particles: GPUParticles2D) -> void:
	particles.top_level = true
	# Deferred: components call this from their _ready, while this node is still adding children.
	add_child.call_deferred(particles)
	particles.position = global_position
	_attached_effects.append(particles)


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
	_release_effects()
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "modulate:a", 0.0, death_duration)
	_tween.tween_property(_sprite, "scale", _base_scale * 0.5, death_duration)
	_tween.chain().tween_callback(queue_free)


## Leave the attached emitters behind to fade out on their own, then free them.
func _release_effects() -> void:
	var host: Node = get_parent()
	for effect: GPUParticles2D in _attached_effects:
		if not is_instance_valid(effect):
			continue
		effect.emitting = false
		if not effect.is_inside_tree():
			# The deferred add never ran (enemy died in its first frame).
			effect.queue_free()
			continue
		if host == null or not host.is_inside_tree():
			continue
		effect.reparent(host, true)
		var tween: Tween = effect.create_tween()
		tween.tween_interval(effect.lifetime + 0.1)
		tween.tween_callback(effect.queue_free)
	_attached_effects.clear()


## Knockback velocity left right now: linear decay over [member knockback_decay_time].
func _current_knockback() -> Vector2:
	if knockback_decay_time <= 0.0:
		return Vector2.ZERO
	return _knockback * (_knockback_time_left / knockback_decay_time)


func _apply_stretch() -> void:
	if _is_dying or not _spawn_done:
		return
	# The sprite is rotated 90 degrees, so its local y axis is the travel axis.
	_sprite.scale = _base_scale * Vector2(1.0, _stretch)


func _on_spawn_finished() -> void:
	_spawn_done = true
	_apply_stretch()


func _play_spawn_in() -> void:
	_base_scale = _sprite.scale
	_sprite.scale = _base_scale * 0.3
	_sprite.modulate.a = 0.0
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "scale", _base_scale, spawn_duration)
	_tween.tween_property(_sprite, "modulate:a", 1.0, spawn_duration)
	_tween.chain().tween_callback(_on_spawn_finished)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _on_health_depleted() -> void:
	die()
