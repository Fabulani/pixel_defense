## Periodically multiplies its [Enemy]'s speed for a short burst.
##
## Reads the enemy through [code]owner[/code]. The first dash comes after a random part of
## [member interval] so groups do not dash in sync. While dashing the sprite is stretched
## along the travel direction. Stops once the enemy is dying.
class_name Dash extends Node

## Seconds between the end of one dash and the start of the next.
@export var interval: float = 2.5
## Seconds a dash lasts.
@export var duration: float = 0.5
## Speed multiplier while dashing.
@export var multiplier: float = 3.0
## Sprite stretch along the travel direction while dashing.
@export var stretch: float = 1.35

const _SPEED_SOURCE: StringName = &"dash"

var _enemy: Enemy
var _timer: Timer
var _dashing: bool = false


func _ready() -> void:
	_enemy = owner as Enemy
	if _enemy == null:
		push_error("Dash: owner is not an Enemy; component disabled.")
		return
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_enemy.died.connect(_on_enemy_died)
	# Random phase, and never during the spawn-in tween.
	_timer.start(randf() * interval + _enemy.spawn_duration)


func _on_timer_timeout() -> void:
	if _enemy.is_dying():
		return
	_dashing = not _dashing
	if _dashing:
		_enemy.set_speed_factor(_SPEED_SOURCE, multiplier)
		_enemy.set_stretch(stretch)
		_timer.start(duration)
	else:
		_stop_dash()
		_timer.start(interval)


func _on_enemy_died(_enemy_died: Enemy) -> void:
	_timer.stop()
	_stop_dash()


func _stop_dash() -> void:
	_dashing = false
	_enemy.clear_speed_factor(_SPEED_SOURCE)
	_enemy.set_stretch(1.0)
