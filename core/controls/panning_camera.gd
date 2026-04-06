class_name PanningCamera extends Camera2D


@export var smooth_damp: SmoothDamp
@export var touch_controls: TouchControls

@export_group("Zoom")
@export var can_zoom: bool = true
@export_range(0.01, 1, 0.01) var min_zoom: float = 1.0
@export_range(1, 20, 0.01) var max_zoom: float = 5.0
@export_range(0.01, 0.5, 0.01) var zoom_step_ratio: float = 0.1

@export_group("Pan")
@export_range(0.1, 1000, 0.1) var pan_speed: float = 500

@export_group("Actions")
@export var pan_action: String = "camera>pan"
@export var zoom_in_action: String = "camera>zoom+"
@export var zoom_out_action: String = "camera>zoom-"


# Action fallbacks (used when actions aren't defined in the InputMap)
var _fallback_pan: bool
var _fallback_zoom_in: bool
var _fallback_zoom_out: bool

## Viewport-space position used as zoom anchor for zoom-to-mouse behavior.
var _anchor_viewport_position: Vector2  
## Zoom value when pinch gesture starts
var _pinch_start_zoom: float = zoom.x

func _ready() -> void:
	smooth_damp.initialize(zoom, position)
	
	touch_controls.pan_changed.connect(_on_pan_changed)
	touch_controls.pinch_changed.connect(_on_pinch_changed)
	touch_controls.pinch_started.connect(_on_pinch_started)

	var actions := InputMap.get_actions()
	_fallback_pan = pan_action not in actions
	_fallback_zoom_in = zoom_in_action not in actions
	_fallback_zoom_out = zoom_out_action not in actions


func _unhandled_input(event: InputEvent) -> void:
	touch_controls.handle_input(event)
	_handle_pan_mouse(event)
	_handle_zoom_scroll_fallback(event)


func _process(delta: float) -> void:
	_handle_directional_input(delta)
	_handle_zoom_input()
	
	_apply_smooth_damp(delta)

func _apply_smooth_damp(delta: float) -> void:
	# Shift position to keep the zoom anchor point stationary on screen
	var pre := _calculate_zoom_anchor(_anchor_viewport_position)
	
	zoom = smooth_damp.smooth_zoom(delta)
	var post := _calculate_zoom_anchor(_anchor_viewport_position)
	var anchor_offset := pre - post
	
	position = smooth_damp.smooth_pan(delta, anchor_offset)


## Calculate the zoom anchor position. Used in anchor offset calculations for
## zoom-to-mouse behavior.
func _calculate_zoom_anchor(cursor_viewport_pos: Vector2) -> Vector2:
	return to_local(get_canvas_transform().affine_inverse() * cursor_viewport_pos)

# -- Pan -----------------------------------------------------------------------

func _handle_pan_mouse(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var pan_active: bool = (not _fallback_pan and Input.is_action_pressed(pan_action)) \
		or (_fallback_pan and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE)
	if pan_active:
		smooth_damp.position_goal -= event.relative / zoom


func _handle_directional_input(delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"camera>pan_left", 
		"camera>pan_right", 
		"camera>pan_up", 
		"camera>pan_down"
	)
	if direction != Vector2.ZERO:
		smooth_damp.position_goal += direction * pan_speed / zoom.x * delta


# -- Zoom ----------------------------------------------------------------------

func _handle_zoom_input() -> void:
	if not can_zoom or (_fallback_zoom_in and _fallback_zoom_out):
		return
	var zoom_in: bool = not _fallback_zoom_in and Input.is_action_just_pressed(zoom_in_action)
	var zoom_out: bool = not _fallback_zoom_out and Input.is_action_just_pressed(zoom_out_action)
	if zoom_in or zoom_out:
		_anchor_viewport_position = get_viewport().get_mouse_position()
		smooth_damp.zoom_goal *= (1.0 / (1.0 - zoom_step_ratio)) if zoom_in else (1.0 - zoom_step_ratio)
		smooth_damp.zoom_goal = smooth_damp.zoom_goal.clamp(min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)


func _handle_zoom_scroll_fallback(event: InputEvent) -> void:
	if not can_zoom or not event is InputEventMouseButton or not event.is_pressed():
		return
	var zoom_in: bool = _fallback_zoom_in and event.button_index == MOUSE_BUTTON_WHEEL_UP
	var zoom_out: bool = _fallback_zoom_out and event.button_index == MOUSE_BUTTON_WHEEL_DOWN
	if zoom_in or zoom_out:
		_anchor_viewport_position = get_viewport().get_mouse_position()
		smooth_damp.zoom_goal *= (1.0 / (1.0 - zoom_step_ratio)) if zoom_in else (1.0 - zoom_step_ratio)
		smooth_damp.zoom_goal = smooth_damp.zoom_goal.clamp(min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)


# -- Other ---------------------------------------------------------------------

## Zoom by an absolute amount.
func zoom_by(amount: float) -> void:
	_anchor_viewport_position = get_viewport().get_visible_rect().size * 0.5
	smooth_damp.zoom_goal = (smooth_damp.zoom_goal + amount * Vector2.ONE).clamp(min_zoom * Vector2.ONE, max_zoom * Vector2.ONE)

func _on_pan_changed(screen_delta: Vector2) -> void:
	smooth_damp.position_goal -= screen_delta / zoom

func _on_pinch_started():
	_pinch_start_zoom = zoom.x
	
func _on_pinch_changed(pinch_factor: float, anchor_viewport_pos: Vector2) -> void:
	var new_zoom: float = clamp(_pinch_start_zoom * pinch_factor, min_zoom, max_zoom)
	_anchor_viewport_position = anchor_viewport_pos
	smooth_damp.zoom_goal = new_zoom * Vector2.ONE
