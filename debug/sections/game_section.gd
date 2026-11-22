extends "res://debug/sections/debug_section.gd"
## Game: god mode and coins.

var _ctx: Context


func build(ctx: Context) -> void:
	_ctx = ctx
	Ui.add_toggle(content, "God mode", State.god_mode, _on_god_mode_toggled)
	Ui.add_button(content, "+9999 coins", _on_coins_pressed)


func apply_state() -> void:
	_set_god_mode(State.god_mode)


func _set_god_mode(on: bool) -> void:
	var base: PlayerBase = _ctx.level.get_player_base()
	if not is_instance_valid(base):
		return
	if on:
		base.set_damage_factor(&"debug", 0.0)
	else:
		base.clear_damage_factor(&"debug")


func _on_god_mode_toggled(on: bool) -> void:
	State.god_mode = on
	_set_god_mode(on)


func _on_coins_pressed() -> void:
	CurrencyManager.earn(9999)
