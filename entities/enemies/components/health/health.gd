class_name Health extends Resource

signal depleted()

@export var hp: float = 1.0

## Reduce hp. Does nothing once hp is already depleted, so [signal depleted] fires once.
func take_damage(amount: float) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		depleted.emit()
