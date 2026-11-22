class_name PlayerBase extends Area2D

signal destroyed
## Emitted on every hit, before health drops (also in god mode, where health stays).
signal damaged(amount: int)

## Debug: enemies reaching the base are freed but do no damage.
var invulnerable: bool = false

var _health: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Reduce the base health. Emits [signal destroyed] and frees the base when it reaches zero.
func take_damage(amount: int) -> void:
	if _health <= 0:
		return
	damaged.emit(amount)
	_health -= amount
	if _health <= 0:
		destroyed.emit()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if invulnerable:
			damaged.emit(1)
		else:
			take_damage(1)
		body.queue_free()
