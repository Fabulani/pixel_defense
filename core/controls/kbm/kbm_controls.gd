class_name KBMControls extends Node

## Emitted when the left mouse button is pressed and released without the pointer moving
## more than [constant CLICK_MOVE_THRESHOLD] and without the pan action being active.
signal clicked(position: Vector2)
## Emitted each frame the camera is panned with the mouse. [param delta] is in viewport pixels.
signal mouse_panned(delta: Vector2)
## Emitted on a zoom input. [param direction] is +1 to zoom in, -1 to zoom out.
signal zoomed(direction: int, anchor_viewport_pos: Vector2)

## Maximum pointer travel (viewport pixels) between press and release for a click.
const CLICK_MOVE_THRESHOLD: float = 8.0

var pan_action: String = ""
var zoom_in_action: String = ""
var zoom_out_action: String = ""

var _fallback_pan: bool
var _fallback_zoom_in: bool
var _fallback_zoom_out: bool

var _left_pressed: bool = false
var _click_valid: bool = false
var _press_position: Vector2 = Vector2.ZERO


## Called by PanningCamera._ready() after pushing action names.
func setup() -> void:
	var actions: Array[StringName] = InputMap.get_actions()
	_fallback_pan = pan_action not in actions
	_fallback_zoom_in = zoom_in_action not in actions
	_fallback_zoom_out = zoom_out_action not in actions


func _process(_delta: float) -> void:
	if not _fallback_zoom_in and Input.is_action_just_pressed(zoom_in_action):
		zoomed.emit(1, get_viewport().get_mouse_position())
	elif not _fallback_zoom_out and Input.is_action_just_pressed(zoom_out_action):
		zoomed.emit(-1, get_viewport().get_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	# Real touches are handled by TouchControls; skip the mouse events Godot
	# emulates from them so a touch is never processed twice.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	_handle_mouse_button(event)
	_handle_mouse_motion(event)
	_handle_scroll(event)


func _is_pan_active(button_mask: int) -> bool:
	if _fallback_pan:
		return button_mask == MOUSE_BUTTON_MASK_MIDDLE
	return Input.is_action_pressed(pan_action)


func _handle_mouse_button(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.is_action("left_mouse"):
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button.pressed:
		_left_pressed = true
		_click_valid = not _is_pan_active(button.button_mask)
		_press_position = button.position
		return
	if not _left_pressed:
		return
	_left_pressed = false
	var moved_too_far: bool = button.position.distance_to(_press_position) > CLICK_MOVE_THRESHOLD
	if _click_valid and not moved_too_far and not _is_pan_active(button.button_mask):
		clicked.emit(button.position)
		get_viewport().set_input_as_handled()
	_click_valid = false


func _handle_mouse_motion(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	var pan_active: bool = _is_pan_active(motion.button_mask)
	if _left_pressed and (pan_active
		or motion.position.distance_to(_press_position) > CLICK_MOVE_THRESHOLD):
		_click_valid = false
	if pan_active:
		mouse_panned.emit(motion.relative)


func _handle_scroll(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.is_pressed():
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	# Only handle scroll directly when the zoom action is not in the InputMap.
	if _fallback_zoom_in and button.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoomed.emit(1, button.position)
	elif _fallback_zoom_out and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoomed.emit(-1, button.position)
