class_name Health extends Resource

signal depleted()

var hp: float = 1.0

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		depleted.emit()
