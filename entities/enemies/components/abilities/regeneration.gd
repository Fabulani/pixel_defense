## Heals its [Enemy] over time once it went a while without taking damage.
##
## Reads the enemy through [code]owner[/code]. Stops once the enemy is dying.
class_name Regeneration extends Node

## Hit points restored per second.
@export var hp_per_second: float = 2.0
## Seconds without damage before healing starts.
@export var delay_after_hit: float = 1.5
## Seconds between heal ticks.
@export var tick_interval: float = 0.5
@export var flash_color: Color = Color(0.3, 1.0, 0.4)
@export var flash_duration: float = 0.15

var _enemy: Enemy
var _timer: Timer
var _quiet_time: float = 0.0


func _ready() -> void:
	_enemy = owner as Enemy
	if _enemy == null:
		push_error("Regeneration: owner is not an Enemy; component disabled.")
		return
	_timer = Timer.new()
	_timer.wait_time = tick_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_enemy.damaged.connect(_on_enemy_damaged)
	_enemy.died.connect(_on_enemy_died)


func _on_enemy_damaged(_amount: float) -> void:
	if _enemy.is_dying():
		return
	_quiet_time = 0.0
	_timer.start()


func _on_enemy_died(_enemy_died: Enemy) -> void:
	_timer.stop()


func _on_timer_timeout() -> void:
	if _enemy.is_dying():
		_timer.stop()
		return
	_quiet_time += tick_interval
	if _quiet_time < delay_after_hit:
		return
	var before: float = _enemy.health.hp
	_enemy.heal(hp_per_second * tick_interval)
	if _enemy.health.hp > before:
		_enemy.flash(flash_color, flash_duration)
	if _enemy.health.hp >= float(_enemy.stats.max_health):
		_timer.stop()
