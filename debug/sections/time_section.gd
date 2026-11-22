extends "res://debug/sections/debug_section.gd"
## Time: time scale, pause, single stepping.

const TIME_SCALES: Array[float] = [0.1, 0.25, 0.5, 1.0, 2.0, 4.0]

var _time_buttons: Dictionary[float, Button] = {}
var _pause_button: Button
var _step_button: Button
var _step_10_button: Button
var _stepping: bool = false


func build(_ctx: Context) -> void:
	var flow: HFlowContainer = Ui.add_flow(content)
	for factor: float in TIME_SCALES:
		var button: Button = Ui.add_button(flow, "%s" % factor, _on_time_scale_pressed.bind(factor))
		button.toggle_mode = true
		_time_buttons[factor] = button
	_pause_button = Ui.add_toggle(content, "Pause", get_tree().paused, _on_pause_toggled)
	var step_row: HFlowContainer = Ui.add_flow(content)
	_step_button = Ui.add_button(step_row, "Step 1", _on_step_pressed.bind(1))
	_step_10_button = Ui.add_button(step_row, "Step 10", _on_step_pressed.bind(10))


func apply_state() -> void:
	Engine.time_scale = State.time_scale


func refresh() -> void:
	for factor: float in _time_buttons:
		_time_buttons[factor].set_pressed_no_signal(is_equal_approx(factor, Engine.time_scale))
	var paused: bool = get_tree().paused
	_pause_button.set_pressed_no_signal(paused)
	_step_button.disabled = not paused and not _stepping
	_step_10_button.disabled = _step_button.disabled


func _on_time_scale_pressed(factor: float) -> void:
	State.time_scale = factor
	Engine.time_scale = factor
	refresh()


func _on_pause_toggled(on: bool) -> void:
	get_tree().paused = on
	refresh()


## Runs [param frames] physics steps, then pauses again. [signal SceneTree.physics_frame] fires
## before the nodes' physics step, so waiting for frames + 1 of them lets exactly [param frames]
## steps (and the idle frames between them) run.
func _on_step_pressed(frames: int) -> void:
	if _stepping or not get_tree().paused:
		return
	_stepping = true
	get_tree().paused = false
	for i: int in range(frames + 1):
		await get_tree().physics_frame
	if is_inside_tree():
		get_tree().paused = true
		_stepping = false
		refresh()
