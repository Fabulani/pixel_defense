class_name KBMControls extends Node

## Emitted when the left mouse button is released, regardless of prior panning.
signal clicked(position: Vector2)
## Emitted each frame the camera is panned with the mouse. [param delta] is in viewport pixels.
signal mouse_panned(delta: Vector2)
## Emitted on a zoom input. [param direction] is +1 to zoom in, -1 to zoom out.
signal zoomed(direction: int, anchor_viewport_pos: Vector2)

var pan_action: String = ""
var zoom_in_action: String = ""
var zoom_out_action: String = ""

var _fallback_pan: bool
var _fallback_zoom_in: bool
var _fallback_zoom_out: bool


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
	_handle_mouse_button(event)
	_handle_mouse_motion(event)
	_handle_scroll(event)


func _handle_mouse_button(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.is_action("left_mouse") and not event.pressed:
		clicked.emit(event.position)
		get_viewport().set_input_as_handled()


func _handle_mouse_motion(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var pan_active: bool = (not _fallback_pan and Input.is_action_pressed(pan_action)) \
		or (_fallback_pan and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE)
	if not pan_active:
		return
	mouse_panned.emit(event.relative)


func _handle_scroll(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.is_pressed():
		return
	# Only handle scroll directly when the zoom action is not in the InputMap.
	if _fallback_zoom_in and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoomed.emit(1, event.position)
	elif _fallback_zoom_out and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoomed.emit(-1, event.position)
