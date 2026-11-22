class_name Health extends Resource

signal depleted()

@export var hp: float = 1.0

## Reduce hp. Does nothing once hp is already depleted, so [signal depleted] fires once.
func take_damage(amount: float) -> void:
	if hp <= 0:
		return
	hp -= amount
	emit_changed()
	if hp <= 0:
		depleted.emit()

## Restore hp, clamped to [param max_hp]. Does nothing once hp is depleted.
func heal(amount: float, max_hp: float) -> void:
	if hp <= 0:
		return
	hp = minf(hp + amount, max_hp)
	emit_changed()

## Sets hp and emits [signal Resource.changed] (also emitted by [method take_damage] and [method heal]),
## not [signal depleted]; keep [param value] above 0.
func set_hp(value: float) -> void:
	hp = value
	emit_changed()
