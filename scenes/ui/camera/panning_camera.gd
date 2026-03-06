class_name PanningCamera extends Camera2D

#region exported Parameters
@export var can_zoom: bool = true
@export var zoom_to_cursor: bool = true
@export_range(0.01, 1, 0.01) var min_zoom: float = 1.0
@export_range(1, 20, 0.01) var max_zoom: float = 5.0
@export_range(0.01, 0.5, 0.01) var zoom_step_ratio: float = 0.1

@export_group("Smoothing")
@export_range(0.0, 0.5, 0.01) var pan_smoothing: float = 0.2
@export_range(0.0, 0.5, 0.01) var zoom_smoothing: float = 0.2

@export_group("Panning")
@export_range(0.1, 1000, 0.1) var keyboard_pan_speed: float = 500

@export_group("Actions")
@export var pan_action: String = "camera>pan"
@export var zoom_in_action: String = "camera>zoom+"
@export var zoom_out_action: String = "camera>zoom-"

# Smooth zoom/pan state
var _zoom_goal: Vector2
var _position_goal: Vector2
var _damped_zoom: Array[Vector2]
var _damped_pan: Array[Vector2]
var _zoom_mouse: Vector2  # Viewport-space position used as zoom anchor

# Touch
var _touch_points: Dictionary[int, Vector2] = {}
var _start_distance: float = 0.0
var _start_zoom: float = 1.0

# Action fallbacks (used when actions aren't defined in the InputMap)
var _fallback_pan: bool
var _fallback_zoom_in: bool
var _fallback_zoom_out: bool


func _ready() -> void:
	_zoom_goal = zoom
	_position_goal = position
	_damped_zoom = [zoom, Vector2.ZERO]
	_damped_pan = [position, Vector2.ZERO]

	var actions := InputMap.get_actions()
	_fallback_pan = pan_action not in actions
	_fallback_zoom_in = zoom_in_action not in actions
	_fallback_zoom_out = zoom_out_action not in actions


func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_input(event)
	_handle_touch_input(event)


func _process(delta: float) -> void:
	_handle_directional_input(delta)
	_handle_zoom_input()
	_apply_smooth_zoom_and_pan(delta)


func _apply_smooth_zoom_and_pan(delta: float) -> void:
	_smooth_damp(_damped_zoom, _zoom_goal, zoom_smoothing, delta)

	# Zoom in and determine camera offset to keep
	# the view under the mouse cursor stationary
	var pre := to_local(get_canvas_transform().affine_inverse() * _zoom_mouse)
	zoom = _damped_zoom[0]
	var post := to_local(get_canvas_transform().affine_inverse() * _zoom_mouse)
	var anchor_offset := (pre - post) if zoom_to_cursor else Vector2.ZERO
	_position_goal += anchor_offset
	_damped_pan[0] += anchor_offset

	_smooth_damp(_damped_pan, _position_goal, pan_smoothing, delta)
	position = _damped_pan[0]


func _handle_mouse_input(event: InputEvent) -> void:
	# Pan with middle mouse button or action
	if event is InputEventMouseMotion:
		var pan_active: bool = (not _fallback_pan and Input.is_action_pressed(pan_action)) \
			or (_fallback_pan and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE)
		if pan_active:
			_position_goal -= event.relative / zoom

	# Zoom with scroll wheel (fallback in case actions are undefined)
	if can_zoom and event is InputEventMouseButton and event.is_pressed():
		var zoom_in: bool = _fallback_zoom_in and event.button_index == MOUSE_BUTTON_WHEEL_UP
		var zoom_out: bool = _fallback_zoom_out and event.button_index == MOUSE_BUTTON_WHEEL_DOWN
		if zoom_in or zoom_out:
			_zoom_mouse = get_viewport().get_mouse_position()
			_zoom_goal *= (1.0 / (1.0 - zoom_step_ratio)) if zoom_in else (1.0 - zoom_step_ratio)
			_zoom_goal = _zoom_goal.clamp(min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)


func _handle_touch_input(event: InputEvent) -> void:
	# Track touch points; snapshot pinch start state when second finger lands
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
		else:
			_touch_points.erase(event.index)

		if _touch_points.size() == 2:
			var positions: Array[Vector2] = _touch_points.values()
			_start_distance = positions[0].distance_to(positions[1])
			_start_zoom = zoom.x
		else:
			_start_distance = 0.0

	# Pinch to zoom (two fingers, anchored to finger midpoint)
	if can_zoom and event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 2 and _start_distance > 0.0:
			var positions: Array[Vector2] = _touch_points.values()
			var current_distance := positions[0].distance_to(positions[1])
			var new_zoom: float = clamp(_start_zoom * (current_distance / _start_distance), min_zoom, max_zoom)
			_zoom_mouse = (positions[0] + positions[1]) * 0.5
			_zoom_goal = new_zoom * Vector2.ONE

	# Pan (single finger)
	if event is InputEventScreenDrag and _touch_points.size() == 1:
		_position_goal -= event.relative / zoom


func _handle_zoom_input() -> void:
	if not can_zoom or _fallback_zoom_in and _fallback_zoom_out:
		return
	var zoom_in := Input.is_action_just_pressed(zoom_in_action)
	var zoom_out := Input.is_action_just_pressed(zoom_out_action)
	if zoom_in or zoom_out:
		_zoom_mouse = get_viewport().get_mouse_position()
		_zoom_goal *= (1.0 / (1.0 - zoom_step_ratio)) if zoom_in else (1.0 - zoom_step_ratio)
		_zoom_goal = _zoom_goal.clamp(min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)


func _handle_directional_input(delta: float) -> void:
	var direction := Input.get_vector("camera>pan_left", "camera>pan_right", "camera>pan_up", "camera>pan_down")
	if direction != Vector2.ZERO:
		_position_goal += direction * keyboard_pan_speed / zoom.x * delta


## Zoom by an absolute amount. Anchors to viewport center so zoom_to_cursor
## does not cause unexpected shifts when called programmatically.
func zoom_by(amount: float) -> void:
	_zoom_mouse = get_viewport().get_visible_rect().size * 0.5
	_zoom_goal = (_zoom_goal + amount * Vector2.ONE).clamp(min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)


## Critically-damped spring smoothing. `state` is [current, velocity].
func _smooth_damp(state: Array[Vector2], target: Vector2, smooth_time: float, delta: float) -> void:
	# Speed up the spring for nicer input values 
	# and a behaviour closer to the "actual" time to come to rest
	smooth_time /= 2.0

	if smooth_time == 0.0:
		state[0] = target
		state[1] = Vector2.ZERO
		return

	var current := state[0]
	var velocity := state[1]
	var omega := 2.0 / smooth_time
	var x := omega * delta
	var expo := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - target
	var original_to := target
	target = current - change
	var temp := (velocity + omega * change) * delta
	velocity = (velocity - omega * temp) * expo
	var output := target + (change + temp) * expo

	# Prevent overshooting
	if delta > 0:
		if (original_to.x > current.x) == (output.x > original_to.x):
			output.x = original_to.x
			velocity.x = (output.x - original_to.x) / delta
		if (original_to.y > current.y) == (output.y > original_to.y):
			output.y = original_to.y
			velocity.y = (output.y - original_to.y) / delta

	state[0] = output
	state[1] = velocity
