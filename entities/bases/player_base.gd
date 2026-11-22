class_name PlayerBase extends Area2D

signal destroyed
## Emitted on every hit, before health drops (also when damage factors cancel the damage).
signal damaged(amount: int)

var _health: int = 1
var _damage_factors: Dictionary[StringName, float] = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Reduce the base health. Emits [signal destroyed] and frees the base when it reaches zero.
func take_damage(amount: int) -> void:
	if _health <= 0:
		return
	damaged.emit(amount)
	var factor: float = 1.0
	for f: float in _damage_factors.values():
		factor *= f
	_health -= roundi(amount * factor)
	if _health <= 0:
		destroyed.emit()
		queue_free()


## Set the damage factor owned by [param source]: hits subtract roundi(amount x product of factors).
func set_damage_factor(source: StringName, factor: float) -> void:
	_damage_factors[source] = factor


## Remove the damage factor owned by [param source].
func clear_damage_factor(source: StringName) -> void:
	_damage_factors.erase(source)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		take_damage(1)
		body.queue_free()
