extends "res://debug/sections/debug_section.gd"
## Waves: spawn or jump to a wave, difficulty, countdown hold, spawn delay.

const BUDGET_SCALES: Array[float] = [0.5, 1.0, 2.0, 4.0, 8.0]
## Spawn delay multiplier used by the "Spawn delay" toggle.
const FAST_SPAWN_FACTOR: float = 0.05

var _ctx: Context
var _wave_spin: SpinBox
var _budget_button: Button


func build(ctx: Context) -> void:
	_ctx = ctx
	var max_waves: int = ctx.level.get_wave_manager().config.max_waves
	_wave_spin = Ui.add_spin(content, 1, max_waves, State.wave_number)
	_wave_spin.value_changed.connect(_on_wave_spin_value_changed)
	Ui.add_button(content, "Spawn wave", _on_spawn_wave_pressed)
	Ui.add_button(content, "Jump to wave", _on_jump_wave_pressed)
	_budget_button = Ui.add_button(content, "", _on_budget_pressed)
	_update_budget_text()
	Ui.add_toggle(content, "Hold countdown", State.countdown_held, _on_hold_countdown_toggled)
	Ui.add_toggle(content, "Spawn delay x%s" % FAST_SPAWN_FACTOR, State.fast_spawn, _on_fast_spawn_toggled)
	Ui.add_button(content, "Clear enemies", _on_kill_all_pressed)


func apply_state() -> void:
	var wave_manager: WaveManager = _ctx.level.get_wave_manager()
	wave_manager.set_difficulty(State.budget_scale)
	wave_manager.set_countdown_paused(State.countdown_held)
	wave_manager.set_spawn_delay_multiplier(FAST_SPAWN_FACTOR if State.fast_spawn else 1.0)


func _update_budget_text() -> void:
	_budget_button.text = "Budget x%s" % State.budget_scale


func _on_wave_spin_value_changed(value: float) -> void:
	State.wave_number = int(value)


func _on_spawn_wave_pressed() -> void:
	_ctx.extra_wave_spawner.call("spawn_wave", State.wave_number - 1)


func _on_jump_wave_pressed() -> void:
	_ctx.level.get_wave_manager().skip_to_wave(State.wave_number - 1)


func _on_budget_pressed() -> void:
	var next: int = (BUDGET_SCALES.find(State.budget_scale) + 1) % BUDGET_SCALES.size()
	State.budget_scale = BUDGET_SCALES[next]
	_ctx.level.get_wave_manager().set_difficulty(State.budget_scale)
	_update_budget_text()


func _on_hold_countdown_toggled(on: bool) -> void:
	State.countdown_held = on
	_ctx.level.get_wave_manager().set_countdown_paused(on)


func _on_fast_spawn_toggled(on: bool) -> void:
	State.fast_spawn = on
	_ctx.level.get_wave_manager().set_spawn_delay_multiplier(FAST_SPAWN_FACTOR if on else 1.0)


func _on_kill_all_pressed() -> void:
	for enemy: Enemy in _ctx.level.get_enemies():
		enemy.die()
